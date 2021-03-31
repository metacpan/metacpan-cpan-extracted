#!/usr/local/bin/perl
BEGIN
{
    use Test::More;
    use lib './lib';
    require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );
    our $BASE_URI;
    our $DEBUG = 0;
};

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

