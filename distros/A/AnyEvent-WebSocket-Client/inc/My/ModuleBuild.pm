package My::ModuleBuild;

use strict;
use warnings;
use base qw( Module::Build );

sub new
{
  my($class, %args) = @_;
  
  # if Crypt::Random::Source is installed,
  # require at least version 0.08 to avoid
  # deprecation messages from Class::MOP
  $args{requires}->{'Crypt::Random::Source'} = '0.08'
    if eval { require Crypt::Random::Source };
  
  $class->SUPER::new(%args);
}

1;
