#!/usr/local/bin/perl
BEGIN
{
    ## use Test::More qw( no_plan );
    use Test::More;
    use lib './lib';
    ## use_ok( 'Apache2::SSI' ) || BAIL_OUT( "Unable to load Apache2::SSI" );
    #use File::Basename;
    #my $filename = File::Basename::basename( __FILE__ );
    require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );
    our $BASE_URI;
};

# $ENV{QUERY_STRING} = 'query';
my $tests =
[
    {
        expect => <<EOT,
Set one: 
Set two: 
Echo two: hi
EOT
        uri => "${BASE_URI}/04.01.set_var.html",
        code => 200,
    },
    {
        expect => <<EOT,

foo = bar
QUERY_STRING = query

04.02.set_var.html

foo = bar
QUERY_STRING = query
EOT
        uri => "${BASE_URI}/04.02.set_var.html?query",
        code => 200,
    },
    {
        expect => <<EOT,

The query string is: query

EOT
        uri => "${BASE_URI}/04.03.set_var.html?query",
        code => 200,
    },
];

run_tests( $tests,
{
    debug => 0,
    type => 'set var',
});

