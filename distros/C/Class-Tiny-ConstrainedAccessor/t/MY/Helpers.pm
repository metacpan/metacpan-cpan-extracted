package MY::Helpers;
use 5.006;
use strict;
use warnings;

use parent 'Exporter';
our @EXPORT=qw(_dor);

# Helper since <5.010 doesn't have `//`
sub _dor {
    my $x = @_ ? $_[0] : $_;
    defined $x ? $x :
        (defined $_[1] ? $_[1] : 'undef')
} #_dor()

1;

