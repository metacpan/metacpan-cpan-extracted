#!/usr/bin/env perl5
use strict;
use warnings;

use Test::More tests => 14;
use CGI::Struct::XS;

# Test various bad inputs

my %inp = (
	# Mismatched delims
	'h{foo]' => 'hashfoo',
	'a[0}'   => 'arr0',

	# Missing delim
	'h{bar'  => 'hbar',

	# Multiple delims in a row
	'h{{{}'  => 'wtf',

	# Non-integer array key
	'a[bar]' => 'arrbar',
	'a[0bar]' => 'arr0bar',

	# Bad starting char
	'{xyz'  => 'badstart',

	# No key
	'h{}'   => 'nokey',
	'h.'    => 'dot nokey',
	'h..'   => 'dot dot nokey',
	'h{foo}.{bar}' => 'nested dot nokey',

	# Create a mismatch
	'm{xyz}' => 'mhash',
	'm[1]'   => 'marr',
);
my @errs;
my $hval = build_cgi_struct \%inp, \@errs;

# Should have a warning about the mismatches
ok(grep(/Not balanced delimiter for h\{foo\]/, @errs), "Got error for h{foo]");
ok(grep(/Not balanced delimiter for a\[0\}/, @errs), "Got error for a[0}");

# And the missing
ok(grep(/Not balanced delimiter for h\{bar/, @errs), "Got error for h{bar");

# Multiple?
ok(grep(/Not balanced delimiter for h\{\{\{}/, @errs), "Got error for h{{{}");

# Plus the non-integer keys
ok(grep(/Array index should be a number for a\[bar\]/, @errs),
   "Got error for a[bar]");
ok(grep(/Array index should be a number for a\[0bar\]/, @errs),
   "Got error for a[0bar]");

# Bad starting char
ok(grep(/Unexpected initial char '\{' for \{xyz/, @errs),
   "Got error for {xyz");

# No key
ok(grep(/Zero-length key name for h\{}/, @errs),
   "Got error for h{}");
ok(grep(/Zero-length key name for h\./, @errs),
   "Got error for h.");
ok(grep(/Zero-length key name for h\.\./, @errs),
   "Got error for h..");
ok(grep(/Zero-length key name for h\{foo}\.\{bar}/, @errs),
   "Got error for h{foo}.{bar}");


# This mismatch could come in either order
my $ok = scalar(grep /Type mismatch: m already used as ArrayRef for m\{xyz\}/, @errs) 
      || scalar(grep /Type mismatch: m already used as HashRef for m\[1\]/, @errs);
ok($ok, "Got error for m{xyz}");

# Every line but one (the key that creates the mismatched type for that
# test) should have an entry in the @errs.
is(@errs, keys(%inp) - 1, "An error for every input");

# We get 3 entries in the output hash; 1 for the mismatched type, and 1
# each for 'h' and 'a' that get far enough to be created.
is(keys %$hval, 3, "Only expected litter in the output");
