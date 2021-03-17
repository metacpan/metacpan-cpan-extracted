#!/usr/local/bin/perl
BEGIN
{
    ## use Test::More qw( no_plan );
    use Test::More;
    use lib './lib';
    # use_ok( 'Apache2::SSI' ) || BAIL_OUT( "Unable to load Apache2::SSI" );
    require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );
    our $BASE_URI;
};

## Used for Apache/mod_perl
$ENV{QUERY_STRING} = 'q=hello&l=ja-JP';
## $ENV{REMOTE_ADDR} = '192.168.2.20';
my $tests =
[
    {
        expect => qr/^[[:blank:]\h\v]*Hi, should print[[:blank:]\h\v]+Hi, should print[[:blank:]\h\v]+Hi, should print[[:blank:]\h\v]+Hi, should print/,
        name => 'basic expressions',
        uri => "${BASE_URI}/03.01.if.html",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*6/,
        name => 'expression with variable declared',
        uri => "${BASE_URI}/03.02.if.html",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]+6/,
        name => 'using pre-declared variable',
        uri => "${BASE_URI}/03.03.if.html",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*Found the query string/,
        name => 'apache2 v() variable',
        uri => "${BASE_URI}/03.04.if.html?q=hello&l=ja-JP",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*Found the language in query string/,
        name => 'basic regular expression v1',
        uri => "${BASE_URI}/03.05.if.html?q=hello&l=ja-JP",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*Non-existing file not found\./,
        no_warning => 1,
        name => 'access with -A (non-existing)',
        uri => "${BASE_URI}/03.06.if.html",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*Found the expected file/,
        name => 'access with -A (existing)',
        uri => "${BASE_URI}/03.07.if.html",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*Oh good, nothing found/,
        name => 'variable non-zero length with -n',
        uri => "${BASE_URI}/03.08.if.html",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*Ok, found the query string/,
        name => 'variable non-zero length with !-z',
        uri => "${BASE_URI}/03.09.if.html?q=hello&l=ja-JP",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*Remote ip is part of my private network/,
        name => 'remote ip against ip block',
        uri => "${BASE_URI}/03.10.if.html",
        code => 200,
        remote_ip => '192.168.2.20',
    },
    {
        expect => qr/^[[:blank:]\h\v]*Ok, remote ip is not part of my subnet/,
        name => 'explicit ip against ip block',
        uri => "${BASE_URI}/03.11.if.html",
        code => 200,
        remote_ip => '192.168.2.20',
    },
    {
        expect => qr/^[[:blank:]\h\v]*Ok, remote ip is not part of my subnet/,
        name => 'explicit ip against ip block (negative)',
        uri => "${BASE_URI}/03.12.if.html",
        code => 200,
        remote_ip => '192.168.2.20',
    },
    {
        expect => qr/^[[:blank:]\h\v]*Good, query string has a positive value\./,
        name => 'positive value of variable',
        uri => "${BASE_URI}/03.13.if.html?q=hello&l=ja-JP",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*Good, that variable is empty\./,
        name => 'positive value of non-existing variable',
        uri => "${BASE_URI}/03.14.if.html",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*Good, checked it was off\./,
        name => 'positive value of string "off"',
        uri => "${BASE_URI}/03.15.if.html",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*https:\/\/ja-jp.example.com[[:blank:]\h\v]*$/,
        name => 'using regex back reference',
        uri => "${BASE_URI}/03.16.if.html",
        code => 200,
        headers => {
            Cookie => q{sitePrefs=%7B%22lang%22%3A%22ja-JP%22%7D}
        },
        legacy => 1,
    },
];

run_tests( $tests,
{
    debug => 0,
    type => 'condition',
});

