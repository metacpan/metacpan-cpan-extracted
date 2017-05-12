package t::model::derived_status;
use strict;
use warnings;
use base qw(ClearPress::model);

__PACKAGE__->mk_accessors(fields());

sub fields {
  return qw(id_derived_status id_status);
}

1;
