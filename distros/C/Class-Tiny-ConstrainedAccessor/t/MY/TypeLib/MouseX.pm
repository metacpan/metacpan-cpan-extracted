#!perl
# Mouse type library.  Mouse requires type-library packages to inherit from
package MY::TypeLib::MouseX;
use 5.006;
use strict;
use warnings;
use MY::Helpers;
# within Mouse, so we put it in a separate package from SampleMouseXTypes.

use Scalar::Util qw(looks_like_number);

use MouseX::Types -declare => [
    qw(MediumInteger),
];

use MouseX::Types::Mouse qw(Int);

BEGIN {
    subtype MediumInteger,
        as Int,
        where { $_ >= 10 and $_ < 20 },
        message { _dor . ' is not an integer on [10,19]' };

    # Sanity check
    my $av = eval { MediumInteger->can('assert_valid') };
    die "cannot assert_valid: $@" unless $av;
}

1;
