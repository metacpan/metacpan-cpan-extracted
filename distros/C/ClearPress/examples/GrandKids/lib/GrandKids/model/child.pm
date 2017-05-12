
package GrandKids::model::child;
use strict;
use warnings;
use base qw(ClearPress::model);

__PACKAGE__->mk_accessors(__PACKAGE__->fields());
__PACKAGE__->has_a([qw(family )]);
__PACKAGE__->has_many([qw()]);
__PACKAGE__->has_all();

sub fields {
  return qw(id_child
	    id_family 
	    birthday name );
}

1;
 
