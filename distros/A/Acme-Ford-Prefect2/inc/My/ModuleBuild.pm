package My::ModuleBuild;

use strict;
use warnings;
use Acme::Alien::DontPanic2;
use base qw( Module::Build );
use Text::ParseWords qw( shellwords );
use Config;

sub _join
{
  join ' ', map { s/(\s)/\\$1/g; $_ } @_;
}

sub new
{
  my($class, %args) = @_;
  
  my $libs_L     = _join grep  /^-L/,    shellwords(Acme::Alien::DontPanic2->libs);
  my $libs_l     = _join grep  /^-l/,    shellwords(Acme::Alien::DontPanic2->libs);
  my $libs_other = _join grep !/^-[Ll]/, shellwords(Acme::Alien::DontPanic2->libs);

  $args{extra_compiler_flags} = Acme::Alien::DontPanic2->cflags;
  $args{extra_linker_flags}   = "$libs_l";
  $args{config}->{lddlflags}  = "$libs_L $libs_other $Config{lddlflags}";
  $args{config}->{ldflags}    = "$libs_L $libs_other $Config{ldflags}";
  
  
  my $self = $class->SUPER::new(%args);
  
  $self;
}

1;
