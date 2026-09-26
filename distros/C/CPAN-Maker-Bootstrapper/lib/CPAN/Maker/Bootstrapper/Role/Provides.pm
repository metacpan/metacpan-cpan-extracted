package CPAN::Maker::Bootstrapper::Role::Provides;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);

use Role::Tiny;
use Role::Tiny::With;

with 'CPAN::Maker::Role::Provides';

########################################################################
sub cmd_provides {
########################################################################
  my ($self) = @_;

  $self->create_provides(
    path => 'lib',
    file => 'provides',
  );

  return $SUCCESS;
}

1;
