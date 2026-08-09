#!/usr/bin/env perl

# Rebuilds the CSV fixtures in this directory from their upstream UCI
# sources.  Run it from the distribution root:
#
#     perl t/data/regenerate.pl
#
# Needs network access; nothing in the test suite does.  The fixtures are
# checked in, so this only has to run when a dataset is added or upstream
# changes.  It prints the SHA-256 of every file it downloads, which is
# what the "upstream sha256" lines in README are.
#
# See README in this directory for provenance, citations and licensing.

use strict;
use warnings;
use File::Basename qw(dirname);
use File::Spec     ();

my $HERE = dirname(__FILE__);
my $BASE = 'https://archive.ics.uci.edu/ml/machine-learning-databases';

# name => {
#   url      :: where the upstream file comes from
#   sep      :: field separator in the upstream file
#   skip     :: leading columns to drop (ID columns and the like)
#   take     :: how many feature columns follow $skip
#   label    :: coderef given the raw upstream fields, returning 1 for the
#               class treated as the anomaly and 0 otherwise
#   columns  :: the header written to the CSV
# }
my @WDBC_BASE = qw(
	radius texture perimeter area smoothness
	compactness concavity concave_points symmetry fractal_dimension
);
my @WDBC = map {
	my $suffix = $_;
	map { $_ . '_' . $suffix } @WDBC_BASE
} qw(mean se worst);

my %SET = (
	ionosphere => {
		url     => "$BASE/ionosphere/ionosphere.data",
		sep     => qr/,/,
		skip    => 0,
		take    => 34,
		label   => sub { $_[0][34] eq 'b' ? 1 : 0 },
		columns => [ map { "a$_" } 1 .. 34 ],
	},
	wdbc => {
		url     => "$BASE/breast-cancer-wisconsin/wdbc.data",
		sep     => qr/,/,
		skip    => 2,
		take    => 30,
		label   => sub { $_[0][1] eq 'M' ? 1 : 0 },
		columns => \@WDBC,
	},
	glass => {
		url     => "$BASE/glass/glass.data",
		sep     => qr/,/,
		skip    => 1,
		take    => 9,
		label   => sub { $_[0][10] == 6 ? 1 : 0 },
		columns => [qw(RI Na Mg Al Si K Ca Ba Fe)],
	},
	seeds => {
		url     => "$BASE/00236/seeds_dataset.txt",
		sep     => qr/\s+/,
		skip    => 0,
		take    => 7,
		label   => sub { $_[0][7] == 3 ? 1 : 0 },
		columns => [
			qw(area perimeter compactness kernel_length
				kernel_width asymmetry_coeff kernel_groove_length)
		],
	},
);

for my $name ( sort keys %SET ) {
	my $spec = $SET{$name};

	my $raw = `curl -sSf '$spec->{url}'`;
	die "fetch of $spec->{url} failed\n" if $? != 0 || !length $raw;
	my $sha = `printf '%s' '$raw' | sha256sum 2>/dev/null || printf '%s' '$raw' | sha256 -q`;
	chomp $sha;
	$sha =~ s/\s.*//;

	my ( @rows, @labels );
	for my $line ( split /\n/, $raw ) {
		$line =~ s/\r\z//;
		next if $line =~ /\A\s*\z/;
		my @f = split $spec->{sep}, $line;
		shift @f while @f && $f[0] eq '';    # leading-whitespace artefacts
		push @labels, $spec->{label}->( \@f );
		my @feat = @f[ $spec->{skip} .. $spec->{skip} + $spec->{take} - 1 ];
		die "$name: non-numeric feature cell in: $line\n"
			if grep { !/\A-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?\z/ } @feat;
		push @rows, \@feat;
	} ## end for my $line ( split /\n/, $raw )

	die "$name: expected $spec->{take} columns\n"
		if grep { scalar @$_ != $spec->{take} } @rows;

	my $csv = File::Spec->catfile( $HERE, "$name.csv" );
	open my $fh, '>', $csv or die "$csv: $!";
	print {$fh} join( ',', @{ $spec->{columns} } ) . "\n";
	print {$fh} join( ',', @$_ ) . "\n" for @rows;
	close $fh;

	my $lab = File::Spec->catfile( $HERE, "$name.labels" );
	open my $lh, '>', $lab or die "$lab: $!";
	print {$lh} "$_\n" for @labels;
	close $lh;

	my $anom = grep { $_ } @labels;
	printf "%-12s %4d rows x %2d features, %3d labelled anomalous (%.1f%%)\n",
		$name, scalar @rows, $spec->{take}, $anom, 100 * $anom / @rows;
	printf "%-12s upstream sha256 %s\n", '', $sha;
} ## end for my $name ( sort keys %SET )
