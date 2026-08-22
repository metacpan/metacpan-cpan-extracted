#!/usr/bin/env perl
require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN { use_ok('Chem::Structure::Parser') or BAIL_OUT('Chem::Structure::Parser will not load') }

ok(defined $Chem::Structure::Parser::VERSION, "VERSION is set ($Chem::Structure::Parser::VERSION)");

# the XS half has to be there: without it every other test is testing nothing
ok(defined &Chem::Structure::Parser::_parse_file,       'XS _parse_file is bootstrapped');
ok(defined &Chem::Structure::Parser::_parse_string,     'XS _parse_string is bootstrapped');
ok(defined &Chem::Structure::Parser::_parse_cif_file,   'XS _parse_cif_file is bootstrapped');
ok(defined &Chem::Structure::Parser::_parse_cif_string, 'XS _parse_cif_string is bootstrapped');

for my $f (qw(
	structure_info structure_info_string pdb_info cif_info
	structure_atoms structure_residues structure_ligands structure_sequences
	chain_sequence structure_summary is_single_ion aa3to1 aa1to3 res1 res_type formats h
)) {
	can_ok('Chem::Structure::Parser', $f);
	ok(defined &{"main::$f"}, "$f is exported into the caller");
}

is_deeply([ formats() ], [ 'mmcif', 'pdb' ], 'formats() lists what can be read');
my $all = formats();
is(ref $all, 'HASH', 'formats() in scalar context is a hashref');
is($all->{pdb},   'supported', 'formats() says PDB is read');
is($all->{mmcif}, 'supported', 'formats() says mmCIF is read');
like($all->{mol2}, qr/not implemented/, 'formats() names the formats not written yet');

done_testing();
