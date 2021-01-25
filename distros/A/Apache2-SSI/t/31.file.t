#!/usr/local/bin/perl
BEGIN
{
    use Test::More;
    use lib './lib';
    require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );
    our $BASE_URI;
};

my $tests =
[
    {
        expect => <<EOT,
Hi.

There.

EOT
        uri => "${BASE_URI}/01.file.html",
        code => 200,
    },
];

run_tests( $tests,
{
    debug => 0,
    type => 'include file',
});

