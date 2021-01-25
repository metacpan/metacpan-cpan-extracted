#!/usr/local/bin/perl
BEGIN
{
    use lib './lib';
    use Test::More qw( no_plan );
    require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );
    our $BASE_URI;
};

my $tests =
[
    {
        text => <<EOT,
Hi.

This was a test.
EOT
        expect => <<EOT,
Hi.

This was a test.
EOT
        uri => "${BASE_URI}/00.bare.html",
        code => 200,
    },
];

run_tests( $tests,
{
    debug => 0,
    type => 'bare',
});

