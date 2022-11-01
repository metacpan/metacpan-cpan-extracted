#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use Test::More;
    use lib './lib';
    use vars qw( $BASE_URI $DEBUG );
    require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );
    our $BASE_URI;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

my $tests =
[
    {
        expect => qr/^[[:blank:]\h\v]*Hi.[[:blank:]\h\v]+There\./,
        uri => "${BASE_URI}/01.file.html",
        code => 200,
    },
];

run_tests( $tests,
{
    debug => $DEBUG,
    type => 'include file',
});

