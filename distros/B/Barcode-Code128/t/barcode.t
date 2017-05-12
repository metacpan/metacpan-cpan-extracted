# -*- Perl -*-

# Load the module
use Test::More tests => 3;
use strict;

BEGIN {
    $| = 1;
    use_ok('Barcode::Code128', qw(FNC1));
}

# Create a test barcode and make sure it is correct

ok(my $code = Barcode::Code128->new, 'constructor');

my $encoded = $code->barcode("1234 abcd");
cmp_ok($encoded, 'eq',
    "## #  ###  # ##  ###  #   # ##   # #### ### ## ##  ##  #  # ##    #".
    "  #    ## #    # ##  #    #  ## ###   # ## ##   ### # ##",
    "'1234 abcd' rendered as expected"
);
