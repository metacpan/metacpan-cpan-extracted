#!/usr/bin/env perl
# mmCIF against real structures.
#
# t/cif.t proves the reader on fixtures, which test the cases that were
# thought of.  This tests the ones that were not, in the two ways there are to
# get real files in front of it:
#
#   1. A directory of real .cif files, read straight.  Nothing to compare them
#      against, so what is checked is that they parse and that the structure
#      that comes back adds up -- the chains account for every atom, the
#      residues account for every chain atom, the sequence is as long as the
#      polymer.  Any .pdb sitting beside a .cif is compared against it.
#
#   2. The PDB corpus t/real.t reads, converted to mmCIF a file at a time and
#      read back.  This is the one that finds things: those files carry every
#      quirk thirty years of a format collects -- altlocs, insertion codes,
#      residues numbered backwards, chains named '1', hydrogens with four
#      character names -- and each of them has to survive the trip through the
#      other format unchanged.  The conversion is a straight column read, so a
#      disagreement is the reader's and not the converting.
#
# Both halves skip rather than fail when there is nothing to read: the
# distribution has to build on a machine with no structures on it.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Cwd 'abs_path';
use File::Basename 'dirname';
use Chem::Structure::Parser;
use Test::More;

my $here = dirname(abs_path(__FILE__));

# canon_charges() -- both readers' charges in one spelling, in place.
#
# The two formats write a formal charge differently and each reader reports
# what its own format wrote: a PDB file saying "1-" reads back as '1-', and the
# mmCIF rendering of that same charge, -1, reads back as '1-' too.  That is the
# conversion working.  But the archive holds PDB files that write the mmCIF
# spelling in the PDB column -- 4byf has "-1" in columns 79-80 -- and there the
# PDB reader passes through what it found while the mmCIF reader normalises, so
# the same charge comes back spelled two ways.
#
# Both are right.  So the comparison asks whether it is the same charge rather
# than whether it is the same string, and a wrong charge -- 1- against 2-, or
# 1- against 1+ -- still fails.  In place because $info is dropped straight
# after, and copying every atom to rewrite one field of it would cost more than
# the comparison.
sub canon_charges {
	my ($i) = @_;
	for my $cid (@{ $i->{chain_order} }) {
		my $c = $i->{chains}{$cid};
		for my $rk (@{ $c->{residue_order} }) {
			my $r = $c->{residues}{$rk};
			for my $an (@{ $r->{atom_order} }) {
				my $a = $r->{atoms}{$an};
				my $q = $a->{charge};
				next unless defined $q && length $q;
				# sign and magnitude, whichever order the field put them in.
				# Zero has no sign: 4iu3 writes "0-" in columns 79-80, and a
				# charge of minus nothing is a charge of nothing.
				my ($sign, $mag) =
					  $q =~ /\A(\d)([-+])\z/ ? ($2, $1)
					: $q =~ /\A([-+])(\d)\z/ ? ($1, $2)
					: $q =~ /\A(\d)\z/       ? ('+', $1)
					:                          (undef, undef);
				next unless defined $mag;              # not a charge; leave it be
				$a->{charge} = $mag == 0 ? '0' : "$sign$mag";
			}
		}
	}
	return $i;
}

# the coordinate half, which is what has to survive the change of format
sub coords {
	my ($i) = @_;
	canon_charges($i);
	my %s = %{ $i->{stats} };
	delete $s{n_lines};    # an mmCIF row and a PDB record are not the same line
	my %c;
	for my $cid (keys %{ $i->{chains} }) {
		my %x = %{ $i->{chains}{$cid} };
		# what _chain_stats() folded in from the header, which the conversion
		# below does not carry across and which t/cif.t tests on its own
		delete @x{qw(seqres seqres_length n_missing mol_id molecule organism
		             fragment ec dbref)};
		$c{$cid} = \%x;
	}
	return { chains => \%c, chain_order => $i->{chain_order}, stats => \%s };
}

