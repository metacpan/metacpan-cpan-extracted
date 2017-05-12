#!/usr/bin/perl -w
use strict;
use Test;

plan tests => 6;

use Crypt::Simple;

my @plain = qw/this is a test/;
my $ciphertext = encrypt(@plain);

ok($ciphertext);

my @out = decrypt($ciphertext);
ok(scalar @plain == scalar @out);
for (my $i=0; $i<@plain; ++$i) {
	ok($plain[$i] eq $out[$i]);
}
