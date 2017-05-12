# -*- Mode: Perl -*-

BEGIN { unshift @INC, "lib", "../lib" }
use strict;
use Data::Compare;

local $^W = 1;
print "1..4\n";

my $test = 0;

print 'not ' unless(Compare(
    { foo => 'FOO', bar => 'BAR', baz => 'BAZ' },
    { foo => 'FOO', bar => 'BAR' },
    { ignore_hash_keys => [qw(baz)] }
) == 1);
print 'ok '.(++$test)." different hashes compare the same when ignoring extra key in first\n";

print 'not ' unless(Compare(
    { foo => 'FOO', bar => 'BAR' },
    { foo => 'FOO', bar => 'BAR', baz => 'BAZ' },
    { ignore_hash_keys => [qw(baz)] }
) == 1);
print 'ok '.(++$test)." different hashes compare the same when ignoring extra key in second\n";

print 'not ' unless(Compare(
    { foo => 'FOO', bar => 'BAR', baz => [] },
    { foo => 'FOO', bar => 'BAR', baz => 'BAZ' },
    { ignore_hash_keys => [qw(baz)] }
) == 1);
print 'ok '.(++$test)." ignoring a key that differs works\n";

print 'not ' unless(Compare(
    { foo => 'FOO', bar => 'BAR', baz => [] },
    { foo => 'FOO', bar => 'BAR', baz => 'BAZ' },
    { ignore_hash_keys => [qw(bar)] }
) == 0);
print 'ok '.(++$test)." ignoring equal data in differing hashes compares unequal\n";
