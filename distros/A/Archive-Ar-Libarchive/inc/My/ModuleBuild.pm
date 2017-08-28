package My::ModuleBuild;

use strict;
use warnings;
use Alien::Base::Wrapper qw( Alien::Libarchive !export );
use ExtUtils::CChecker;
use Text::ParseWords qw( shellwords );
use base qw( Module::Build );

sub new
{
  my($class, %args) = @_;

  %args = (%args, Alien::Base::Wrapper->mb_args);
  $args{c_source} = 'xs';
  
  my $self = $class->SUPER::new(%args);
  
  $self;
}

1;
