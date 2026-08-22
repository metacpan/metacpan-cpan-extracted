#!/usr/bin/env perl
# The flat views over a parsed structure, and the summary.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Cwd 'abs_path';
use File::Basename 'dirname';
use Scalar::Util 'refaddr';
use Chem::Structure::Parser;
use Test::Exception;
use Test::More;

my $data = dirname(abs_path(__FILE__)) . '/data';
my $i = structure_info("$data/mini.pdb");

#--------
# structure_atoms -- the shape to hand to a distance calculation
#--------
{
	my $atoms = structure_atoms($i);
	is(ref $atoms, 'ARRAY', 'structure_atoms: an array reference');
	is(scalar @$atoms, 65,
		'one entry per distinct atom: the two conformers of one CB are one atom');
	is($atoms->[0]{name}, 'N', 'in file order');
	is($atoms->[0]{chain}, 'A', 'each atom carries its chain');
	is($atoms->[0]{resname}, 'MET', 'and its residue name');
	is($atoms->[0]{resseq}, 1, 'and its residue number');
	is($atoms->[0]{reskey}, '1', 'and the key it is filed under');
	ok(defined $atoms->[0]{x}, 'and its coordinates');

	my $a = structure_atoms($i, 'B');
	is(scalar @$a, 12, 'structure_atoms: one chain on request');
	is($a->[0]{chain}, 'B', 'and it is that chain');

	# the copies must not be the residue-s own atom hashes: writing to one of
	# these should not scribble on the structure
	$a->[0]{x} = 'scribbled';
	isnt($i->{chains}{B}{residues}{1}{atoms}{P}{x}, 'scribbled',
		'structure_atoms returns copies, not the hashes inside the structure');

	throws_ok { structure_atoms($i, 'Z') } qr/no chain 'Z'/, 'a chain that is not there dies';
}

#--------
# structure_residues -- the same residues that are in the nested structure,
# not copies, so that walking them and looking one up agree
#--------
{
	my $res = structure_residues($i);
	is(scalar @$res, 17, 'structure_residues: every residue in the file');
	is($res->[0]{resname}, 'MET', 'in file order');
	is(refaddr($res->[0]), refaddr($i->{chains}{A}{residues}{1}),
		'and they are the very residues in the structure, not copies of them');
	is(scalar @{ structure_residues($i, 'B') }, 4, 'one chain on request');
}

#--------
# structure_ligands
#--------
{
	my $lig = structure_ligands($i);
	is_deeply([ sort keys %$lig ], [ 'NAG_A_201', 'ZN_A_202' ],
		'structure_ligands: the heterogens that are not water, keyed by name, chain and number');
	is($lig->{NAG_A_201}{resname}, 'NAG', 'and the residue itself is the value');
	ok(!grep({ /HOH/ } keys %$lig), 'water is not a ligand');
}

