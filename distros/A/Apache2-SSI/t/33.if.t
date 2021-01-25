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
        text => <<'EOT',
EOT
        expect => <<'EOT',

 Hi, should print



 Hi, should print



 Hi, should print



 Hi, should print

EOT
        name => 'basic expressions',
        uri => "${BASE_URI}/03.01.if.html",
        code => 200,
    },
    {
        expect => <<EOT,


6

EOT
        name => 'expression with variable declared',
        uri => "${BASE_URI}/03.02.if.html",
        code => 200,
    },
    {
        expect => <<EOT,

6

EOT
        name => 'using pre-declared variable',
        uri => "${BASE_URI}/03.03.if.html",
        code => 200,
    },
    {
        expect => <<EOT,

Found the query string

EOT
        name => 'apache2 v() variable',
        uri => "${BASE_URI}/03.04.if.html?q=hello&l=ja-JP",
        code => 200,
    },
    {
        expect => <<EOT,

Found the language in query string

EOT
        name => 'basic regular expression v1',
        uri => "${BASE_URI}/03.05.if.html?q=hello&l=ja-JP",
        code => 200,
    },
    {
        expect => <<EOT,

Non-existing file not found.

EOT
        no_warning => 1,
        name => 'access with -A (non-existing)',
        uri => "${BASE_URI}/03.06.if.html",
        code => 200,
    },
    {
        expect => <<EOT,

Found the expected file

EOT
        name => 'access with -A (existing)',
        uri => "${BASE_URI}/03.07.if.html",
        code => 200,
    },
    {
        expect => <<EOT,

Oh good, nothing found

EOT
        name => 'variable non-zero length with -n',
        uri => "${BASE_URI}/03.08.if.html",
        code => 200,
    },
    {
        expect => <<EOT,

Ok, found the query string

EOT
        name => 'variable non-zero length with !-z',
        uri => "${BASE_URI}/03.09.if.html?q=hello&l=ja-JP",
        code => 200,
    },
    {
        expect => <<EOT,

Remote ip is part of my private network

EOT
        name => 'remote ip against ip block',
        uri => "${BASE_URI}/03.10.if.html",
        code => 200,
        remote_ip => '192.168.2.20',
    },
    {
        expect => <<EOT,

Ok, remote ip is not part of my subnet

EOT
        name => 'explicit ip against ip block',
        uri => "${BASE_URI}/03.11.if.html",
        code => 200,
        remote_ip => '192.168.2.20',
    },
    {
        expect => <<EOT,

Ok, remote ip is not part of my subnet

EOT
        name => 'explicit ip against ip block (negative)',
        uri => "${BASE_URI}/03.12.if.html",
        code => 200,
        remote_ip => '192.168.2.20',
    },
    {
        expect => <<EOT,

Good, query string has a positive value.

EOT
        name => 'positive value of variable',
        uri => "${BASE_URI}/03.13.if.html?q=hello&l=ja-JP",
        code => 200,
    },
    {
        expect => <<EOT,

Good, that variable is empty.

EOT
        name => 'positive value of non-existing variable',
        uri => "${BASE_URI}/03.14.if.html",
        code => 200,
    },
    {
        expect => <<EOT,

Good, checked it was off.

EOT
        name => 'positive value of string "off"',
        uri => "${BASE_URI}/03.15.if.html",
        code => 200,
    },
];

run_tests( $tests,
{
    debug => 0,
    type => 'condition',
});

