package t::model::derived_attr;
use strict;
use warnings;
use base qw(ClearPress::model);

__PACKAGE__->mk_accessors(fields());

sub fields {
  return qw(id_derived_attr id_derived id_attribute);
}

1;
