package My::ModuleBuild;

use strict;
use warnings;
use base qw( Module::Build );

sub new
{
  my($class, %args) = @_;

  if($^O ne 'midnightbsd' && eval { require Archive::Libarchive::FFI; 1 })
  {
    $args{requires}->{'Archive::Libarchive::FFI'} = 0;
  }
  elsif($^O eq 'midnightbsd' && eval { require Archive::Libarchive::XS; 1 })
  {
    $args{requires}->{'Archive::Libarchive::XS'} = 0;
  }
  elsif(defined $ENV{ARCHIVE_LIBARCHIVE_ANY})
  {
    $args{requires}->{"Archive::Libarchive::$ENV{ARCHIVE_LIBARCHIVE_ANY}"} = 0;
  }
  else
  {
    if($^O eq 'midnightbsd')
    {
      $args{requires}->{'Archive::Libarchive::FFI'} = 0;
    }
    else
    {
      $args{requires}->{'Archive::Libarchive::XS'} = 0;
    }
  }

  $class->SUPER::new(%args);
}

1;
