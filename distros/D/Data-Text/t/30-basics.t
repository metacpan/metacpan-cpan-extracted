#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most tests => 11;	# Combines Test::More, Test::Exception, etc.
use Test::NoWarnings;
# use lib 'lib';	# Add the path to the module

BEGIN { use_ok('Data::Text') }

# Test new() and as_string()
my $text = Data::Text->new('Hello');
isa_ok($text, 'Data::Text', 'Object created');
is($text->as_string(), 'Hello', 'Initial text set correctly');

# Test append()
$text->append(', World!');
is($text->as_string(), 'Hello, World!', 'Text appended correctly');

# Test equality
my $text2 = Data::Text->new('Hello, World!');
cmp_ok($text, '==', $text2, 'Objects are equal');
cmp_ok($text, '!=', Data::Text->new('Different'), 'Objects are not equal');

# Test trim
$text->append('   ');
$text->trim();
is($text->as_string(), 'Hello, World!', 'Trim removes trailing/leading spaces');

# Test replace
$text->replace({ 'World' => 'Perl' });
is($text->as_string(), 'Hello, Perl!', 'Replace works correctly');

# Test appendconjunction()
my $conj_text = Data::Text->new();
$conj_text->appendconjunction('nan', 'tulip', 'xxx-xxxx-C');
is($conj_text->as_string(), 'nan, tulip, and xxx-xxxx-C', 'Conjunction appended correctly');

# Test length()
is($text->length(), length('Hello, Perl!'), 'Length calculated correctly');
