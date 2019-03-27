#!perl
package MY::Class::MooseXTypes;
use 5.006;
use strict;
use warnings;
use MY::Helpers;

our @ISA;
use Scalar::Util qw(looks_like_number);

use Type::Tiny;

use MooseX::Types -declare => [
    qw(MediumInteger),
];

use MooseX::Types::Moose qw(Int);

BEGIN {
    subtype MediumInteger,
        as Int,
        where { $_ >= 10 and $_ < 20 },
        message { _dor . ' is not an integer on [10,19]' };

    # Sanity check
    my $av = eval { MediumInteger->can('assert_valid') };
    die "cannot assert_valid: $@" unless $av;
}

use Class::Tiny::ConstrainedAccessor
    medint => MediumInteger,
    med_with_default => MediumInteger,
    lazy_default => MediumInteger,
;

BEGIN { undef @ISA; }   # So we're not a Moose class
    # See https://metacpan.org/release/Class-Tiny/source/lib/Class/Tiny.pm#L27

# After using ConstrainedAccessor, we use this
use Class::Tiny qw(medint regular), {
    med_with_default => 12,
    lazy_default => sub { 19 },
};

1;
