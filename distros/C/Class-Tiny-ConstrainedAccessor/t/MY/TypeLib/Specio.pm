#!perl
# Specio type library.  Used by MY::Class::Specio.

package MY::TypeLib::Specio;
use 5.006;
use strict;
use warnings;

use Scalar::Util qw(looks_like_number);

use parent 'Specio::Exporter';
use Specio::Declare;
use Specio::Library::Builtins;

# Regular version - non-inlineable
declare('MediumInteger',
    parent => t('Int'),
    where => sub { $_[0] >= 10 and $_[0] < 20 },
);

# An inlineable version so we can test the inline_check code path.
declare('MediumIntegerInline',
    inline => sub {
        my ($self, $var) = @_;
        return qq[(
            Scalar::Util::looks_like_number($var) &&
                ($var >= 10) && ($var < 20)
        )];
    },
);

# Sanity check
for(qw(MediumInteger MediumIntegerInline)) {
    t($_)->validate_or_die(15);
    t($_)->value_is_valid(0) and die "Unexpected validation success in $_";
}

1;
