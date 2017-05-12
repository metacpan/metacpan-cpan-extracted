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
use Data::Printer {
  indent         => 2,
  colored        => '0',
  use_prototypes => 0,
  rc_file        => '',
};

use POSIX;

use 5.010;

our $VERSION = '0.062'; # VERSION

has '_config_key_cache' => ( is => 'rw', default => sub { {} } );
has '_nfi_cache'        => ( is => 'rw', default => sub { {} } );
has 'analysis_version'  => ( is => 'rw', builder => '_build_analysis_version' );
has '_substitute_conf' => ( is => 'rw', lazy_build => 1 );
has 'config'           => ( is => 'rw', lazy_build => 1 );
has 'merge_av_config'  => ( is => 'rw', default    => 1 );
has 'log'              => ( is => 'rw', builder    => '_build_log' );
has 'config_file'      => ( is => 'rw', default    => 'gonz.conf.yml' );
has 'analysis_name' => (is => 'rw', lazy_build => 1);

sub _build_analysis_name {
  my ($self) = @_;

  return (File::Spec->splitdir(File::Spec->rel2abs('.')))[-1]
}

sub _build_analysis_version {
  my ($self) = @_;

  my $av;
  if ( $ENV{ANALYSIS_VERSION} ) {
    $av = $ENV{ANALYSIS_VERSION};
  } elsif ( -f 'av' ) {
    $av = ( slurpc('av') )[0];
  } else {
    carp "using current dir as output dir";
    $av = '.';
  }
  return _prepare_av($av);
}

sub _build__substitute_conf {
  my ($self) = @_;

  my %subs = (
    an      => sub { return $self->analysis_name },
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

  my $conf;
  my $conf_f = $self->config_file;
  if ( -f $conf_f ) {
    $conf = yslurp($conf_f);
  $conf //= {};

    confess "configuration file >> $conf_f << is not a hash/dictionary structure"
      if ( ref $conf ne 'HASH' );
    $self->log->info("reading >> $conf_f <<");
    $self->_substitute_conf->visit($conf);
  }

  my $av_conf_f = join( ".", $self->analysis_version, "conf", "yml" );
  if ( $self->merge_av_config && $av_conf_f !~ /^\./ && -f $av_conf_f ) {

    my $av_conf = yslurp($av_conf_f);
    confess "configuration file >> $av_conf_f << is not a hash/dictionary structure"
      if ( ref $av_conf ne 'HASH' );

    $self->log->info("reading >> $av_conf_f <<");
    $self->_substitute_conf->visit($av_conf);

    $conf = { %$conf, %$av_conf };
  }
  return $conf;
}

sub BUILD {
  my ($self) = @_;

  my $av = $self->analysis_version;

  $self->log->info("invoked ($av)")    # if a script is run, log it
    if ( !$ENV{GONZLOG_SILENT} );
}

around 'analysis_version' => sub {
  my $orig = shift;
  my $self = shift;

  return $self->$orig()
    unless @_;

  return $self->$orig( _prepare_av(shift) );
};

sub _prepare_av {
  my $av = shift;
  if ( !$av ) {
    return '.';
  } elsif ( $av =~ /^[-A-Za-z_.0-9]+$/ ) {
    mkdir $av unless ( -d $av );
  } else {
    carp "analysis version not or not correctly specified, variable contains: " . ( $av // 'nothing' );
    carp "using current dir as output dir";
    return '.';
  }
  return $av;
}

sub av { shift->analysis_version(@_) }

sub c { shift->conf(@_) }

sub nfi {
  my $self = shift;

  my $f = $self->_nfi(@_);

  # only log it once per filename
  $self->log->info("(nfi) > $f <")
    unless ( $self->_nfi_cache->{$f}++ );

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
        $self->log->fatal_confess("$k not found in gonzconf");
      }
    } elsif ( $r && $r eq 'ARRAY' ) {
      if ( exists( $data->[$k] ) ) {
        $data = $data->[$k];
      } else {
        $self->log->fatal_confess("$k not found in gonzconf");
      }
    } else {
      $self->log->fatal_confess("$k not found in gonzconf");
    }
  }
  if (@keys) {
    my $k = join( " ", @keys );
    $self->log->info( "(gonzconf) > " . $k . " <", p($data) )
      unless ( $self->_config_key_cache->{ '_' . $k }++ );

  } else {
    $self->log->info( "(gonzconf) dump", p($data) )
      unless ( $self->_config_key_cache->{'_'}++ );
  }
  return $data;
}

sub path_to {
  my $self = shift;

  my $home = Bio::Gonzales::Util::Development::File::find_root(
    {
      location => '.',
      dirs     => [ '.git', 'analysis', ],
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