#--------
# is_single_ion -- the chains a caller walking chain_order wants out of the way
# before it asks the rest for a sequence.  One residue in the chain is the whole
# of the question: not one atom, and not a residue name looked up in a table.
# mini.pdb numbers its zinc into chain A, which is the other half of the
# question, so the chains that are one heterogen are written here.
#--------
{
	my $one = sub {
		my ($record, $chain, $resname, $resseq, @names) = @_;
		my $out = '';
		my $serial = 0;
		for my $n (@names) {
			$serial++;
			my $name = length($n) == 4 ? $n : sprintf(' %-3s', $n);
			my ($el) = $n =~ /([A-Z])/;
			$out .= sprintf("%-6s%5d %-4s %3s %1s%4d    %8.3f%8.3f%8.3f%6.2f%6.2f          %2s\n",
				$record, $serial, $name, $resname, $chain, $resseq,
				$serial, $serial + 1, $serial + 2, 1, 20, $el);
		}
		return $out;
	};
	my $s = structure_info_string(
		$one->('ATOM  ', 'A', 'MET', 1, qw(N CA C O))                 .  # a polymer
		$one->('ATOM  ', 'A', 'ALA', 2, qw(N CA C O))                 .
		$one->('ATOM  ', 'A', 'GLY', 3, qw(N CA C O))                 .
		$one->('HETATM', 'E', 'ZN', 101, 'ZN')                        .  # one ion
		$one->('HETATM', 'F', 'SO4', 201, qw(S O1 O2 O3 O4))          .  # one polyatomic ion
		$one->('HETATM', 'B', 'BF4', 202, qw(B F1 F2 F3 F4))          .  # one the ION table misses
		$one->('HETATM', 'G', 'MG', 301, 'MG')                        .  # an ion and its water
		$one->('HETATM', 'G', 'HOH', 302, 'O')                        .
		$one->('HETATM', 'W', 'HOH', 401, 'O')                        .  # water alone
		$one->('HETATM', 'L', 'NAG', 501, qw(C1 C2 O5 N2))            .  # a ligand
		$one->('HETATM', 'H', 'ZN', 601, 'ZN')                        .  # two ions
		$one->('HETATM', 'H', 'ZN', 602, 'ZN')
	);
	ok(is_single_ion($s->{chains}{E}), 'is_single_ion: a chain that is one zinc');
	ok(is_single_ion($s, 'E'), 'and the same asked with the structure and a chain id');
	ok(is_single_ion($s->{chains}{F}),
		'a lone sulphate: residues in the chain are counted, not atoms in the residue');
	ok(is_single_ion($s->{chains}{B}),
		'and a lone BF4, which the ION table does not list: no name is looked up');
	is($s->{chains}{F}{residues}{201}{type}, 'ion',   'the sulphate types as an ion');
	is($s->{chains}{B}{residues}{202}{type}, 'ligand', 'the BF4 does not, and answers the same anyway');
	ok(!is_single_ion($s->{chains}{A}), 'a chain with a polymer in it is not one residue');
	ok(!is_single_ion($s->{chains}{G}), 'an ion with a water beside it is two residues');
	ok(!is_single_ion($s->{chains}{H}), 'and two zincs are two residues');

	# the residue is not asked what it is, so these read true as well
	ok(is_single_ion($s->{chains}{W}), 'a chain of one water reads true: single counts residues');
	ok(is_single_ion($s->{chains}{L}), 'so does a chain of one sugar');
	is($s->{chains}{W}{residues}{401}{type}, 'water',
		'and the residue says which it is, for a caller who needs the difference');

	is(is_single_ion($s, 'A'), '', 'false is the empty string, true is 1');
	is(is_single_ion($s, 'E'), 1, 'false is the empty string, true is 1');

	is_deeply([ grep { !is_single_ion($s, $_) } @{ $s->{chain_order} } ],
		[ qw(A G H) ], 'which is what putting the one-residue chains aside looks like');

	# the ion chains of mini.pdb are numbered into chain A, so it has none
	ok(!grep({ is_single_ion($i, $_) } @{ $i->{chain_order} }),
		'an ion numbered into a polymer chain does not make that chain a single ion');

	# all three hashes in a parsed structure are hash references, so a wrong
	# one is said to be wrong rather than answered false
	throws_ok { is_single_ion($s) } qr/that is the whole structure/,
		'is_single_ion: the structure without a chain id dies';
	throws_ok { is_single_ion($s->{chains}{A}{residues}{1}) } qr/that is a residue/,
		'is_single_ion: a residue dies';
	throws_ok { is_single_ion($s, 'Z') } qr/no chain 'Z'/, 'is_single_ion: unknown chain dies';
	throws_ok { is_single_ion($s, undef) } qr/no chain given/, 'is_single_ion: an undefined chain id dies';
	throws_ok { is_single_ion('A') } qr/expected the chain hash reference/, 'is_single_ion: a string dies';
	throws_ok { is_single_ion([]) } qr/expected the chain hash reference/, 'is_single_ion: an arrayref dies';
	throws_ok { is_single_ion(undef) } qr/expected the chain hash reference/, 'is_single_ion: undef dies';
	throws_ok { is_single_ion({ not => 'a chain' }) } qr/expected the chain hash reference/,
		'is_single_ion: a hash that is not a chain dies';

	# a chain out of a model set is a chain
	my $nmr = structure_info("$data/nmr.pdb", model => 'all');
	my ($m) = sort keys %{ $nmr->{models} };
	ok(!is_single_ion($nmr->{models}{$m}{chains}{ $nmr->{models}{$m}{chain_order}[0] }),
		'is_single_ion: a chain from $info->{models} is a chain like any other');
}