# --- consistency, for a structure with nothing to compare it against -------
sub adds_up {
	my ($info, $name) = @_;
	my $atoms = 0;
	$atoms += $info->{chains}{$_}{n_atoms} for @{ $info->{chain_order} };
	return "the chains hold $atoms atoms but the file had $info->{stats}{n_atoms}"
		if $atoms != $info->{stats}{n_atoms};
	for my $cid (@{ $info->{chain_order} }) {
		my $c = $info->{chains}{$cid};
		my ($n, $poly) = (0, 0);
		for my $rk (@{ $c->{residue_order} }) {
			my $r = $c->{residues}{$rk};
			$n += $r->{n_atoms};
			$poly++ if $r->{type} eq 'amino_acid' || $r->{type} eq 'nucleotide';
			return "chain $cid residue $rk has no atoms" unless $r->{n_atoms};
			return "chain $cid residue $rk is keyed wrong" unless $r->{key} eq $rk;
		}
		return "chain $cid: residues hold $n atoms, the chain says $c->{n_atoms}"
			if $n != $c->{n_atoms};
		return "chain $cid: $poly polymer residues but a sequence of "
		       . length($c->{sequence})
			if length($c->{sequence}) != $poly;
		return "chain $cid: $c->{n_residues} residues but "
		       . scalar(@{ $c->{residue_order} }) . ' in the order'
			if $c->{n_residues} != @{ $c->{residue_order} };
	}

	# and the header, for the files that have one.  The .cif files a
	# simulation writes carry no header at all, so this says nothing about
	# them; point STRUCTURE_INFO_TEST_CIF_DIR at a directory of archive
	# entries and it is the half of the reader that gets exercised.
	for my $k (qw(resolution r_work r_free temperature ph)) {
		next unless defined $info->{$k};
		return "$k is '$info->{$k}', which is not a number"
			unless $info->{$k} =~ /\A-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?\z/;
	}
	for my $k (qw(keywords experiment authors helix sheet ssbond link cispep)) {
		return "$k is not an array reference" unless ref $info->{$k} eq 'ARRAY';
	}
	for my $k (qw(header seqres het remarks modres dbref cryst1 journal)) {
		return "$k is not a hash reference" unless ref $info->{$k} eq 'HASH';
	}
	for my $cid (keys %{ $info->{seqres} }) {
		my $s = $info->{seqres}{$cid};
		return "seqres $cid has no sequence" unless defined $s->{sequence};
		return "seqres $cid: length $s->{length} but a sequence of "
		       . length($s->{sequence})
			if defined $s->{length} && @{ $s->{residues} }
			&& $s->{length} != length $s->{sequence};
	}
	return undef;
}

