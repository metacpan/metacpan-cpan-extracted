#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    # use Test2::V0;
    use Test::More;
    use vars qw( $DEBUG );
    use ok( 'Apache2::API::Query' ) || bail_out( "Cannot load Apache2::API::Query" );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
    require( "./t/env.pl" ) if( -e( "t/env.pl" ) );
};

use strict;
use warnings;

my $qq = Apache2::API::Query->new( 'foo=1&foo=2&bar=3;bog=abc;bar=7;fluffy=3' );
isa_ok( $qq, 'Apache2::API::Query' );

# To generate this list:
# perl -lnE '/^sub (?!init|[A-Z]|_)/ and say "can_ok( \$qq, \''", [split(/\s+/, $_)]->[1], "\'' );"' ./lib/Apache2/API/Query.pm
can_ok( $qq, 'strip' );
can_ok( $qq, 'strip_except' );
can_ok( $qq, 'strip_null' );
can_ok( $qq, 'strip_like' );
can_ok( $qq, 'replace' );
can_ok( $qq, 'stringify' );
can_ok( $qq, 'qstringify' );
can_ok( $qq, 'revert' );
can_ok( $qq, 'has_changed' );
can_ok( $qq, 'hash' );
can_ok( $qq, 'hash_arrayref' );
can_ok( $qq, 'hidden' );
can_ok( $qq, 'separator' );
can_ok( $qq, '_deepcopy' );
can_ok( $qq, '_parse_qs' );
can_ok( $qq, '_init_from_arrayref' );

# borrowed from Apache2::API::Query
is( $qq->stringify, 'bar=3&bar=7&bog=abc&fluffy=3&foo=1&foo=2', 'stringify' );
ok( $qq = Apache2::API::Query->new( foo => 1, foo => 2, bar => 3, bog => 'abc', bar => 7, fluffy => 3 ), 'object from hash' );
is( $qq->stringify, 'bar=3&bar=7&bog=abc&fluffy=3&foo=1&foo=2', 'stringify from hash' );

# Constructor - hashref version
ok( $qq = Apache2::API::Query->new({ foo => [ 1, 2 ], bar => [ 3, 7 ], bog => 'abc', fluffy => 3 }), 'object from hash reference' );
is( $qq->stringify, 'bar=3&bar=7&bog=abc&fluffy=3&foo=1&foo=2', 'stringify from hash reference' );

# Constructor - CGI.pm-style hashref version, packed values
ok( $qq = Apache2::API::Query->new({ foo => "1\0002", bar => "3\0007", bog => 'abc', fluffy => 3 }), 'object from cgi-style hash reference' );
is( $qq->stringify, 'bar=3&bar=7&bog=abc&fluffy=3&foo=1&foo=2', 'stringify from hash reference' );

# NOTE: methods check
# strip
ok( $qq->strip( qw(foo bog) ), 'strip' );
is( $qq->stringify, 'bar=3&bar=7&fluffy=3', 'strip -> stringify' );

# Simple replace
$qq = Apache2::API::Query->new( 'foo=1&foo=2&bar=3;bog=abc;bar=7;fluffy=3' );
ok( $qq->replace( foo => 'xyz', bog => 'magic', extra => 1 ), 'replace' );
is( $qq->stringify, 'bar=3&bar=7&bog=magic&extra=1&fluffy=3&foo=xyz', 'replace -> stringify' );

# Composite replace
ok( $qq->replace(foo => [ 123, 456, 789 ], extra => 2), 'replace' );
is( $qq->stringify, 'bar=3&bar=7&bog=magic&extra=2&fluffy=3&foo=123&foo=456&foo=789', 'replace -> stringify' );

# Auto-stringification
is( "$qq", 'bar=3&bar=7&bog=magic&extra=2&fluffy=3&foo=123&foo=456&foo=789', 'stringification' );

# strip_except
ok( $qq->strip_except( qw(bar foo extra) ), 'strip_except' );
is( $qq->stringify, 'bar=3&bar=7&extra=2&foo=123&foo=456&foo=789', 'strip_except -> stringify' );

# strip_null
ok( $qq = Apache2::API::Query->new( foo => 1, foo => 2, bar => '', bog => 'abc', zero => 0, fluffy => undef ), 'object from hash' );
ok( $qq->strip_null, 'strip_null' );
is( $qq->stringify, 'bog=abc&foo=1&foo=2&zero=0', 'strip_null -> stringify' );

# strip_like
ok( $qq = Apache2::API::Query->new( 'foo=1&foo=2&bar=3;bog=abc;bar=7;fluffy=3;zero=0' ), 'object from query string' );
ok( $qq->strip_like( qr/^b/ ), 'strip_like' );
is( $qq->stringify, 'fluffy=3&foo=1&foo=2&zero=0', 'strip_like -> stringify' );
ok( $qq->strip_like( qr/^f[lzx]/ ), 'strip_like' );
is( $qq->stringify, 'foo=1&foo=2&zero=0', 'strip_like -> stringify' );
ok( $qq->strip_like( qr/\d/ ), 'strip_like' );
is( $qq->stringify, 'foo=1&foo=2&zero=0', 'strip_like -> stringify' );

