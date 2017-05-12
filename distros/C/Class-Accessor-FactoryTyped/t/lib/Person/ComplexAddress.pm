package Person::ComplexAddress;
use warnings;
use strict;
use parent 'Class::Accessor::Complex';
__PACKAGE__->mk_new->mk_scalar_accessors(qw(street city postalcode country));
1;
