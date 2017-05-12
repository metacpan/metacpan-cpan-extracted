package t::model::derived;
use strict;
use warnings;
use base qw(ClearPress::model);
use t::model::derived_child;
use t::model::derived_parent;
use t::model::derived_attr;
use t::model::attribute;

__PACKAGE__->mk_accessors(fields());
__PACKAGE__->has_all();
__PACKAGE__->has_a('derived_parent');
__PACKAGE__->has_many({child => 'derived_child'});
__PACKAGE__->has_a_through('status|derived_status');
__PACKAGE__->has_many_through('attribute|derived_attr');

sub fields {
  return qw(id_derived id_derived_parent id_derived_status text_dummy char_dummy int_dummy float_dummy);
}

1;
