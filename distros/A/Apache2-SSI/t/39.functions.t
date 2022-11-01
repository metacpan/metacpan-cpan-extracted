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
    require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );
    our $BASE_URI;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

$ENV{QUERY_STRING} = 'q=hello&l=ja-JP';

use utf8;
my $tests =
[
    {
        expect => qr/^[[:blank:]\h\v]*This worked\!/,
        name => 'base64',
        uri => "${BASE_URI}/09.01.functions.html",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*This worked\!/,
        name => 'env',
        uri => "${BASE_URI}/09.02.functions.html?q=hello&l=ja-JP",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*This worked\!/,
        name => 'escape',
        uri => "${BASE_URI}/09.03.functions.html",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*This worked\!/,
        name => 'http',
        requires => 'mod_perl',
        uri => "${BASE_URI}/09.04.functions.html",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*This worked\!/,
        name => 'ldap',
        uri => "${BASE_URI}/09.05.functions.html",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*This worked\!/,
        name => 'md5',
        uri => "${BASE_URI}/09.06.functions.html",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*This worked\!/,
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
        expect => qr/^[[:blank:]\h\v]*This worked\!/,
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
        expect => qr/^[[:blank:]\h\v]*This worked\!/,
        name => 'replace',
        uri => "${BASE_URI}/09.09.functions.html",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*This worked\!/,
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
        expect => qr/^[[:blank:]\h\v]*This worked\!/,
        name => 'resp',
        requires => 'mod_perl',
        uri => "${BASE_URI}/09.11.functions.html",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*This worked\!/,
        name => 'sha1',
        uri => "${BASE_URI}/09.12.functions.html",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*This worked\!/,
        name => 'tolower',
        uri => "${BASE_URI}/09.13.functions.html",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*This worked\!/,
        name => 'toupper',
        uri => "${BASE_URI}/09.14.functions.html",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*This worked\!/,
        name => 'unbase64',
        uri => "${BASE_URI}/09.15.functions.html",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*This worked\!/,
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

