#!/usr/bin/perl

# t/00.load.t - check module loading and create testing directory
BEGIN
{
    use strict;
    use warnings;
    # use Test::More qw( no_plan );
    use Test::More tests => 2;
    use_ok( 'Apache2::SSI' );
};

use strict;
use warnings;

my $object = Apache2::SSI->new(
    debug => 0,
    document_uri => '../index.html?q=something&l=en_GB',
    document_root => './t/htdocs',
) || BAIL_OUT( Apache2::SSI->error );
isa_ok( $object, 'Apache2::SSI' );

