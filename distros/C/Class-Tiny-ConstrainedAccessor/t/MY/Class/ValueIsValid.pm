#!perl
package MY::Class::ValueIsValid;
use 5.006;
use strict;
use warnings;

use MY::TypeLib::ValueIsValid;

use Class::Tiny::ConstrainedAccessor
    medint => $MediumInteger,
    med_with_default => $MediumInteger,
    lazy_default => $MediumInteger,
;

# After using ConstrainedAccessor, we use this
use Class::Tiny qw(medint regular), {
    med_with_default => 12,
    lazy_default => sub { 19 },
};

1;
