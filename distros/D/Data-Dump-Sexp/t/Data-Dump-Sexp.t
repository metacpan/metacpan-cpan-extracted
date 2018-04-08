#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 10;
BEGIN { use_ok('Data::Dump::Sexp') };

use Data::SExpression;

is dump_sexp(5), 5;
is dump_sexp('yes'), '"yes"';
is dump_sexp('"ha\\ha\\ha"'), '"\\"ha\\\\ha\\\\ha\\""';
is dump_sexp([1, "yes", 2]), '(1 "yes" 2)';
is dump_sexp({b => 5, a => "yes"}), '(("a" . "yes") ("b" . 5))';

sub roundtrip_test {
	my ($sexp) = @_;
	my $ds = Data::SExpression->new({use_symbol_class => 1, fold_lists => 0});
	my $parsed = $ds->read($sexp);
	is dump_sexp($parsed), $sexp
}

roundtrip_test 'symbol';
roundtrip_test '(HA-HA 111 "text")';
roundtrip_test '(cons . cell)';
roundtrip_test '(1 2 3 . 4)';
