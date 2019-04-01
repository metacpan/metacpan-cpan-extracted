#!perl
package MY::Class::Specio;
use 5.006;
use strict;
use warnings;

use Type::Tiny;

use MY::TypeLib::Specio;

use Class::Tiny::ConstrainedAccessor
    medint => t('MediumInteger'),
    med_with_default => t('MediumIntegerInline'),   # for coverage
    lazy_default => t('MediumInteger'),
;

# After using ConstrainedAccessor, we use this
use Class::Tiny qw(medint regular), {
    med_with_default => 12,
    lazy_default => sub { 19 },
};

1;
