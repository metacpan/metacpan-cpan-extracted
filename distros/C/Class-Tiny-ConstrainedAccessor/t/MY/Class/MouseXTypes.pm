#!perl
# MOUSE
package MY::Class::MouseXTypes;
use 5.006;
use strict;
use warnings;
our @ISA;
use Scalar::Util qw(looks_like_number);

use Type::Tiny;

use Mouse;
use MY::TypeLib::MouseX qw(MediumInteger);

use Class::Tiny::ConstrainedAccessor
    medint => MediumInteger,
    med_with_default => MediumInteger,
    lazy_default => MediumInteger,
;

BEGIN { undef @ISA; }   # So we're not a Mouse class
    # See https://metacpan.org/release/Class-Tiny/source/lib/Class/Tiny.pm#L27

# After using ConstrainedAccessor, we use this
use Class::Tiny qw(medint regular), {
    med_with_default => 12,
    lazy_default => sub { 19 },
};

1;
