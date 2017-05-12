package t::model::status;
use strict;
use warnings;
use base qw(ClearPress::model);

__PACKAGE__->mk_accessors(fields());
__PACKAGE__->has_all();

sub fields {
  return qw(id_status description);
}

1;
