package t::model::response;
use strict;
use warnings;
use base qw(ClearPress::model);

__PACKAGE__->mk_accessors(fields());

sub fields {
  return qw(code name);
}

1;
