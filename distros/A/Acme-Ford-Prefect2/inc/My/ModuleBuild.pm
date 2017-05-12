package My::ModuleBuild;

use strict;
use warnings;
use Acme::Alien::DontPanic2;
use base qw( Module::Build );

sub new
{
  my($class, %args) = @_;
  
  $args{extra_compiler_flags} = Acme::Alien::DontPanic2->cflags;
  $args{extra_linker_flags}   = Acme::Alien::DontPanic2->libs;
  
  my $self = $class->SUPER::new(%args);
  
  $self;
}

1;