#---------------------------------------------------------------------------
# 1. real .cif files
#---------------------------------------------------------------------------
{
	my @dirs = grep { defined && -d } (
		$ENV{STRUCTURE_INFO_TEST_CIF_DIR},
		"$ENV{HOME}/ui/pep-priml/metad/systems",
		"$here/real",
	);
	my @files;
	for my $d (@dirs) {
		next if @files;
		opendir(my $dh, $d) or next;
		my @e = sort grep { !/\A\./ } readdir $dh;
		closedir $dh;
		# a flat directory of .cif files, or one directory per structure
		push @files, map { "$d/$_" } grep { /\.(cif|mmcif|pdbx)(\.gz)?\z/ } @e;
		next if @files;
		for my $sub (grep { -d "$d/$_" } @e) {
			opendir(my $sh, "$d/$sub") or next;
			push @files, map { "$d/$sub/$_" }
			             sort grep { /\.(cif|mmcif|pdbx)(\.gz)?\z/ } readdir $sh;
			closedir $sh;
		}
	}

	SKIP: {
		skip 'no directory of real mmCIF structures found; '
		     . 'set STRUCTURE_INFO_TEST_CIF_DIR', 1 unless @files;
		my $want = $ENV{STRUCTURE_INFO_TEST_ALL} ? scalar @files : 80;
		@files = @files[0 .. $want - 1] if @files > $want;
		diag(sprintf('reading %d real mmCIF structures', scalar @files));

		my ($read, $paired, @bad, @differ, @note) = (0, 0);
		for my $f (@files) {
			my $name = join '/', (split m{/}, $f)[-2, -1];
			my $info = eval { structure_info($f) };
			if (!$info) { push @bad, "$name: $@"; next }
			if (my $why = adds_up($info, $name)) { push @bad, "$name: $why"; next }
			unless ($info->{stats}{n_atoms} && @{ $info->{chain_order} }) {
				push @bad, "$name: parsed to nothing";
				next;
			}
			$read++;

			my $twin = twin($f) or next;
			my $pdb  = eval { structure_info($twin) } or next;
			$paired++;

			# What is asserted of a pair is what cannot legitimately differ
			# between two files of the same structure: how many atoms there
			# are, and what the sequences are.  Both are read straight off the
			# coordinates by the same code for either format, so a difference
			# in one of them is the reader's doing.
			my $seq = sub {
				my ($i) = @_;
				return join '|', sort values %{ structure_sequences($i) };
			};
			push @differ, "$name: $pdb->{stats}{n_atoms} atoms in the .pdb, "
			              . "$info->{stats}{n_atoms} in the .cif"
				if $pdb->{stats}{n_atoms} != $info->{stats}{n_atoms};
			push @differ, "$name: the sequences differ"
				if $seq->($pdb) ne $seq->($info);

			# How those atoms are divided into chains can differ without either
			# reader being wrong, because the two files can disagree: 5jjm.pdb
			# and 6nsx.pdb put their ions in chain A on the HETATM record and
			# in chains C and D on the TER record that follows it, and the .cif
			# says C and D throughout.  Each reader reports what its own file
			# says, so this is worth seeing and is not a failure.
			push @note, "$name: chains @{ $pdb->{chain_order} } in the .pdb, "
			            . "@{ $info->{chain_order} } in the .cif"
				if "@{ $info->{chain_order} }" ne "@{ $pdb->{chain_order} }";
		}
		is(scalar @bad, 0, "all $read real mmCIF structures read and add up");
		diag("  $_") for @bad[0 .. ($#bad < 9 ? $#bad : 9)];
		if ($paired) {
			diag("$paired of them had the same structure as a .pdb beside them");
			is(scalar @differ, 0, 'and each of those agrees with it');
			diag("  $_") for @differ;
			diag('the two files disagree about the chains here, and each '
			     . 'reader reports what its own file says:') if @note;
			diag("  $_") for @note;
		}
	}
}

# twin() -- the .pdb of the same structure as this .cif, or nothing.
#
# Only two namings count as the same structure, and both have to be exact: the
# same stem in the same directory, or -- the layout of a directory per
# structure -- a prepared 'fixed.cif' beside the entry it was prepared from.
# Nothing else is guessed at, because a directory of one structure holds
# several files that are not it: 1cka/solvated.cif is 1cka in a box of water,
# 38088 atoms against 674, and pairing those two would report the water as a
# disagreement between the readers.
sub twin {
	my ($cif) = @_;
	my ($stem) = $cif =~ /\A(.*)\.(?:cif|mmcif|pdbx)\z/ or return undef;
	return "$stem.pdb" if -f "$stem.pdb";
	my ($dir, $id, $base) = $cif =~ m{\A(.*)/([^/]+)/([^/]+)\z} or return undef;
	return "$dir/$id/$id.pdb" if $base eq 'fixed.cif' && -f "$dir/$id/$id.pdb";
	return undef;
}

#---------------------------------------------------------------------------
# 2. the PDB corpus, through mmCIF and back
#---------------------------------------------------------------------------

# to_cif() -- a PDB file as mmCIF text.  A straight column read, because the
# point is to change nothing but the way it is written down: the coordinates
# go across as the characters they already are, so the two parses have to
# agree to the last digit and not merely to within a rounding.
sub cifq {
	my ($v) = @_;
	return '?' unless defined $v && length $v;
	return $v unless $v =~ /[\s'"]/ || $v =~ /\A[_\#\$\[\]]/
	              || $v =~ /\A(?:data|loop|save|stop|global)_/i;
	return "'$v'" if $v !~ /'/;
	return "\"$v\"" if $v !~ /"/;
	return "\n;$v\n;";
}

sub to_cif {
	my ($file) = @_;
	open my $fh, '<', $file or die "$file: $!";
	my @rows;
	my $model = 1;
	my $aniso = 0;
	while (my $l = <$fh>) {
		$l =~ s/\r?\n\z//;
		if ($l =~ /\AMODEL\s+(\d+)/)  { $model = $1; next }
		if ($l =~ /\AANISOU/)         { $aniso++;   next }
		next unless $l =~ /\A(ATOM  |HETATM)/;
		my $group = $1 eq 'ATOM  ' ? 'ATOM' : 'HETATM';
		my $f = sub {
			my ($from, $len) = @_;
			return '' if $from >= length $l;
			my $s = substr($l, $from, $len);
			$s =~ s/\A\s+//; $s =~ s/\s+\z//;
			return $s;
		};
		# the chain is column 22, falling back to 21, which is the rule the
		# reader follows for the two-character chain ids of a large assembly
		my $chain = $f->(21, 1);
		$chain = $f->(20, 1) unless length $chain;
		# A PDB charge is a magnitude then its sign, "2+", and an mmCIF one is
		# a signed integer, 2.  The archive holds all four spellings of that --
		# 4byf and 4ui0 write "-1" with the sign first, 6cc9 writes a bare "0"
		# -- so all four are read here.  Anything else is passed through as it
		# stands, which is what the reader does with a field it cannot make an
		# integer of, so a nonsense charge survives the trip as itself: 4iu3
		# writes "0-", and that is the file's problem and not the reader's.
		my $chg = $f->(78, 2);
		$chg = !length $chg              ? undef
		     : $chg =~ /\A(\d)([-+])\z/  ? ($2 eq '-' ? "-$1" : $1)
		     : $chg =~ /\A([-+])(\d)\z/  ? ($1 eq '-' ? "-$2" : $2)
		     : $chg =~ /\A\d\z/          ? $chg
		     :                             $chg;
		push @rows, [
			$group, $f->(6, 5), $f->(76, 2), $f->(12, 4), $f->(16, 1),
			$f->(17, 3), $chain, $f->(22, 4), $f->(26, 1),
			$f->(30, 8), $f->(38, 8), $f->(46, 8), $f->(54, 6), $f->(60, 6),
			$chg, $model,
		];
	}
	close $fh;
	my @out = ('data_converted', '#', 'loop_',
		map { "_atom_site.$_" } qw(
			group_PDB id type_symbol auth_atom_id label_alt_id auth_comp_id
			auth_asym_id auth_seq_id pdbx_PDB_ins_code
			Cartn_x Cartn_y Cartn_z occupancy B_iso_or_equiv
			pdbx_formal_charge pdbx_PDB_model_num));
	push @out, join ' ', map { cifq($_) } @$_ for @rows;
	if ($aniso) {
		# ANISOU has no bearing on the structure and is counted rather than
		# kept, so a row with nothing but an id in it is enough to count
		push @out, '#', 'loop_', '_atom_site_anisotrop.id';
		push @out, $_ for 1 .. $aniso;
	}
	push @out, '#';
	return join('', map { "$_\n" } @out);
}

{
	my @dirs = grep { defined && -d } (
		$ENV{STRUCTURE_INFO_TEST_DIR},
		"$ENV{HOME}/ui/pepPriML/PPB/PDB/PDBbind.v2020",
		"$here/real",
	);
	my @all;
	if (@dirs && opendir(my $dh, $dirs[0])) {
		@all = sort grep { /\.(pdb|ent)\z/ } readdir $dh;   # not .gz: to_cif reads plain
		closedir $dh;
	}

	SKIP: {
		skip 'no directory of real PDB structures found; set STRUCTURE_INFO_TEST_DIR', 1
			unless @all;
		# a spread across the directory rather than the first N, which in a
		# directory named by PDB id would be all the same vintage
		my $want = $ENV{STRUCTURE_INFO_TEST_ALL} ? scalar @all : 40;
		my $step = @all > $want ? int(@all / $want) : 1;
		my @files = map { "$dirs[0]/$all[$_]" } grep { $_ % $step == 0 } 0 .. $#all;
		@files = @files[0 .. $want - 1] if @files > $want;
		diag(sprintf('converting %d of %d real structures to mmCIF and back',
			scalar @files, scalar @all));

		my ($checked, @bad) = (0);
		for my $file (@files) {
			my $name = (split m{/}, $file)[-1];
			my $pdb = eval { structure_info($file) };
			unless ($pdb) { push @bad, "$name: reading it as PDB: $@"; next }
			next unless $pdb->{stats}{n_atoms};

			my $cif = eval { structure_info_string(to_cif($file)) };
			unless ($cif) { push @bad, "$name: reading it as mmCIF: $@"; next }
			is($cif->{format}, 'mmcif', "$name: the converted text reads as mmCIF")
				if $checked == 0;

			my ($x, $y) = (coords($pdb), coords($cif));
			if (!eq_deeply_ish($x, $y, \my $where)) {
				push @bad, "$name: $where";
				next;
			}
			$checked++;
		}
		is(scalar @bad, 0,
			"$checked real structures survive the trip through mmCIF unchanged");
		diag("  $_") for @bad[0 .. ($#bad < 9 ? $#bad : 9)];
	}
}

# is_deeply's message is not useful when the difference is one atom in four
# hundred thousand, so this finds the path itself
sub eq_deeply_ish {
	my ($x, $y, $where, $path) = @_;
	$path = '' unless defined $path;
	if (ref $x ne ref $y) { $$where = "$path: " . (ref($x) || 'value') . " became " . (ref($y) || 'value'); return 0 }
	if (ref $x eq 'HASH') {
		my %k = map { $_ => 1 } (keys %$x, keys %$y);
		for my $k (sort keys %k) {
			if (!exists $x->{$k}) { $$where = "$path.$k appeared"; return 0 }
			if (!exists $y->{$k}) { $$where = "$path.$k vanished"; return 0 }
			return 0 unless eq_deeply_ish($x->{$k}, $y->{$k}, $where, "$path.$k");
		}
		return 1;
	}
	if (ref $x eq 'ARRAY') {
		if (@$x != @$y) { $$where = sprintf('%s: %d elements became %d', $path, scalar @$x, scalar @$y); return 0 }
		for my $i (0 .. $#$x) {
			return 0 unless eq_deeply_ish($x->[$i], $y->[$i], $where, "$path\[$i]");
		}
		return 1;
	}
	my $xs = defined $x ? "$x" : '(undef)';
	my $ys = defined $y ? "$y" : '(undef)';
	return 1 if $xs eq $ys;
	$$where = "$path: '$xs' became '$ys'";
	return 0;
}

done_testing();