#--------
# sequences
#--------
{
	is_deeply(structure_sequences($i), { A => 'MAGCMHHSC', B => 'ACGT' }, 'structure_sequences');
	throws_ok { chain_sequence($i, 'Z') } qr/no chain 'Z'/, 'chain_sequence: unknown chain dies';
	throws_ok { chain_sequence($i) } qr/no chain given/, 'chain_sequence: no chain dies';
	throws_ok { chain_sequence($i, 'A', 'guessed') } qr/observed.*seqres/,
		'chain_sequence: an unknown kind of sequence dies';
}

#--------
# structure_summary
#--------
{
	my $s = structure_summary($i);
	like($s, qr/9XYZ/, 'summary: the id');
	like($s, qr/A SMALL TEST STRUCTURE/, 'summary: the title');
	like($s, qr/resolution\s+1\.85/, 'summary: the resolution');
	like($s, qr/chain A\s+protein/, 'summary: a line per chain');
	like($s, qr/MAGCMHHSC/, 'summary: the sequence');
	like($s, qr/1 gap\b/, 'summary: gaps, singular');
	like($s, qr/NAG_A_201/, 'summary: the ligands');
	is(substr($s, -1), "\n", 'summary: ends with a newline');
}

#--------
# the views all insist on a real structure
#--------
for my $f (qw(structure_atoms structure_residues structure_ligands structure_sequences structure_summary)) {
	no strict 'refs';
	# structure_sequences also takes a file name, so its complaint about being
	# handed nothing says so; every one of them still refuses a hash that is
	# not a structure.
	my $nothing = $f eq 'structure_sequences'
		? qr/expected a file name or the hash reference/
		: qr/expected the hash reference/;
	throws_ok { $f->({ not => 'a structure' }) } qr/expected the hash reference/,
		"$f: a hash that is not a structure dies";
	throws_ok { $f->(undef) } $nothing, "$f: undef dies";
	throws_ok { $f->([]) } qr/expected the hash reference/, "$f: an arrayref dies";
	throws_ok { $f->('') } $nothing, "$f: the empty string dies";
}

#--------
# h() -- the documentation, by name, by glob and by reference.
#
# h() prints to STDOUT by name rather than to the selected handle, on purpose:
# help that goes wherever output happens to have been redirected is help you
# cannot find.  So the capture has to replace the handle itself.
#--------
sub capture_h {
	my @args = @_;
	my ($out, $ret) = ('');
	{
		local *STDOUT;
		open STDOUT, '>', \$out or die $!;
		$ret = h(@args);
		close STDOUT;
	}
	return ($ret, $out);
}

{
	my ($got, $out) = capture_h('structure_info');
	is($got, 'structure_info', 'h: returns the name it showed');
	like($out, qr/structure_info/, 'h: prints that function-s documentation');
	like($out, qr/altloc/, 'h: including its options');
	unlike($out, qr/=head/, 'h: without the POD markup around it');
}
for my $arg ('res_type', \&Chem::Structure::Parser::res_type, *Chem::Structure::Parser::res_type) {
	my ($got, $out) = capture_h($arg);
	like($out, qr/nucleotide/, 'h: takes a name, a reference or a glob');
}
{
	# a fully qualified name, which is what a glob stringifies to
	my ($got, $out) = capture_h('Chem::Structure::Parser::aa3to1');
	is($got, 'aa3to1', 'h: a package-qualified name is accepted');
}
{
	my ($got, $out) = capture_h();
	is($got, undef, 'h: with no argument returns undef');
	like($out, qr/Documented functions/, 'and lists what is documented');
	like($out, qr/\bres1\b/, 'including the small ones');
}
{
	my ($got, $out) = capture_h('no_such_function');
	is($got, undef, 'h: an undocumented name returns undef');
	like($out, qr/Documented functions/, 'and lists the documented ones instead of dying');
}

done_testing();
