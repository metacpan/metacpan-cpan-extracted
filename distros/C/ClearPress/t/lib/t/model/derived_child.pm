package t::model::derived_child;
use strict;
use warnings;
use base qw(ClearPress::model);
use t::model::derived;
use t::model::derived_status;
use t::model::status;

__PACKAGE__->mk_accessors(fields());
__PACKAGE__->has_all();
__PACKAGE__->has_a(['derived']);

sub fields {
  return qw(id_derived_child id_derived text_dummy);
}

1;
