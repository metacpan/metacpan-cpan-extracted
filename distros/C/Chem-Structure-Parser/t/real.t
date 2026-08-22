#!/usr/bin/env perl
# Against real structures, when there are any to hand.
#
# The fixtures test the cases that were thought of.  This tests the ones that
# were not: a few thousand real entries carry every quirk thirty years of a
# format collects, and most of them are in files nobody would think to write
# by hand.
#
# Set STRUCTURE_INFO_TEST_DIR to a directory of .pdb/.ent files to run it
# somewhere else.  With nothing to read, the file skips rather than fails --
# the distribution has to build on a machine with no structures on it.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Cwd 'abs_path';
use File::Basename 'dirname';
use Chem::Structure::Parser;
use Test::More;

my @DIRS = grep { defined && -d } (
	$ENV{STRUCTURE_INFO_TEST_DIR},
	"$ENV{HOME}/ui/pepPriML/PPB/PDB/PDBbind.v2020",
	dirname(abs_path(__FILE__)) . '/real',
);
plan skip_all => 'no directory of real structures found; set STRUCTURE_INFO_TEST_DIR'
	unless @DIRS;

opendir(my $dh, $DIRS[0]) or plan skip_all => "cannot read $DIRS[0]: $!";
my @all = sort grep { /\.(pdb|ent)(\.gz)?\z/ } readdir $dh;
closedir $dh;
plan skip_all => "no structure files in $DIRS[0]" unless @all;

# a spread across the directory rather than the first N, which in a directory
# named by PDB id would be all the same vintage
my $want = $ENV{STRUCTURE_INFO_TEST_ALL} ? @all : 60;
my $step = @all > $want ? int(@all / $want) : 1;
my @files = map { "$DIRS[0]/$all[$_]" } grep { $_ % $step == 0 } 0 .. $#all;
@files = @files[0 .. $want - 1] if @files > $want;

diag(sprintf('reading %d of %d structures in %s', scalar @files, scalar @all, $DIRS[0]));

