#!/usr/local/bin/perl
BEGIN
{
    ## use Test::More qw( no_plan );
    use Test::More;
    use lib './lib';
    ## use_ok( 'Apache2::SSI' ) || BAIL_OUT( "Unable to load Apache2::SSI" );
    require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );
    our $BASE_URI;
    our $DEBUG = 0;
};

$ENV{QUERY_STRING} = 'q=hello&l=ja-JP';

use utf8;
my $tests =
[
    {
        expect => <<EOT,

This worked!


EOT
        name => 'base64',
        uri => "${BASE_URI}/09.01.functions.html",
        code => 200,
    },
    {
        expect => <<EOT,

This worked!


EOT
        name => 'env',
        uri => "${BASE_URI}/09.02.functions.html?q=hello&l=ja-JP",
        code => 200,
    },
    {
        expect => <<EOT,

This worked!


EOT
        name => 'escape',
        uri => "${BASE_URI}/09.03.functions.html",
        code => 200,
    },
    {
        expect => <<EOT,

This worked!


EOT
        name => 'http',
        requires => 'mod_perl',
        uri => "${BASE_URI}/09.04.functions.html",
        code => 200,
    },
    {
        expect => <<EOT,

This worked!


EOT
        name => 'ldap',
        uri => "${BASE_URI}/09.05.functions.html",
        code => 200,
    },
    {
        expect => <<EOT,

This worked!


EOT
        name => 'md5',
        uri => "${BASE_URI}/09.06.functions.html",
        code => 200,
    },
    {
        expect => <<EOT,

This worked!


EOT
        name => 'note',
        requires => 'mod_perl',
        'sub' => sub
        {
            my $ssi = shift( @_ );
            $ssi->notes( CustomerId => 1234 );
        },
        uri => "${BASE_URI}/09.07.functions.html",
        code => 200,
        fail => ( !Apache2::SSI::Notes->supported ),
    },
    {
        expect => <<EOT,

This worked!


EOT
        name => 'osenv',
        requires => 'mod_perl',
        'sub' => sub
        {
            my $ssi = shift( @_ );
            $ssi->notes( CustomerId => 1234 );
        },
        uri => "${BASE_URI}/09.08.functions.html",
        code => 200,
    },
    {
        expect => <<EOT,

This worked!


EOT
        name => 'replace',
        uri => "${BASE_URI}/09.09.functions.html",
        code => 200,
    },
    {
        expect => <<EOT,

This worked!


EOT
        name => 'reqenv',
        requires => 'mod_perl',
        'sub' => sub
        {
            my $ssi = shift( @_ );
            $ssi->env( ProcessId => $$ );
        },
        uri => "${BASE_URI}/09.10.functions.html",
        code => 200,
    },
    {
        expect => <<EOT,

This worked!


EOT
        name => 'resp',
        requires => 'mod_perl',
        uri => "${BASE_URI}/09.11.functions.html",
        code => 200,
    },
    {
        expect => <<EOT,

This worked!


EOT
        name => 'sha1',
        uri => "${BASE_URI}/09.12.functions.html",
        code => 200,
    },
    {
        expect => <<EOT,

This worked!


EOT
        name => 'tolower',
        uri => "${BASE_URI}/09.13.functions.html",
        code => 200,
    },
    {
        expect => <<EOT,

This worked!


EOT
        name => 'toupper',
        uri => "${BASE_URI}/09.14.functions.html",
        code => 200,
    },
    {
        expect => <<EOT,

This worked!


EOT
        name => 'unbase64',
        uri => "${BASE_URI}/09.15.functions.html",
        code => 200,
    },
    {
        expect => <<EOT,

This worked!


EOT
        name => 'unescape',
        uri => "${BASE_URI}/09.16.functions.html",
        code => 200,
    },
];

run_tests( $tests,
{
    debug => $DEBUG,
    type => 'functions',
});

