#!perl
# 31-undef-column-no-warnings.t
#
# Verifies that score_samples, predict, and score_predict_samples produce
# no warnings when a sample contains undef in one or more feature columns.
#
# Perl coerces undef to 0 in numeric context.  The _path_length traversal
# guards every feature access with "// 0" so that the coercion is silent
# regardless of which column(s) are undef.  The same battery runs against
# the pure-Perl backend and, when it compiled, the C backend; a missing C
# backend skips that arm rather than failing.

use strict;
use warnings;
use Test::More;

use Algorithm::Classifier::IsolationForest;

my $CLASS = 'Algorithm::Classifier::IsolationForest';

my @BACKENDS = ( [ 'pure-perl' => 0 ] );
push @BACKENDS, [ 'C' => 1 ]
	if $Algorithm::Classifier::IsolationForest::HAS_C;

# Training data: 2-D regular grid (no undef anywhere in training).
my @train;
for my $i ( -7 .. 7 ) {
	for my $j ( -7 .. 7 ) {
		push @train, [ $i / 7.0, $j / 7.0 ];
	}
}

# Test points that deliberately have undef in one or both columns.
my @undef_pts = (
	[ 0.3,   undef ],    # inlier-like x, missing y
	[ 6.0,   undef ],    # outlier-like x, missing y
	[ undef, 0.5 ],      # missing x, inlier-like y
	[ undef, undef ],    # both columns missing
	[ -0.5,  undef ],    # negative inlier x, missing y
	[ -7.0,  undef ],    # outlier-like negative x, missing y
);

# Helper: run a block and collect any warnings it emits.
sub _capture_warnings {
	my ($code) = @_;
	my @w;
	local $SIG{__WARN__} = sub { push @w, @_ };
	$code->();
	return @w;
}

for my $be (@BACKENDS) {
	my ( $be_name, $USE_C ) = @$be;

	my $f = $CLASS->new(
		n_trees     => 100,
		sample_size => 256,
		seed        => 42,
		use_c       => $USE_C
	);
	$f->fit( \@train );

	subtest "[$be_name] score_samples emits no warnings with undef column(s)" => sub {
		my @warns = _capture_warnings( sub { $f->score_samples( \@undef_pts ) } );
		is( scalar @warns, 0, 'no warnings from score_samples on undef column(s)' );
	};

	subtest "[$be_name] predict emits no warnings with undef column(s)" => sub {
		my @warns = _capture_warnings( sub { $f->predict( \@undef_pts ) } );
		is( scalar @warns, 0, 'no warnings from predict on undef column(s)' );
	};

	subtest "[$be_name] score_predict_samples emits no warnings with undef column(s)" => sub {
		my @warns = _capture_warnings( sub { $f->score_predict_samples( \@undef_pts ) } );
		is( scalar @warns, 0, 'no warnings from score_predict_samples on undef column(s)' );
	};

	subtest "[$be_name] score_predict_split emits no warnings with undef column(s)" => sub {
		my @warns = _capture_warnings( sub { $f->score_predict_split( \@undef_pts ) } );
		is( scalar @warns, 0, 'no warnings from score_predict_split on undef column(s)' );

		# Also verify the new method returns scores/labels consistent with
		# score_predict_samples on the same data (numeric equality on scores,
		# exact equality on labels).
		my $pairs = $f->score_predict_samples( \@undef_pts );
		my ( $scores, $labels ) = $f->score_predict_split( \@undef_pts );
		is( scalar @$scores, scalar @$pairs, 'split returns matching scores length' );
		is( scalar @$labels, scalar @$pairs, 'split returns matching labels length' );

		my $mismatches = 0;
		for my $i ( 0 .. $#$pairs ) {
			$mismatches++ if $scores->[$i] != $pairs->[$i][0];
			$mismatches++ if $labels->[$i] != $pairs->[$i][1];
		}
		is( $mismatches, 0, 'score_predict_split scores/labels match score_predict_samples element-for-element' );
	}; ## end "[$be_name] score_predict_split emits no warnings with undef column(s)" => sub

	subtest "[$be_name] extended mode: score_samples emits no warnings with undef column(s)" => sub {
		my $ef = $CLASS->new(
			n_trees     => 100,
			sample_size => 256,
			mode        => 'extended',
			seed        => 42,
			use_c       => $USE_C,
		);
		$ef->fit( \@train );
		my @warns = _capture_warnings( sub { $ef->score_samples( \@undef_pts ) } );
		is( scalar @warns, 0, 'no warnings from score_samples (extended mode) on undef column(s)' );
	}; ## end "[$be_name] extended mode: score_samples emits no warnings with undef column(s)" => sub
} ## end for my $be (@BACKENDS)

done_testing;
