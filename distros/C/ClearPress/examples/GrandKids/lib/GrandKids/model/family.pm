
package GrandKids::model::family;
use strict;
use warnings;
use base qw(ClearPress::model);

__PACKAGE__->mk_accessors(__PACKAGE__->fields());
__PACKAGE__->has_a([qw()]);
__PACKAGE__->has_many([qw(child )]);
__PACKAGE__->has_all();

sub fields {
  return qw(id_family
	    
	    address city name state zip );
}

1;
 