# --- an independent reader, for the things worth checking twice ------------
#
# The point of the XS is to slice fixed columns quickly.  This does the same
# slicing in the most obvious Perl there is, and the two are compared on every
# file: if the C ever reads a column wrong, the two will disagree.  It is
# deliberately naive -- no options, no filtering, model 1 only.
#
# It returns two things.  The residue list is every residue in the file as
# chain/number/insertion code/name, which tests the column reading and nothing
# else.  The protein sequences are built from amino acids alone, which tests
# the reading and the single-letter codes without going near the ambiguity
# over whether a lone GUA is a nucleotide or a free base.
#
# A residue is a chain, a number and an insertion code, which is how the
# module keys them, and the name is carried along rather than being part of
# the identity.  It cannot be part of it: one position is sometimes modelled
# in two chemical states at once, as complementary altloc groups, and both
# are the same residue.  3zeu has ten methionines each written as MSE in
# altlocs A and B and MET in C and D, a selenomethionine that only went
# halfway in; 2ftm has an aspartate at A115 that is IAS in altloc A and ASP
# in B, 5nai a CSD/CYS at A198, 5za2 a SEP/SER at B64 and 6e4z a NEP/HIP at
# H58.  Counting those twice would put a second M in the sequence of a
# protein that has one.  The name still has to agree, because it is in the
# string being compared -- only the counting is by position.
sub reference_read {
	my ($file) = @_;
	open my $fh, '<', $file or die "$file: $!";
	my (%res, %seq, %seen, $ended);
	while (my $l = <$fh>) {
		last if $ended;
		$ended = 1 if $l =~ /\AENDMDL/;
		next unless $l =~ /\A(?:ATOM  |HETATM)/;
		my $chain   = substr($l, 21, 1);
		my $resname = substr($l, 17, 3);
		my $num     = substr($l, 22, 4);
		my $icode   = substr($l, 26, 1);
		for ($chain, $resname, $num, $icode) { s/\A\s+//; s/\s+\z// }
		my $key = "$chain|$num|$icode";
		next if $seen{$key}++;
		push @{ $res{$chain} }, "$num|$icode|$resname";
		$seq{$chain} .= aa3to1($resname) if res_type($resname) eq 'amino_acid';
	}
	close $fh;
	return (\%res, \%seq);
}

my $checked = 0;
my $chains_with_seqres = 0;
my @over;
for my $file (@files) {
	my $name = (split m{/}, $file)[-1];
	my $info = eval { structure_info($file) };
	if (!$info) {
		fail("$name: $@");
		next;
	}
	$checked++;

	# --- the counts have to add up ---------------------------------------
	my $chain_atoms = 0;
	$chain_atoms += $info->{chains}{$_}{n_atoms} for @{ $info->{chain_order} };
	is($chain_atoms, $info->{stats}{n_atoms}, "$name: the chains account for every atom")
		or next;

	my $ok = 1;
	for my $cid (@{ $info->{chain_order} }) {
		my $c = $info->{chains}{$cid};
		my ($res_atoms, $polymer) = (0, 0);
		for my $rk (@{ $c->{residue_order} }) {
			my $r = $c->{residues}{$rk};
			$res_atoms += $r->{n_atoms};
			$polymer++ if $r->{type} eq 'amino_acid' || $r->{type} eq 'nucleotide';
			# every residue key is the number with its insertion code on the end
			$ok &&= $rk eq (defined $r->{number} ? $r->{number} : '') . $r->{icode};
		}
		$ok &&= $res_atoms == $c->{n_atoms};
		$ok &&= $polymer   == $c->{n_polymer};
		$ok &&= length($c->{sequence}) == $c->{n_polymer};
		$ok &&= $c->{sequence} =~ /\A[A-Z]*\z/;
		$ok &&= scalar(@{ $c->{residue_order} }) == scalar(keys %{ $c->{residues} });
	}
	ok($ok, "$name: residues, atoms and sequence lengths agree inside every chain");

	# --- against the naive reader ----------------------------------------
	my ($ref_res, $ref_seq) = reference_read($file);
	my $got_res = {};
	for my $cid (@{ $info->{chain_order} }) {
		my $c = $info->{chains}{$cid};
		$got_res->{$cid} = [ map {
			my $r = $c->{residues}{$_};
			"$r->{number}|$r->{icode}|$r->{resname}"
		} @{ $c->{residue_order} } ];
	}
	is_deeply($got_res, $ref_res,
		"$name: the XS reads the same residues, in the same order, as plain Perl substr does");

	# Amino acids by name, on both sides, so that this compares column reading
	# and single-letter codes and nothing else.  Whether a given residue ends
	# up in the chain's sequence is a question of classification -- a free
	# glycine in a binding site does not -- and that is structure.t's business,
	# not this comparison's.
	my $got_seq = {};
	for my $cid (@{ $info->{chain_order} }) {
		my $c = $info->{chains}{$cid};
		my $s = join '', map  { aa3to1($c->{residues}{$_}{resname}) }
		                 grep { res_type($c->{residues}{$_}{resname}) eq 'amino_acid' }
		                 @{ $c->{residue_order} };
		$got_seq->{$cid} = $s if length $s;
	}
	is_deeply($got_seq, { map { $_ => $ref_seq->{$_} } grep { length $ref_seq->{$_} } keys %$ref_seq },
		"$name: and the same amino acid sequence");

	# --- what the header said, where it said anything --------------------
	if (defined $info->{resolution}) {
		ok($info->{resolution} > 0 && $info->{resolution} < 100,
			"$name: resolution $info->{resolution} is a plausible number");
	}
	if (defined $info->{r_free}) {
		ok($info->{r_free} > 0 && $info->{r_free} < 1, "$name: R-free is a fraction");
	}
	# The observed sequence is normally no longer than SEQRES -- every residue
	# with coordinates ought to be one that was declared.  It is not a rule the
	# format enforces, though: 3lms has ATOM residues numbered 567, 1501, 1889
	# and 2356 in a chain whose SEQRES is 309 long.  So this is counted across
	# the corpus rather than asserted per file, which still catches the failure
	# that matters -- a classification bug that starts sweeping ligands or
	# waters into sequences would push the rate up at once.
	for my $cid (@{ $info->{chain_order} }) {
		my $c = $info->{chains}{$cid};
		next unless defined $c->{seqres} && length $c->{sequence};
		$chains_with_seqres++;
		if (length($c->{sequence}) > length($c->{seqres})) {
			push @over, sprintf('%s chain %s: %d observed vs %d in SEQRES',
				$name, $cid, length $c->{sequence}, length $c->{seqres});
		}
	}
}

diag("longer than SEQRES: $_") for @over;
ok(@over <= $chains_with_seqres / 20,
	sprintf('the observed sequence is no longer than SEQRES in all but a few chains (%d of %d)',
		scalar @over, $chains_with_seqres));

# --- the id in the file agrees with the name of the file -------------------
{
	my $named = 0;
	for my $file (@files[0 .. ($#files > 20 ? 20 : $#files)]) {
		my $name = (split m{/}, $file)[-1];
		my ($stem) = $name =~ /\A(?:pdb)?([0-9a-z]{4})[.]/i or next;
		my $info = structure_info($file);
		next unless defined $info->{header}{id_code} && length $info->{header}{id_code};
		$named++;
		is($info->{id}, uc $stem, "$name: the id in HEADER matches the file name");
	}
	ok($named > 0, 'at least one file had an id to check');
}

diag("checked $checked structures");
done_testing();
