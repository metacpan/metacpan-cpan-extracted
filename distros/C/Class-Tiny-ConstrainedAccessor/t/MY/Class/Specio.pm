#!perl
package MY::Class::Specio;
use 5.006;
use strict;
use warnings;
our @ISA;
use Scalar::Util qw(looks_like_number);

use Type::Tiny;

use MY::TypeLib::Specio;

use Class::Tiny::ConstrainedAccessor
    medint => t('MediumInteger'),
    med_with_default => t('MediumInteger'),
    lazy_default => t('MediumInteger'),
;

BEGIN { undef @ISA; }   # So we're not a Mouse class
    # See https://metacpan.org/release/Class-Tiny/source/lib/Class/Tiny.pm#L27

# After using ConstrainedAccessor, we use this
use Class::Tiny qw(medint regular), {
    med_with_default => 12,
    lazy_default => sub { 19 },
};

1;
