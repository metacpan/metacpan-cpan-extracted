#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    # use Test::More qw( no_plan );
    use Test::More;
    # use_ok( 'Apache2::SSI' ) || BAIL_OUT( "Unable to load Apache2::SSI" );
    use lib './lib';
    use vars qw( $BASE_URI $DEBUG );
    require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );
    our $BASE_URI;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

$ENV{PATH_INFO}    = '/path';
# $ENV{QUERY_STRING} = 'query';

my $tests =
[
    {
        expect => qr/^[[:blank:]\h\v]*Hi\, here's a 5\:[[:blank:]\h\v]+5\; path_info\: \/path\; query_string\: query\;[[:blank:]\h\v]+Right\?/,
        name => 'executing cgi',
        uri => "${BASE_URI}/05.01.exec.html/path?query",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*Hi, here's a 5\:[[:blank:]\h\v]+5[[:blank:]\h\v]+Right\?/,
        name => 'executing cmd',
        uri => "${BASE_URI}/05.02.exec.html",
        code => 200,
    },
    ## This should fail
    {
        expect => '',
        name => 'executing relative path cgi not existing [should fail]',
        fail => 1,
        uri => "${BASE_URI}/05.03.exec.html",
        code => 200,
    },
    ## This should fail
    {
        expect => '',
        name => 'executing relative path cgi forbidden [should fail]',
        fail => 1,
        uri => "${BASE_URI}/05.04.exec.html",
        code => 200,
    },
];

run_tests( $tests,
{
    debug => $DEBUG,
    type => 'exec',
});

