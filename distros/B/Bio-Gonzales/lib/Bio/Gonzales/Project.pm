package Bio::Gonzales::Project;

use Mouse;

use warnings;
use strict;
use Carp;
use FindBin;
use File::Spec;
use Bio::Gonzales::Util::File qw/slurpc/;
use Bio::Gonzales::Util::Cerial;
use Bio::Gonzales::Util::Development::File;
use Data::Visitor::Callback;
use Bio::Gonzales::Util::Log;
use Data::Printer;
use POSIX;

use 5.010;

our $VERSION = '0.0546'; # VERSION

has 'analysis_version' => ( is => 'rw', builder    => '_build_analysis_version' );
has '_substitute_conf' => ( is => 'rw', lazy_build => 1 );
has 'config'           => ( is => 'rw', lazy_build => 1 );
has 'log'              => ( is => 'rw', builder    => '_build_log' );

sub _build_analysis_version {
  my ($self) = @_;

  if ( $ENV{ANALYSIS_VERSION} ) {
    return $ENV{ANALYSIS_VERSION};
  } elsif ( -f 'av' ) {
    return ( slurpc('av') )[0];
  } else {
    carp "using current dir as output dir";
    return '.';
  }
}

sub _build__substitute_conf {
  my ($self) = @_;

  my %subs = (
    av      => sub { return $self->analysis_version },
    path_to => sub { return $self->path_to(@_) },
    data    => sub { return $self->path_to('data') },
  );

  return Data::Visitor::Callback->new(
    plain_value => sub {
      return unless defined $_;
      $_ =~ s{ ^ ~ ( [^/]* ) }
            { $1
                ? (getpwnam($1))[7]
                : ( $ENV{HOME} || (getpwuid($>))[7] )
            }ex;

      my $subsre = join "|", keys %subs;
      s{__($subsre)(?:\((.+?)\))?__}{ $subs{ $1 }->( $2 ? split( /,/, $2 ) : () ) }eg;
    }
  );
}

sub _build_log {
  my ($self) = @_;

  return Bio::Gonzales::Util::Log->new(
    path      => $self->_nfi('gonz.log'),
    level     => 'info',
    namespace => $FindBin::Script
  );
}

sub _build_config {
  my ($self) = @_;

  my $data;
  if ( -f 'gonz.conf.yml' ) {
    $data = yslurp('gonz.conf.yml');
  } elsif ( -f 'gonzconf.yml' ) {
    $data = yslurp('gonzconf.yml');
  } elsif ( -f 'iof.yml' ) {
    $data = yslurp('iof.yml');
  } elsif ( -f 'io_files.yml' ) {
    $data = thaw_file('io_files.yml');
  } elsif ( -f 'iof.json' ) {
    $data = jslurp('iof.json');
  } else {
    confess "io file not found";
  }
  $self->_substitute_conf->visit($data);
  return $data;
}

sub BUILD {
  my ($self) = @_;

  my $av = $self->analysis_version;
  unless ( $av && $av =~ /^[-A-Za-z_.0-9]+$/ ) {
    carp "analysis version not or not correctly specified, variable contains: " . ( $av // 'nothing' );
    carp "using current dir as output dir";
    $self->analysis_version('.');
  } else {
    mkdir $av unless ( -d $av );
  }

  $self->log->info("invoked")    # if a script is run, log it
    if ( !$ENV{GONZLOG_SILENT} );
}

sub av { shift->analysis_version(@_) }

sub c { shift->conf(@_) }

sub nfi {
  my $self = shift;

  my $f = $self->_nfi(@_);
  $self->log->info("(nfi) > $f <");
  return $f;
}

sub _nfi {
  my $self = shift;
  return File::Spec->catfile( $self->analysis_version, @_ );
}

sub conf {
  my ( $self, @keys ) = @_;

  my $data = $self->config;

  for my $k (@keys) {
    confess "empty key supplied" unless ($k);
    my $r = ref $data;
    if ( $r && $r eq 'HASH' ) {
      if ( exists( $data->{$k} ) ) {
        $data = $data->{$k};
      } else {
        confess "$k not found in gonzconf";
      }
    } elsif ( $r && $r eq 'ARRAY' ) {
      if ( exists( $data->[$k] ) ) {
        $data = $data->[$k];
      } else {
        confess "$k not found in gonzconf";
      }
    } else {
      confess "$k not found in gonzconf";
    }
  }
  if (@keys) {
    $self->log->info( "(gonzconf) > " . join( " ", @keys  ) . " <", p($data) );

  } else {
    $self->log->info( "(gonzconf) dump", p($data) );
  }
  return $data;
}

sub path_to {
  my $self = shift;

  my $home = Bio::Gonzales::Util::Development::File::find_root(
    {
      location => '.',
      dirs     => [ '.git', 'analysis', 'doc', ],
      files    => ['Makefile']
    }
  );

  confess "Could not find project home"
    unless ($home);
  return File::Spec->catfile( $home, @_ );
}

sub analysis_path {
  my $self = shift;

  return $self->path_to( "analysis", @_ );
}

__PACKAGE__->meta->make_immutable();
