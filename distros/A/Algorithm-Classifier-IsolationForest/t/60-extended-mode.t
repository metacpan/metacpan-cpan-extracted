#!perl
use strict;
use warnings;
use Test::More;

use Algorithm::Classifier::IsolationForest;

my $CLASS = 'Algorithm::Classifier::IsolationForest';

# Run against the pure-Perl backend always, and against C when it compiled.
# A missing C backend skips that arm rather than failing.
my @BACKENDS = ( [ 'pure-perl' => 0 ] );
push @BACKENDS, [ 'C' => 1 ]
	if $Algorithm::Classifier::IsolationForest::HAS_C;

# 3-feature data so extension_level has room to be clamped.
my @data3 = map { [ $_, $_ * 2, ( $_ % 5 ) ] } 1 .. 60;

for my $be (@BACKENDS) {
	my ( $be_name, $USE_C ) = @$be;

	subtest "[$be_name] extended mode is recorded and fits" => sub {
		my $f = $CLASS->new(
			mode    => 'extended',
			n_trees => 20,
			seed    => 3,
			use_c   => $USE_C
		);
		$f->fit( \@data3 );
		is( $f->{mode},              'extended', 'mode stored as extended' );
		is( scalar @{ $f->{trees} }, 20,         'extended forest builds its trees' );

		my $scores = $f->score_samples( \@data3 );
		is( scalar @$scores, scalar @data3, 'extended mode scores every sample' );
		my $bad = grep { !defined $_ || $_ <= 0 || $_ > 1 } @$scores;
		is( $bad, 0, 'extended-mode scores are all in (0, 1]' );
	}; ## end "[$be_name] extended mode is recorded and fits" => sub

	subtest "[$be_name] extension_level defaults to the maximum (n_features - 1)" => sub {
		my $f = $CLASS->new(
			mode    => 'extended',
			n_trees => 5,
			seed    => 3,
			use_c   => $USE_C
		);
		$f->fit( \@data3 );
		is( $f->{extension_level_used}, 2, 'undef extension_level resolves to n_features - 1 (= 2 here)' );
	}; ## end "[$be_name] extension_level defaults to the maximum (n_features - 1)" => sub

	subtest "[$be_name] extension_level is clamped to [0, n_features - 1] at fit time" => sub {
		my $hi = $CLASS->new(
			mode            => 'extended',
			extension_level => 99,           # absurdly large
			n_trees         => 5,
			seed            => 3,
			use_c           => $USE_C,
		);
		$hi->fit( \@data3 );
		is( $hi->{extension_level_used}, 2, 'an over-large extension_level is clamped down to n_features - 1' );

		my $lo = $CLASS->new(
			mode            => 'extended',
			extension_level => 0,            # axis-like single-feature splits
			n_trees         => 5,
			seed            => 3,
			use_c           => $USE_C,
		);
		$lo->fit( \@data3 );
		is( $lo->{extension_level_used}, 0, 'extension_level => 0 is preserved (single-feature oblique splits)' );
	}; ## end "[$be_name] extension_level is clamped to [0, n_features - 1] at fit time" => sub

	subtest "[$be_name] extension_level is unused in axis mode" => sub {
		my $f = $CLASS->new(
			mode    => 'axis',
			n_trees => 5,
			seed    => 3,
			use_c   => $USE_C
		);
		$f->fit( \@data3 );
		is( $f->{extension_level_used}, undef, 'axis mode does not resolve an extension level' );
	}; ## end "[$be_name] extension_level is unused in axis mode" => sub

	subtest "[$be_name] one-dimensional data works in both modes" => sub {
		my @data1 = map { [$_] } 1 .. 50;

		for my $mode (qw(axis extended)) {
			my $f = $CLASS->new(
				mode    => $mode,
				n_trees => 20,
				seed    => 11,
				use_c   => $USE_C
			);
			$f->fit( \@data1 );
			is( $f->{n_features}, 1, "$mode: single feature inferred" );

			# A value far outside the 1..50 range should look anomalous.
			my $scores = $f->score_samples( [ [25], [1000] ] );
			cmp_ok( $scores->[1], '>', $scores->[0],
				"$mode: a distant 1-D point scores higher than a central one" );
		} ## end for my $mode (qw(axis extended))
	}; ## end "[$be_name] one-dimensional data works in both modes" => sub
} ## end for my $be (@BACKENDS)

done_testing;
