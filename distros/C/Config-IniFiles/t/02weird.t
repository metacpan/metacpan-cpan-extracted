#!/usr/bin/perl

use strict;
use warnings;

# Should be 6.
use Test::More tests => 6;

use Config::IniFiles;

use lib "./t/lib";

use Config::IniFiles::Debug;
use Config::IniFiles::TestPaths;

my ( $ini, $value );

$ini = Config::IniFiles->new( -file => t_file("test.ini") );
$ini->_assert_invariants();
$ini->SetFileName( t_file("test02.ini") );
$ini->SetWriteMode("0666");

# print "Weird characters in section name . ";
$value = $ini->val( '[w]eird characters', 'multiline' );
$ini->_assert_invariants();

# TEST
is(
    $value,
    "This$/is a multi-line$/value",
    "Weird characters in section name",
);

$ini->newval( "test7|anything", "exists", "yes" );
$ini->_assert_invariants();
$ini->RewriteConfig;
$ini->ReadConfig;
$ini->_assert_invariants();
$value = $ini->val( "test7|anything", "exists" );

# TEST
is( $value, "yes", "More weird chars.", );

# Test 3/4
# Make sure whitespace after parameter name is not included in name
# TEST
is(
    $ini->val( 'test7', 'criterion' ),
    'price <= maximum',
    "Make sure whitespace after parameter name is not included in name",
);

# TEST
ok(
    !defined $ini->val( 'test7', 'criterion ' ),
    "For criterion containing whitespace returns undef.",
);

# Test 5
# Build a file from scratch with tied interface for testing
my %test;

# TEST
ok( ( tie %test, 'Config::IniFiles' ), "Tying is successful" );
tied(%test)->SetFileName( t_file('test02.ini') );

# Test 6
# Also with pipes when using tied interface using vlaue of 0
$test{'2'} = {};
tied(%test)->_assert_invariants();
$test{'2'}{'test'} = "sleep";
tied(%test)->_assert_invariants();
my $sectionheader = "0|2";
$test{$sectionheader} = {};
tied(%test)->_assert_invariants();
$test{$sectionheader}{'vacation'} = 0;
tied(%test)->_assert_invariants();
tied(%test)->RewriteConfig();
tied(%test)->ReadConfig;

# TEST
ok( scalar( $test{$sectionheader}{'vacation'} == 0 ), "Returned 0", );

# Clean up when we're done
t_unlink("test02.ini");

