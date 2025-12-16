#! /usr/bin/env perl

use strict;

use Chess::Plisco;

sub getLine;
sub processPosition;
sub getNode;
sub printDot;

my ($filename, $depth) = @ARGV;

if (!defined $depth || $depth !~ /^[1-9][0-9]*$/) {
	die "Usage: $0 LOGFILE DEPTH\n";
}

open my $fh, '<', $filename or die "$filename: $!";

my $line = $fh->getline;
if ($line !~ /^DEBUG Searching (.*)\n/) {
	die "$filename: not a debug log\n";
}
my $fen = $1;

# Scan to depth.
my $found;
while (my $line = $fh->getline) {
	if ($line eq "DEBUG Deepening to depth $depth\n") {
		$found = 1;
		last;
	}
}

die "no output for depth $depth found" if !$found;

my @ab;
my @value;

my $pos = Chess::Plisco->new($fen);
my $tree = {
	moves => [],
	subnodes => {},
};

my $value = processPosition $pos, $tree;

if (!defined $value) {
	die "search not terminated";
}

$tree->{value} = -$value;

#use Data::Dumper;
#warn Dumper $tree;

print <<"EOF";
Digraph AlphaBetaTree {
	node[shape=circle, fontsize=8]
	n[]
EOF

printDot $tree, $pos;

print <<"EOF";

	n[label="root v=$value\\nα=-∞ β=+∞"];
}
EOF

sub processPosition {
	my ($pos, $tree) = @_;

	my @moves;

	while (my %line = getLine) {
		if ($line{type} eq 'finished') {
			return $line{value};
		} elsif ($line{type} eq 'start') {
			my $move = $line{move};
			push @moves, $move;
		} elsif ($line{type} eq 'value') {
			my $node = getNode(\@moves, $tree);
			$node->{value} = -$line{value};
			pop @moves;
		} elsif ($line{type} eq 'alphabeta') {
			my $node = getNode(\@moves, $tree);
			$node->{alpha} = $line{alpha};
			$node->{beta} = $line{beta};
		} elsif ($line{type} eq 'cutoff') {
			my $node = getNode(\@moves, $tree);
			$node->{cutoff} = 1;
		}
	}
}

sub getLine {
	my $line = $fh->getline or die "premature end-of-file";

	chomp $line;
	my $original = $line;
	die "unrecognised line: $line" if $line !~ s/^DEBUG //;

	if ($line =~ /^Score at depth $depth: (-?[0-9]+)$/) {
		return type => 'finished', value => $1 ;
	}

	#if (!($line =~ s{^\[([0-9]+)/([0-9]+)\] }{})) {
	if (!($line =~ s{^\[([0-9]+)/([0-9]+)\] }{}m)) { # The m is only here to make VS Code happy.
		die "unrecognised line: $line";
	}

	$line =~ s/\.+//;

	my %retval = (
		ply => $1,
		seldepth => $2,
		type => 'unknown',
		original => $original,
	);

	if ($line =~ /^move ([a-h][1-8][a-h][1-8][qrbn]?): start search$/) {
		return %retval, type => 'start', move => $1;
	} elsif ($line =~ /^move ([a-h][1-8][a-h][1-8][qrbn]?): value (-?[0-9]+)$/) {
		return %retval, type => 'value', move => $1, value => $2;
	} elsif ($line =~ /^alphabeta: alpha = (-?[0-9]+), beta = (-?[0-9]+),/) {
		return %retval, type => 'alphabeta', alpha => $1, beta => $2;
	} elsif ($line =~ /^[a-h][1-8][a-h][1-8][qrbn]? fail high/) {
		return %retval, type => 'cutoff';
	}

	return %retval, unrecognised => $line;
}

sub getNode {
	my ($moves, $tree) = @_;

	my $node = $tree;

	foreach my $move (@$moves) {
		if (!$node->{subnodes}->{$move}) {
			push @{$node->{moves}}, $move;
			$node->{subnodes}->{$move} //= {
				moves => [],
				subnodes => {},
			};
		}
		$node = $node->{subnodes}->{$move};
	}

	return $node;
}

sub printDot {
	my ($tree, $pos, @path) = @_;

	my $parent_suffix = join '_', @path;

	my $i = 0;
	foreach my $move (@{$tree->{moves}}) {
		++$i;
		my $suffix = join '_', @path, $i;
		eval {
			$pos->parseMove($move);
		};
		if ($@) {
			$DB::single = 1;
		}
		my $san = $pos->SAN($pos->parseMove($move));
		my $subtree = $tree->{subnodes}->{$move};

		my $value_op = $subtree->{cutoff} ? '≥' : '=';
		my $alpha = $subtree->{alpha};
		my $beta = $subtree->{beta};
		$alpha =~ s/16383/∞/;
		$beta =~ s/16383/∞/;

		my $undo = $pos->applyMove($move);

		my $cutoff = '';
		if ($subtree->{cutoff}) {
			my @legal_moves = $pos->legalMoves;
			my $num_moves = @legal_moves - @{$subtree->{moves}};
			if ($num_moves > 0) {
				$cutoff = "\\n$num_moves moves\\ncut off";
			}
		}

		print qq{\tn${suffix}[label="v${value_op}$subtree->{value}\\nα=${alpha} β=${beta}$cutoff"];\n};
		print qq{\tn$parent_suffix -> n${suffix}[label="$san"];\n};

		printDot $subtree, $pos, @path, $i;

		$pos->unapplyMove($undo);
	}
}