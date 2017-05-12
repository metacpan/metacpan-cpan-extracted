package My::ModuleBuild;

use strict;
use warnings;
use Alien::Libarchive::Installer;
use base qw( Module::Build );

sub new
{
  my($class, %args) = @_;
  
  unless(eval { Alien::Libarchive::Installer->system_install( test => 'ffi', alien => 1 ) })
  {
    $args{requires}->{'Alien::Libarchive'} = '0.21';
  }
  
  my $self = $class->SUPER::new(%args);
  
  $self;
}

1;
