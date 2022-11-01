#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    # use Test::More qw( no_plan );
    use Test::More;
    use lib './lib';
    use vars qw( $BASE_URI $DEBUG );
    # use_ok( 'Apache2::SSI' ) || BAIL_OUT( "Unable to load Apache2::SSI" );
    #use File::Basename;
    #my $filename = File::Basename::basename( __FILE__ );
    require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );
    our $BASE_URI;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

# $ENV{QUERY_STRING} = 'query';
my $tests =
[
    {
        expect => qr/^[[:blank:]\h\v]*Set one\:[[:blank:]\h\v]+Set two\:[[:blank:]\h\v]+Echo two: hi/,
        uri => "${BASE_URI}/04.01.set_var.html",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*foo \= bar[[:blank:]\h\v]+QUERY_STRING \= query[[:blank:]\h\v]+04.02.set_var.html[[:blank:]\h\v]+foo \= bar[[:blank:]\h\v]+QUERY_STRING = query/,
        uri => "${BASE_URI}/04.02.set_var.html?query",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*The query string is: query/,
        uri => "${BASE_URI}/04.03.set_var.html?query",
        code => 200,
    },
];

run_tests( $tests,
{
    debug => 0,
    type => 'set var',
});

