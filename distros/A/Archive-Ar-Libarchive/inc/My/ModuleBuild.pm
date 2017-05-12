package My::ModuleBuild;

use strict;
use warnings;
use Alien::Libarchive;
use ExtUtils::CChecker;
use Text::ParseWords qw( shellwords );
use base qw( Module::Build );

sub new
{
  my($class, %args) = @_;
  
  my $alien = Alien::Libarchive->new;

  $args{extra_compiler_flags} = $alien->cflags;
  $args{extra_linker_flags}   = $alien->libs;
  $args{c_source}             = 'xs';
  
  my $self = $class->SUPER::new(%args) unless $alien->isa('Alien::Base');
  
  $self;
}

1;
