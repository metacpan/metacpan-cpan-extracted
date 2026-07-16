package Example::Schema::ResultSet::PersonRole;

use strict;
use warnings;
use base 'Example::Schema::ResultSet';

sub is_user {
  my $self = shift;
  # TODO: We need some logic or conventions around 'if we have a resultset cache
  # use that, otherwise make one.
  warn "user check";
  return my $found = grep { $_->is_user } $self->all;
}

1;
