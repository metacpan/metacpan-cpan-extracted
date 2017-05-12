package My::Builder;

use strict;
use warnings;
use base 'Module::Build';

use lib "inc";
use File::Spec::Functions qw(catfile rel2abs);
use ExtUtils::Command;
use File::Path qw();
use File::ShareDir;
use Config;

sub ACTION_install {
  my $self = shift;
  my $sharedir = eval {File::ShareDir::dist_dir('Alien-FreeImage')} || '';
  if ( -d $sharedir ) {
    warn "Removing the old '$sharedir'\n";
    File::Path::rmtree($sharedir);
    File::Path::mkpath($sharedir);    
  }
  return $self->SUPER::ACTION_install(@_);
}

sub ACTION_clean {
  my $self = shift;
  unlink 'build_done';
  chdir 'src';
  $self->make_clean();
  chdir $self->base_dir();
  return $self->SUPER::ACTION_clean(@_);
}

sub ACTION_code {
  my $self = shift;
  unless (-e 'build_done') {
    $self->add_to_cleanup('build_done');
    
    # prepare butld directory
    my $build_out = catfile('sharedir', $self->{properties}->{dist_version});
    $self->add_to_cleanup($build_out);
    $self->notes('build_out', $build_out);

    # go for build
    my $prefix = rel2abs($build_out);
    chdir 'src';
    $self->make_inst($prefix);
    chdir $self->base_dir();
   
    # store info about build into future Alien::FreeImage::ConfigData
    my $libs = $^O eq 'MSWin32' ? ' -lfreeimage ' : ' -lfreeimage -lstdc++ ';
    $self->config_data('share_subdir', $self->{properties}->{dist_version});
    $self->config_data('config', { PREFIX => '@PrEfIx@',
                                   LIBS   => ' -L' . $self->quote_literal('@PrEfIx@') . $libs,
                                   INC    => ' -DFREEIMAGE_LIB -I' . $self->quote_literal('@PrEfIx@') . ' ',
                                 });

    # mark sucessfully finished build
    local @ARGV = ('build_done');
    ExtUtils::Command::touch();
  }
  $self->SUPER::ACTION_code;
}

sub make_clean {
  # this needs to be overriden in My::Builder::<platform>
  die "###ERROR### use My::Builder::<platform>";
}

sub make_inst {
  # this needs to be overriden in My::Builder::<platform>
  die "###ERROR### use My::Builder::<platform>";
}

sub quote_literal {
  my ($self, $path) = @_;
  return $path;
}

sub get_make {
  my ($self) = @_;
 
  return $Config{make} if $^O eq 'cygwin';
 
  my @try = ($Config{gmake}, 'gmake', '/usr/local/bin/gmake', 'gnumake', 'make', $Config{make});
  my %tested;
  warn "Gonna detect GNU make:\n";
  foreach my $name ( @try ) {
    next unless $name;
    next if $tested{$name};
    $tested{$name} = 1;
    warn "- testing: '$name'\n";
    if ($self->_is_gnu_make($name)) {
      warn "- found: '$name'\n";
      return $name
    }
  }
  warn "- ### GNU make NOT FOUND ### falling back to 'make'\n";
  return 'make';
}
 
sub _is_gnu_make {
  my ($self, $name) = @_;
  my $devnull = File::Spec->devnull();
  my $ver = `$name --version 2> $devnull`;
  if ($ver =~ /GNU Make/i) {
    return 1;
  }
  return 0;
}

1;
