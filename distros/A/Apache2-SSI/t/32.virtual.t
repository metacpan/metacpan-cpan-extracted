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

my $tests =
[
    {
        expect => qr/^[[:blank:]\h\v]*Hi.[[:blank:]\h\v]+There\./,
        uri => "${BASE_URI}/02.01.virtual.html",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*Hi.[[:blank:]\h\v]+02\.02\.virtual\.html/,
        uri => "${BASE_URI}/02.02.virtual.html",
        code => 200,
    },
];

run_tests( $tests,
{
    debug => 0,
    type => 'include virtual',
});

