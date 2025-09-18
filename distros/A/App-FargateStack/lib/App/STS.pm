package App::STS;

use strict;
use warnings;

use Data::Dumper;
use English qw(no_match_vars);

use Role::Tiny::With;
with 'App::AWS';

use parent qw(App::Command);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(qw(profile region));

########################################################################
sub get_caller_identity {
########################################################################
  my ( $self, $query ) = @_;

  return $self->command( 'get-caller-identity', [ $query ? ( '--query' => $query ) : () ] );
}

1;
