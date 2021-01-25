#!/usr/local/bin/perl
BEGIN
{
    ## use Test::More qw( no_plan );
    use Test::More;
    ## use_ok( 'Apache2::SSI' ) || BAIL_OUT( "Unable to load Apache2::SSI" );
    use lib './lib';
    require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );
    our $BASE_URI;
};

$ENV{PATH_INFO}    = '/path';
# $ENV{QUERY_STRING} = 'query';

my $tests =
[
    {
        expect => <<EOT,
Hi, here's a 5:
5; path_info: /path; query_string: query;
Right?
EOT
        name => 'executing cgi',
        uri => "${BASE_URI}/05.01.exec.html/path?query",
        code => 200,
    },
    {
        expect => <<EOT,
Hi, here's a 5:
5

Right?
EOT
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
    debug => 0,
    type => 'exec',
});

