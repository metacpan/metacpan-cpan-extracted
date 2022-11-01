#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $BASE_URI $DEBUG );
    use Test::More qw( no_plan );
    require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );
    our $BASE_URI;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

my $tests =
[
    {
        text => <<EOT,
Hi.

This was a test.
EOT
        expect => qr/^[[:blank:]\h\v]*Hi.[[:blank:]\h\v]+This was a test\./,
        uri => "${BASE_URI}/00.bare.html",
        code => 200,
    },
];

run_tests( $tests,
{
    debug => 0,
    type => 'bare',
});

