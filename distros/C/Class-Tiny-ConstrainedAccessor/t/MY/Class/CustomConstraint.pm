#!perl
package MY::Class::CustomConstraint;
use 5.006;
use strict;
use warnings;
use Scalar::Util qw(looks_like_number);

use vars::i '$MediumInteger' =>
    [   # checker
        sub { looks_like_number($_[0]) and $_[0] >= 10 and $_[0] < 20 },
        # get_message
        sub { ($_[0]||'falsy value') . " is not a medium integer" },
    ];

use Class::Tiny::ConstrainedAccessor
    medint => $MediumInteger,           # create accessor sub medint()
    med_with_default => $MediumInteger,
    lazy_default => $MediumInteger,
;

# After using ConstrainedAccessor
use Class::Tiny qw(medint regular), {
    med_with_default => 12,
    lazy_default => sub { 19 },
};

1;