subtest "revert" => sub
{
    ok( $qq = Apache2::API::Query->new( 'foo=1&foo=2&bar=3;bog=abc;bar=7;fluffy=3'), 'object from query string' );
    my $str1 = $qq->stringify;

    # Strip
    $qq->strip( qw(foo fluffy) );
    my $str2 = $qq->stringify;
    isnt( $str1, $str2, 'strings different after strip' );

    # Revert
    $qq->revert;
    my $str3 = $qq->stringify;
    is( $str1, $str3, 'strings identical after revert' );
};

subtest "eq" => sub
{
    my( $qq1, $qq2 );

    ok( $qq1 = Apache2::API::Query->new( 'foo=1&foo=2&bar=3' ), 'object from query string' );
    ok( $qq2 = Apache2::API::Query->new( 'foo=1&bar=3&foo=2' ), 'object from query string' );
    is( $qq1, $qq2, 'eq' );
    ok( $qq2 = Apache2::API::Query->new( 'bar=3&foo=1&foo=2' ), 'object from query string' );
    is( $qq1, $qq2, 'eq' );
    ok( $qq2 = Apache2::API::Query->new( 'bar=3&foo=2&foo=1' ), 'object from query string' );
    isnt( $qq1, $qq2, 'ne ok (value ordering preserved)' );
    ok( $qq2 = Apache2::API::Query->new( 'bar=3' ), 'object from query string' );
    isnt( $qq1, $qq2, 'ne ok' );
};

subtest 'unescape' => sub
{
    my $data_esc =
    {
    group     => 'prod%2Cinfra%2Ctest',
    'op%3Aset'  => 'x%3Dy',
    };
    my $data_unesc =
    {
    group     => 'prod,infra,test',
    'op:set'  => 'x=y',
    };
    my $qs_esc = 'group=prod%2Cinfra%2Ctest&op%3Aset=x%3Dy';
    my( $qq, $qs );

    ok( $qq = Apache2::API::Query->new( $qs_esc ), 'object from unescaped query string' );
    is_deeply( scalar( $qq->hash ), $data_unesc, '$qq->hash keys and values are unescaped' );
    is( "$qq", $qs_esc, 'stringification escapes keys/values' );

    ok( $qq = Apache2::API::Query->new( $data_esc ), 'object from unescaped hash reference' );
    is_deeply( scalar $qq->hash, $data_unesc, '$qq->hash keys and values are unescaped' );
    is( "$qq", $qs_esc, 'stringification escapes keys/values' );

    ok( $qq = Apache2::API::Query->new( %$data_esc ), 'object from unescaped hash' );
    is_deeply( scalar $qq->hash, $data_unesc, '$qq->hash keys and values are unescaped' );
    is( "$qq", $qs_esc, 'stringification escapes keys/values' );
};

subtest 'has_changed' => sub
{
    my $qq;
    ok( $qq = Apache2::API::Query->new( 'foo=1&foo=2&bar=3;bog=;bar=7;fluffy=3'), 'object from query string' );
    ok( !$qq->has_changed, 'has_changed returns false' );

    # strip
    $qq->strip( qw(bogus) );
    ok( !$qq->has_changed, 'has_changed returns false after removing non-existing element' );
    $qq->strip( qw(foo fluffy) );
    ok( $qq->has_changed > 0, 'has_changed returns true after strip' );

    # revert
    $qq->revert;
    ok( !$qq->has_changed, 'has_changed returns false after revert' );

    # strip except
    $qq->strip_except( qw(foo bar bog bar fluffy) );
    ok( !$qq->has_changed, 'has_changed returns false after strip_except on all elements' );
    $qq->strip_except( qw(foo) );
    ok( $qq->has_changed > 0, 'has_changed returns true after strip_except' );

    # revert
    $qq->revert;
    ok( !$qq->has_changed, 'has_changed returns false after revert' );

    # strip_null
    $qq->strip_null;
    ok( $qq->has_changed > 0, 'has_changed returns true after strip_null' );

    # revert
    $qq->revert;
    ok( !$qq->has_changed, 'has_changed returns false after revert' );
};

subtest 'clone' => sub
{
    my $qq;

    ok( $qq = Apache2::API::Query->new( 'foo=1&foo=2&bar=3;bog=abc;bar=7;fluffy=3'), 'object from query string' );
    my $str1 = $qq->stringify;
    my $qstr = $qq->qstringify;
    is( $qstr, "?$str1", 'qstringify' );

    # Basic clone test
    is( $qq->clone->stringify, $str1, 'clone' );

    # Clone and make a change
    isnt( $qq->clone->strip( 'fluffy' )->stringify, $qq->stringify, 'changed clone stringifies differently' );

    # Identical changes stringify identically
    is( $qq->clone->strip( 'fluffy' )->qstringify, $qq->strip('fluffy')->qstringify, 'same changes qstringify identically' );
};

subtest 'japanese' => sub
{
    my $qs = 'lang=ja_JP&name=%E3%83%AA%E3%83%BC%E3%82%AC%E3%83%AB%E3%83%86%E3%83%83%E3%82%AF%E3%83%97%E3%83%AC%E3%83%9F%E3%82%A2%E3%83%A0';

    use utf8;
    my $test_string = 'リーガルテックプレミアム';
    my $q = Apache2::API::Query->new( $qs );
    isa_ok( $q, 'Apache2::API::Query' );
    my $h = $q->hash;
    is( $h->{name}, $test_string );
};

done_testing();

__END__

