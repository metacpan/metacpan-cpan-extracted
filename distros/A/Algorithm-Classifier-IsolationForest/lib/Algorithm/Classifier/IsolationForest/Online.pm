package Algorithm::Classifier::IsolationForest::Online;

use strict;
use warnings;
use Carp        qw(croak);
use JSON::PP    ();
use File::Slurp qw(read_file write_file);

# Runtime-only dependency: tagged_row_to_array is delegated to the parent
# class (identical semantics, no point duplicating it) and the
# contamination threshold selection reuses _threshold_from_ranked.  The
# parent never loads this module at compile time (its from_json requires
# it on demand), so there is no cycle.
use Algorithm::Classifier::IsolationForest ();

our $VERSION = '0.6.0';

# Node layout.  Unlike the batch forest's nodes, online nodes are mutable
# and carry a running point count plus the bounding box (per-feature
# lo/hi) of every point that has passed through them -- that box is what
# split simulation samples from, since points themselves are never stored
# in the tree.  Both node types share the first four slots so the
# learn/unlearn bookkeeping never has to branch on type:
#
#   leaf:     [0, count, \@lo, \@hi]
#   internal: [1, count, \@lo, \@hi, attr, split, left, right]
#
# The type tag mirrors the parent's convention (0 is falsy, so
# while ($node->[0]) walks to a leaf).  A leaf built from an empty
# synthetic partition has count 0 and an undef box (slots 2/3); the box
# is initialised from the first real point that reaches it.
use constant _N_TYPE  => 0;
use constant _N_COUNT => 1;
use constant _N_LO    => 2;
use constant _N_HI    => 3;
use constant _N_ATTR  => 4;
use constant _N_SPLIT => 5;
use constant _N_LEFT  => 6;
use constant _N_RIGHT => 7;

use constant _NT_LEAF => 0;
use constant _NT_AXIS => 1;

# Trees are binary (the reference implementation's branching_factor == 2),
# which fixes the depth-budget log base at log(2 * 2).  Spelled as the
# exact-double literal rather than log(4) so it is bit-identical to the
# OL_LOG4 literal the C learn path uses regardless of the platform's
# libm rounding -- a one-ulp disagreement would flip `depth < limit`
# split decisions exactly when a tree's count is eta * 4**k (the same
# TWO_PI trick the parent uses for _randn parity).
use constant _LOG4 => unpack( 'd', pack 'd', 1.3862943611198906 );
use constant _LOG2 => log(2);

# DBL_EPSILON, added to the normalisation factor before dividing so a
# just-started model (normaliser 0) yields well-defined scores instead of
# a division by zero -- the same guard the reference implementation uses.
use constant _EPS => 2.220446049250313e-16;

# The online learn/unlearn/score-row XS functions were added to the C
# backend after the batch-scoring ones, so a prebuilt object installed
# from an older release can back $HAS_C while lacking them (the parent
# trusts a flag-matched prebuilt object without inspecting its symbol
# set).  Probe once at load: without them, use_c still accelerates the
# packed-snapshot batch scoring -- those functions have been in the
# object all along -- and learning quietly stays pure Perl instead of
# crashing on an undefined XS sub.  Rebuilding/reinstalling (or
# IF_RUNTIME_BUILD=1) restores the full set.
use constant _HAS_ONLINE_XS => defined &Algorithm::Classifier::IsolationForest::online_learn_row_xs ? 1 : 0;

=head1 NAME

Algorithm::Classifier::IsolationForest::Online - Online (streaming) Isolation Forest anomaly detection

=head1 SYNOPSIS

    use Algorithm::Classifier::IsolationForest::Online;

    my $oif = Algorithm::Classifier::IsolationForest::Online->new(
        n_trees          => 100,
        window_size      => 2048,
        max_leaf_samples => 32,
        seed             => 42,
    );

    # stream data through the model; each point is learned and old
    # points beyond the window are forgotten automatically
    $oif->learn(\@warmup_rows);

    # prequential operation: score each point against the model as it
    # stood BEFORE that point was learned, then learn it
    my $scores = $oif->score_learn(\@new_rows);

    # or score without learning
    my $scores2 = $oif->score_samples(\@query_rows);
    my $labels  = $oif->predict(\@query_rows);

    # persistence keeps the window, so a reloaded model keeps forgetting
    # correctly as the stream continues
    $oif->save('oiforest_model.json');
    my $resumed = Algorithm::Classifier::IsolationForest::Online->load('oiforest_model.json');

=head1 DESCRIPTION

Implements Online Isolation Forest (Online-iForest; Leveni, Weigert
Cassales, Pfahringer, Bifet & Boracchi 2024 -- see REFERENCES), a
streaming variant of Isolation Forest for data that arrives continuously
and whose distribution may drift.  There is no C<fit()>: the model
C<learn>s points as they arrive and, once more than C<window_size> points
have been seen, forgets the oldest point for every new one so the model
always reflects the most recent C<window_size> points of the stream.

Trees never store data points.  Each node keeps only a running count of
the points that passed through it and the bounding box of their feature
values.  A leaf splits once enough points have accumulated (see
C<max_leaf_samples> and C<growth>); because the actual points are gone,
the split simulates them by sampling uniformly inside the leaf's bounding
box.  Forgetting reverses the process: counts are decremented along the
forgotten point's path and a subtree whose count falls below its split
requirement is collapsed back into a leaf.

Scoring follows the classic Isolation Forest intuition -- anomalies
isolate at shallow depth -- but normalises by the depth budget
C<log(n/max_leaf_samples) / log(4)> of the current window rather than the
batch model's C<c(psi)>.  Scores are in (0, 1] with high values
anomalous, directly comparable in spirit (though not numerically) to the
parent class's scores.

Both learning and scoring are accelerated through the parent class's
Inline::C backend when it is available; C<use_c> covers them together.

Learning (and the per-row walks inside C<score_learn>) runs in C
directly against the live trees, drawing randomness through the same
generator in the same order as the pure-Perl path -- so, like the
parent's C<fit()>, a C<learn()> with a given seed produces bit-identical
trees whether C<use_c> is on or off (on C<nvsize == 8> perls; wide-NV
perls keep extra low bits in the pure-Perl path).  The knob changes
speed, never results.

Batch scoring lazily flattens the mutable trees into the same packed
node layout the batch scorer walks -- online trees are axis-only, and
the online per-leaf depth adjustment rides in the slot the batch packer
uses for its own leaf adjustment -- so C<score_samples>, C<predict>,
C<path_lengths>, C<score_predict_samples>, and C<score_predict_split>
all run through the same C (and OpenMP, when linked) tree walk the
parent uses, with identical results to the pure-Perl fallback.  Any
C<learn> invalidates the packed snapshot; the next batch-scoring call
repacks once.  C<score_learn> never touches the snapshot: it mutates
the trees after every single point, so its rows are scored by walking
the live trees in C instead.

A model needs to have seen at least C<max_leaf_samples> points before
tree structure exists at all; until then every point scores 1.0.  Give
the model a warm-up C<learn()> pass before trusting scores or labels.

Models saved by this class carry their own C<format> tag.
C<< Algorithm::Classifier::IsolationForest->load >> recognises it and
dispatches here, so callers can load either model type through the
parent class.

=head1 GENERAL METHODS

=head2 new(%args)

Inits the object.

  - n_trees :: number of isolation trees in the ensemble
      default :: 100

  - window_size :: how many of the most recent points the model reflects.
          Once the stream exceeds this, learning a point forgets the
          oldest retained point.  0 or undef disables forgetting: the
          model then learns from the whole stream and retains no window
          (so nothing is ever unlearned and threshold relearning needs
          caller-supplied data).
      default :: 2048

  - max_leaf_samples :: how many points a leaf must accumulate before it
          splits (eta in the paper).  Also the unit of the depth budget:
          trees stop splitting past log(n/eta)/log(4).
      default :: 32

  - growth :: how the split requirement scales with depth (the reference
          implementation's `type` parameter).
            adaptive :: a leaf at depth k needs max_leaf_samples * 2**k
                        points to split -- deeper splits need
                        exponentially more evidence
            fixed    :: max_leaf_samples points regardless of depth
      default :: adaptive

  - subsample :: probability in (0, 1] that a given tree learns (or
          forgets) a given point, drawn independently per tree per point.
          Values below 1 increase diversity among trees on very dense
          streams.  Note that, as in the reference implementation, learn
          and forget draws are independent, so per-tree counts are only
          approximate under subsampling.
      default :: 1.0

  - seed :: optional integer to seed srand with, for reproducible trees
          given the same stream in the same order.  Processed via
          abs(int()).  Seeding happens here in new(), since there is no
          fit() to do it in.
      default :: undef

  - contamination :: expected fraction of anomalies, in (0, 0.5]. When
          set, the first predict()-family call learns a score threshold
          that flags this fraction of the current window, and uses it as
          the default cutoff.  The threshold does NOT track the stream
          automatically afterwards; call relearn_threshold() to refresh
          it.  undef => no learned threshold (predict() falls back to
          0.5).
      default :: undef

  - missing :: how learn() treats undef (missing) feature cells.  Scoring
          always tolerates undef (mapped to 0), matching the parent
          class's long-standing behaviour.
            die  :: croak if a learned point contains an undef cell
            zero :: treat a missing cell as the value 0
      default :: die

  - feature_names :: optional arrayref of per-feature labels enabling the
          *_tagged methods (and required by mungers below).
      default :: undef

  - mungers :: optional hashref of declarative L<Algorithm::ToNumberMunger>
          specs; every tagged row (learn_tagged, score_learn_tagged, the
          scoring *_tagged methods, tagged_row_to_array) is munged from
          raw values into numbers through the compiled plan, and
          munge_rows() applies the scalar mungers to positional rows.
          Requires feature_names; spec errors croak here.  The spec is
          saved with the model.  Identical semantics to the parent
          class's knob -- see MUNGERS in
          L<Algorithm::Classifier::IsolationForest> for details and
          caveats.
      default :: undef

  - schema_version :: optional opaque string identifying the revision of
          the variable schema this model was built against.  Never
          parsed; saved with the model.  Usually set via a prototype --
          see PROTOTYPES in L<Algorithm::Classifier::IsolationForest>
          (whose new_from_prototype creates online models too).
      default :: undef

  - schema_description :: optional opaque free-text description of what
          the variable schema is.  Same handling as schema_version.
      default :: undef

  - feature_descriptions :: optional hashref of 'feature name => free
          text' describing individual features.  Requires feature_names;
          every key must name an entry there or new() croaks.  Partial
          coverage is fine.  Saved with the model.
      default :: undef

  - use_c :: boolean, override whether the parent class's Inline::C
          backend is used, for learning and scoring both (see
          DESCRIPTION).  When false the instance runs pure Perl even if
          the C backend compiled.  Results are identical either way --
          learn() builds bit-identical trees for the same seed (on
          nvsize == 8 perls) and scoring matches exactly -- so only
          speed differs.
      default :: $Algorithm::Classifier::IsolationForest::HAS_C

  - use_openmp :: boolean, override whether OpenMP parallel scoring is
          used inside the C tree walk.  Ignored when use_c is false.
      default :: $Algorithm::Classifier::IsolationForest::HAS_OPENMP

=cut

sub new {
	my ( $class, %args ) = @_;

	my $growth = $args{growth} // 'adaptive';
	croak "growth must be 'adaptive' or 'fixed'"
		unless $growth =~ /\A(?:adaptive|fixed)\z/;

	my $missing = $args{missing} // 'die';
	croak "missing must be one of: die, zero"
		unless $missing =~ /\A(?:die|zero)\z/;

	if ( defined( $args{seed} ) ) {
		$args{seed} = abs( int( $args{seed} ) );
	}

	# window_size => 0 and window_size => undef both mean "no forgetting";
	# normalise to 0 so the rest of the code has one falsy spelling.
	my $window_size = exists $args{window_size} ? ( $args{window_size} // 0 ) : 2048;

	# Clamp the accel knobs against what the parent's build actually has,
	# exactly as the parent's new() does: use_c => 1 without a compiled
	# backend would otherwise call undefined XS subs at first scoring, and
	# OpenMP is meaningless without the C tree walk.
	my $use_c
		= defined $args{use_c}
		? ( $args{use_c} && $Algorithm::Classifier::IsolationForest::HAS_C ? 1 : 0 )
		: $Algorithm::Classifier::IsolationForest::HAS_C;
	my $use_openmp
		= defined $args{use_openmp}
		? ( $args{use_openmp} && $Algorithm::Classifier::IsolationForest::HAS_OPENMP ? 1 : 0 )
		: $Algorithm::Classifier::IsolationForest::HAS_OPENMP;
	$use_openmp = 0 unless $use_c;

	my $self = {
		n_trees              => $args{n_trees} // 100,
		window_size          => $window_size,
		max_leaf_samples     => $args{max_leaf_samples} // 32,
		growth               => $growth,
		subsample            => $args{subsample} // 1.0,
		seed                 => $args{seed},
		contamination        => $args{contamination},
		missing              => $missing,
		feature_names        => $args{feature_names},
		threshold            => undef,                           # learned lazily if contamination set
		n_features           => undef,                           # learned from the first row
		seen                 => 0,                               # total points learned over the model's lifetime
		window               => [],                              # the retained rows, oldest first
		trees                => [],
		mungers              => undef,                           # optional Algorithm::ToNumberMunger spec hash
																 # Opaque schema metadata, usually set via the parent class's
																 # new_from_prototype and persisted with the model.
		schema_version       => $args{schema_version},
		schema_description   => $args{schema_description},
		feature_descriptions => $args{feature_descriptions},
		_use_c               => $use_c,
		_use_openmp          => $use_openmp,
	};

	for my $doc (qw(schema_version schema_description)) {
		croak "$doc must be a plain string"
			if defined $self->{$doc} && ref $self->{$doc};
	}
	Algorithm::Classifier::IsolationForest::_validate_feature_descriptions( $self->{feature_names},
		$self->{feature_descriptions} )
		if defined $self->{feature_descriptions};

	# Optional Algorithm::ToNumberMunger integration, identical to the
	# parent's: compiled eagerly so spec errors surface here; the module
	# is only required when a spec is actually given.
	if ( defined $args{mungers} ) {
		croak "mungers must be a hashref of 'tag => munger spec'"
			unless ref $args{mungers} eq 'HASH';
		croak "mungers requires feature_names (the munger plan compiles against them)"
			unless ref $self->{feature_names} eq 'ARRAY' && @{ $self->{feature_names} };
		$self->{mungers} = $args{mungers};
		$self->{_munger_plan}
			= Algorithm::Classifier::IsolationForest::_compile_mungers( $self->{feature_names}, $self->{mungers} );
		$self->{munger_module_version} = $Algorithm::ToNumberMunger::VERSION;
	} ## end if ( defined $args{mungers} )

	croak "n_trees must be >= 1"          unless $self->{n_trees} >= 1;
	croak "max_leaf_samples must be >= 1" unless $self->{max_leaf_samples} >= 1;
	croak "window_size must be 0 (unbounded) or >= max_leaf_samples"
		if $self->{window_size} && $self->{window_size} < $self->{max_leaf_samples};
	croak "subsample must be in (0, 1]"
		unless $self->{subsample} > 0 && $self->{subsample} <= 1;
	croak "contamination must be a number in (0, 0.5]"
		if defined $self->{contamination}
		&& !( $self->{contamination} > 0 && $self->{contamination} <= 0.5 );

	$self->{trees} = [ map { { root => undef, count => 0, depth_limit => 0 } } 1 .. $self->{n_trees} ];

	srand( $self->{seed} ) if defined $self->{seed};

	return bless $self, $class;
} ## end sub new

=head2 learn(\@data)

Learns the passed samples, in order, as the next points of the stream.
Once the model has seen more than C<window_size> points, each learned
point also forgets the oldest retained point, so the model tracks the
most recent C<window_size> points.

The data format matches the parent class's C<fit>: an arrayref of
arrayrefs, each inner arrayref one sample of numeric features.  All
samples must have the same feature count; the count is locked in by the
first sample ever learned.

Returns C<$self>, so it chains.

    $oif->learn(\@rows);

=cut

sub learn {
	my ( $self, $data ) = @_;
	croak "learn() expects a non-empty arrayref of samples"
		unless ref $data eq 'ARRAY' && @$data;
	for my $row (@$data) {
		$self->_learn_row( $self->_prep_row( $row, 'learn' ) );
	}
	return $self;
}

=head2 learn_tagged(\%row)

=head2 learn_tagged(\@rows)

Learns one sample supplied as a hashref of named feature values, or a
whole batch supplied as an arrayref of such hashrefs, in stream order.
The model must have C<feature_names> set.  Rows go through
L</tagged_row_to_array> (and therefore through the munger plan when
C<mungers> is configured).  Returns C<$self>.

    $oif->learn_tagged({ cpu => 0.9, mem => 0.4, disk => 0.1 });
    $oif->learn_tagged(\@hashref_rows);

Croaks under the same conditions as L</tagged_row_to_array>, naming the
offending row by index in the batch form.

=cut

sub learn_tagged {
	my ( $self, $row ) = @_;
	if ( ref $row eq 'ARRAY' ) {
		my @rows;
		for my $i ( 0 .. $#$row ) {
			push @rows, $self->tagged_row_to_array( $row->[$i], "learn_tagged (row $i)" );
		}
		return $self->learn( \@rows );
	}
	my $vec = $self->tagged_row_to_array( $row, 'learn_tagged' );
	return $self->learn( [$vec] );
} ## end sub learn_tagged

=head2 score_learn(\@data)

Prequential (test-then-train) operation, the usual way to run a streaming
detector: each sample is scored against the model as it stood I<before>
that sample was learned, then learned.  Returns an arrayref of anomaly
scores, one per sample, in input order.

Unlike the pure scoring methods this works on a brand-new model too (the
first points of a stream simply score 1.0, as nothing is known yet).

    my $scores = $oif->score_learn(\@rows);

=cut

sub score_learn {
	my ( $self, $data ) = @_;
	croak "score_learn() expects a non-empty arrayref of samples"
		unless ref $data eq 'ARRAY' && @$data;
	my @scores;
	for my $row (@$data) {
		my $r = $self->_prep_row( $row, 'score_learn' );
		push @scores, $self->_score_row($r);
		$self->_learn_row($r);
	}
	return \@scores;
} ## end sub score_learn

=head2 score_learn_tagged(\%row)

Prequential score-then-learn for a single sample supplied as a hashref of
named feature values.  Returns the scalar anomaly score the sample had
before it was learned.

    my $score = $oif->score_learn_tagged({ cpu => 0.9, mem => 0.4 });

Croaks under the same conditions as L</tagged_row_to_array>.

=cut

sub score_learn_tagged {
	my ( $self, $row ) = @_;
	my $vec    = $self->tagged_row_to_array( $row, 'score_learn_tagged' );
	my $result = $self->score_learn( [$vec] );
	return $result->[0];
}

=head2 score_samples(\@data)

Returns an arrayref of anomaly scores in (0, 1] without learning
anything.  Scores near 1 are strong anomalies (isolated at shallow
depth); scores well below 0.5 are normal.

    my $scores = $oif->score_samples(\@data);

=cut

sub score_samples {
	my ( $self, $data ) = @_;
	$self->_check_learned;
	croak "score_samples() expects an arrayref of samples"
		unless ref $data eq 'ARRAY';

	if ( $self->_ensure_c_trees ) {
		my ( $n_pts, $x_packed ) = $self->_pack_input($data);
		my $sums_packed = "\0" x ( $n_pts * 8 );
		Algorithm::Classifier::IsolationForest::score_all_xs(
			$self->{_c_nodes},   $self->{_c_coef_idx},       $self->{_c_coef_val},
			$x_packed,           $sums_packed,               $n_pts,
			$self->{n_features}, scalar @{ $self->{trees} }, $self->{_use_openmp}
		);
		my $result = [];
		Algorithm::Classifier::IsolationForest::finalize_scores_xs( $sums_packed, $n_pts, $self->_score_inv, $result );
		return $result;
	} ## end if ( $self->_ensure_c_trees )

	my $sums = $self->_depth_sums($data);
	my $inv  = $self->_score_inv;
	return [ map { exp( -$_ * $inv ) } @$sums ];
} ## end sub score_samples

=head2 score_sample_tagged(\%row)

Scores a single sample supplied as a hashref of named feature values,
without learning it.  Returns a scalar anomaly score in (0, 1].

    my $score = $oif->score_sample_tagged({ cpu => 0.9, mem => 0.4 });

Croaks under the same conditions as L</tagged_row_to_array>.

=cut

sub score_sample_tagged {
	my ( $self, $row ) = @_;
	my $vec    = $self->tagged_row_to_array( $row, 'score_sample_tagged' );
	my $result = $self->score_samples( [$vec] );
	return $result->[0];
}

=head2 path_lengths(\@data)

Returns an arrayref of the mean isolation depth per sample across the
trees, for inspection -- the streaming counterpart of the parent class's
method of the same name.  Depths include the per-leaf count adjustment.

    my $depths = $oif->path_lengths(\@data);

=cut

sub path_lengths {
	my ( $self, $data ) = @_;
	$self->_check_learned;
	croak "path_lengths() expects an arrayref of samples"
		unless ref $data eq 'ARRAY';
	my $t = scalar @{ $self->{trees} };

	if ( $self->_ensure_c_trees ) {
		my ( $n_pts, $x_packed ) = $self->_pack_input($data);
		my $sums_packed = "\0" x ( $n_pts * 8 );
		Algorithm::Classifier::IsolationForest::score_all_xs(
			$self->{_c_nodes},   $self->{_c_coef_idx}, $self->{_c_coef_val},
			$x_packed,           $sums_packed,         $n_pts,
			$self->{n_features}, $t,                   $self->{_use_openmp}
		);
		my $result = [];
		Algorithm::Classifier::IsolationForest::finalize_path_lengths_xs( $sums_packed, $n_pts, $t + 0.0, $result );
		return $result;
	} ## end if ( $self->_ensure_c_trees )

	my $sums = $self->_depth_sums($data);
	return [ map { $_ / $t } @$sums ];
} ## end sub path_lengths

=head2 predict(\@data, $threshold)

Returns an arrayref of 0/1 labels for the specified data, without
learning it.

If C<$threshold> is not given, the contamination-learned cutoff is used
when available (learned from the current window on first use -- see
C<contamination> in L</new>), otherwise 0.5.

Note that absolute score levels depend on C<window_size> and
C<max_leaf_samples> (shallower depth budgets compress scores downward),
so the 0.5 fallback is a blunt default here -- anomalies reliably rank
above normal points, but may sit below 0.5.  Setting C<contamination>,
or passing a threshold calibrated from observed scores, is recommended.

    my $labels = $oif->predict(\@data);

=cut

sub predict {
	my ( $self, $data, $threshold ) = @_;
	$self->_check_learned;
	$self->_ensure_threshold;
	$threshold
		= defined $threshold         ? $threshold
		: defined $self->{threshold} ? $self->{threshold}
		:                              0.5;

	# Fast path: threshold the raw depth sums directly, skipping the
	# per-point exp() -- score >= T iff sum <= -log(T)/inv.  Only valid
	# for a normal threshold in (0, 1), like the parent's gate.
	if ( $threshold > 0 && $threshold < 1 && $self->_ensure_c_trees ) {
		my ( $n_pts, $x_packed ) = $self->_pack_input($data);
		my $sums_packed = "\0" x ( $n_pts * 8 );
		Algorithm::Classifier::IsolationForest::score_all_xs(
			$self->{_c_nodes},   $self->{_c_coef_idx},       $self->{_c_coef_val},
			$x_packed,           $sums_packed,               $n_pts,
			$self->{n_features}, scalar @{ $self->{trees} }, $self->{_use_openmp}
		);
		my $sum_threshold = -log($threshold) / $self->_score_inv;
		my $result        = [];
		Algorithm::Classifier::IsolationForest::predict_sums_xs( $sums_packed, $n_pts, $sum_threshold, $result );
		return $result;
	} ## end if ( $threshold > 0 && $threshold < 1 && $self...)

	my $scores = $self->score_samples($data);
	return [ map { $_ >= $threshold ? 1 : 0 } @$scores ];
} ## end sub predict

=head2 predict_tagged(\%row, $threshold)

Predicts whether a single sample, supplied as a hashref of named feature
values, is an anomaly.  Returns a scalar 1 (anomaly) or 0 (normal).
C<$threshold> defaults the same way as in L</predict>.

    my $label = $oif->predict_tagged({ cpu => 0.9, mem => 0.4 });

Croaks under the same conditions as L</tagged_row_to_array>.

=cut

sub predict_tagged {
	my ( $self, $row, $threshold ) = @_;
	my $vec    = $self->tagged_row_to_array( $row, 'predict_tagged' );
	my $result = $self->predict( [$vec], $threshold );
	return $result->[0];
}

=head2 score_predict_samples(\@data, $threshold)

Returns an arrayref of C<[$score, $label]> pairs, one per sample, without
learning.  C<$threshold> defaults the same way as in L</predict>.

    my $results = $oif->score_predict_samples(\@data);

=cut

sub score_predict_samples {
	my ( $self, $data, $threshold ) = @_;
	$self->_check_learned;
	$self->_ensure_threshold;
	$threshold
		= defined $threshold         ? $threshold
		: defined $self->{threshold} ? $self->{threshold}
		:                              0.5;

	# Fast path: [score, label] pairs built straight from the sum buffer
	# in one C call; gated identically to predict().
	if ( $threshold > 0 && $threshold < 1 && $self->_ensure_c_trees ) {
		my ( $n_pts, $x_packed ) = $self->_pack_input($data);
		my $sums_packed = "\0" x ( $n_pts * 8 );
		Algorithm::Classifier::IsolationForest::score_all_xs(
			$self->{_c_nodes},   $self->{_c_coef_idx},       $self->{_c_coef_val},
			$x_packed,           $sums_packed,               $n_pts,
			$self->{n_features}, scalar @{ $self->{trees} }, $self->{_use_openmp}
		);
		my $inv           = $self->_score_inv;
		my $sum_threshold = -log($threshold) / $inv;
		my $result        = [];
		Algorithm::Classifier::IsolationForest::score_predict_xs( $sums_packed, $n_pts, $inv, $sum_threshold, $result );
		return $result;
	} ## end if ( $threshold > 0 && $threshold < 1 && $self...)

	my $scores = $self->score_samples($data);
	return [ map { [ $_, ( $_ >= $threshold ? 1 : 0 ) ] } @$scores ];
} ## end sub score_predict_samples

=head2 score_predict_sample_tagged(\%row, $threshold)

Scores and classifies a single sample supplied as a hashref of named
feature values.  Returns a two-element arrayref C<[$score, $label]>.
C<$threshold> defaults the same way as in L</predict>.

    my $pair = $oif->score_predict_sample_tagged({ cpu => 0.9, mem => 0.4 });

Croaks under the same conditions as L</tagged_row_to_array>.

=cut

sub score_predict_sample_tagged {
	my ( $self, $row, $threshold ) = @_;
	my $vec    = $self->tagged_row_to_array( $row, 'score_predict_sample_tagged' );
	my $result = $self->score_predict_samples( [$vec], $threshold );
	return $result->[0];
}

=head2 score_predict_split(\@data, $threshold)

Same values as L</score_predict_samples> but returned as two flat
arrayrefs.  In list context returns C<($scores_aref, $labels_aref)>.

    my ($scores, $labels) = $oif->score_predict_split(\@data);

=cut

sub score_predict_split {
	my ( $self, $data, $threshold ) = @_;
	$self->_check_learned;
	$self->_ensure_threshold;
	$threshold
		= defined $threshold         ? $threshold
		: defined $self->{threshold} ? $self->{threshold}
		:                              0.5;

	# Fast path: two flat arrayrefs straight from the sum buffer; gated
	# identically to predict().
	if ( $threshold > 0 && $threshold < 1 && $self->_ensure_c_trees ) {
		my ( $n_pts, $x_packed ) = $self->_pack_input($data);
		my $sums_packed = "\0" x ( $n_pts * 8 );
		Algorithm::Classifier::IsolationForest::score_all_xs(
			$self->{_c_nodes},   $self->{_c_coef_idx},       $self->{_c_coef_val},
			$x_packed,           $sums_packed,               $n_pts,
			$self->{n_features}, scalar @{ $self->{trees} }, $self->{_use_openmp}
		);
		my $inv           = $self->_score_inv;
		my $sum_threshold = -log($threshold) / $inv;
		my $scores        = [];
		my $labels        = [];
		Algorithm::Classifier::IsolationForest::score_predict_split_xs( $sums_packed, $n_pts, $inv,
			$sum_threshold, $scores, $labels );
		return ( $scores, $labels );
	} ## end if ( $threshold > 0 && $threshold < 1 && $self...)

	my $scores = $self->score_samples($data);
	my @labels = map { $_ >= $threshold ? 1 : 0 } @$scores;
	return ( $scores, \@labels );
} ## end sub score_predict_split

=head2 relearn_threshold(\@data)

Re-derives the contamination decision threshold so it flags the requested
fraction of the current window (or of C<\@data>, when passed).  Call this
after the stream has drifted, or on whatever cadence threshold freshness
matters; learning alone never moves the threshold.

Requires C<contamination> to have been set.  With C<< window_size => 0 >>
no window is retained, so C<\@data> must be supplied.

Returns C<$self>, so it chains.

    $oif->relearn_threshold;

=cut

sub relearn_threshold {
	my ( $self, $data ) = @_;
	croak "relearn_threshold requires contamination to have been set in new()"
		unless defined $self->{contamination};
	my $rows = defined $data ? $data : $self->{window};
	croak "relearn_threshold: no retained window to learn a threshold from "
		. "(window_size is 0); pass an arrayref of recent data"
		unless ref $rows eq 'ARRAY' && @$rows;

	my $scores = $self->score_samples($rows);
	my @desc   = sort { $b <=> $a } @$scores;
	my $n_pts  = scalar @desc;
	my $k      = int( $self->{contamination} * $n_pts + 0.5 );
	$k                 = 1      if $k < 1;
	$k                 = $n_pts if $k > $n_pts;
	$self->{threshold} = Algorithm::Classifier::IsolationForest::_threshold_from_ranked( \@desc, $k );
	return $self;
} ## end sub relearn_threshold

=head2 decision_threshold

The score cutoff the predict methods use by default; undef unless
C<contamination> was set and a predict-family method or
L</relearn_threshold> has run.

=cut

sub decision_threshold { return $_[0]->{threshold} }

=head2 feature_names

Returns the arrayref of feature name strings stored with the model, or
undef if none were provided.

=cut

sub feature_names { return $_[0]->{feature_names} }

=head2 schema_version

Returns the user-owned schema version string stored with the model
(usually via a prototype -- see PROTOTYPES in
L<Algorithm::Classifier::IsolationForest>), or undef if none was
recorded.

=cut

sub schema_version { return $_[0]->{schema_version} }

=head2 schema_description

Returns the free-text description of the variable schema stored with the
model, or undef if none was recorded.

=cut

sub schema_description { return $_[0]->{schema_description} }

=head2 feature_descriptions

Returns the hashref of per-feature description strings stored with the
model, or undef if none were recorded.  Keys are feature names; coverage
may be partial.

=cut

sub feature_descriptions { return $_[0]->{feature_descriptions} }

=head2 window_count

Returns how many points the model currently retains in its sliding
window (0 when C<< window_size => 0 >>).

=cut

sub window_count { return scalar @{ $_[0]->{window} } }

=head2 seen

Returns the total number of points learned over the model's lifetime,
including points that have since been forgotten.

=cut

sub seen { return $_[0]->{seen} }

=head2 tagged_row_to_array(\%row, $caller)

Validates a hashref of named feature values against the model's stored
C<feature_names> and returns a positional arrayref.  Identical semantics
to the parent class's method of the same name (to which it delegates);
see there for the croak conditions.

=cut

sub tagged_row_to_array {
	my $self = shift;
	return Algorithm::Classifier::IsolationForest::tagged_row_to_array( $self, @_ );
}

=head2 munge_rows(\@rows)

Applies the model's scalar mungers to positional rows, exactly as the
parent class's method of the same name (to which it delegates); a model
without C<mungers> returns the input unchanged.

=cut

sub munge_rows {
	my $self = shift;
	return Algorithm::Classifier::IsolationForest::munge_rows( $self, @_ );
}

=head1 MODEL SAVE/LOAD METHODS

Persistence keeps the sliding window alongside the trees, so a reloaded
model continues forgetting correctly as the stream resumes.  This makes
saved online models larger than batch models by O(window_size *
n_features).  Perl's RNG state is not persisted: a save/reload point
breaks bit-for-bit reproducibility of subsequent learning versus an
uninterrupted run, though scoring of the reloaded model is exact.

=head2 to_json

Returns a JSON representation of the model.

    my $json = $oif->to_json;

=cut

sub to_json {
	my ($self) = @_;
	my $payload = {
		format  => 'Algorithm::Classifier::IsolationForest::Online',
		version => 1,
		params  => {
			n_trees               => $self->{n_trees},
			window_size           => $self->{window_size},
			max_leaf_samples      => $self->{max_leaf_samples},
			growth                => $self->{growth},
			subsample             => $self->{subsample},
			contamination         => $self->{contamination},
			threshold             => $self->{threshold},
			n_features            => $self->{n_features},
			missing               => $self->{missing},
			feature_names         => $self->{feature_names},
			seen                  => $self->{seen},
			mungers               => $self->{mungers},
			munger_module_version => $self->{munger_module_version},
			schema_version        => $self->{schema_version},
			schema_description    => $self->{schema_description},
			feature_descriptions  => $self->{feature_descriptions},
		},
		trees  => [ map { { count => $_->{count}, root => $_->{root} } } @{ $self->{trees} } ],
		window => $self->{window},
	};
	return JSON::PP->new->canonical(1)->encode($payload);
} ## end sub to_json

=head2 from_json($json)

Init the object from the model in the specified JSON string.

    my $oif = Algorithm::Classifier::IsolationForest::Online->from_json($json);

=cut

sub from_json {
	my ( $class, $text ) = @_;
	my $payload = JSON::PP->new->decode($text);
	croak "not an online IsolationForest model"
		unless ref $payload eq 'HASH'
		&& defined $payload->{format}
		&& $payload->{format} eq 'Algorithm::Classifier::IsolationForest::Online';

	my $p = $payload->{params} || {};

	my $self = {
		n_trees          => $p->{n_trees},
		window_size      => $p->{window_size} // 0,
		max_leaf_samples => $p->{max_leaf_samples},
		growth           => $p->{growth}    // 'adaptive',
		subsample        => $p->{subsample} // 1.0,
		seed             => undef,
		contamination    => $p->{contamination},
		threshold        => $p->{threshold},
		n_features       => $p->{n_features},
		missing          => $p->{missing} // 'die',
		feature_names    => $p->{feature_names},
		# Recompiled lazily on first tagged use, like the parent.
		mungers               => $p->{mungers},
		munger_module_version => $p->{munger_module_version},
		# Opaque schema metadata; absent in models saved before prototype
		# support, which just means "none recorded".
		schema_version       => $p->{schema_version},
		schema_description   => $p->{schema_description},
		feature_descriptions => $p->{feature_descriptions},
		seen                 => $p->{seen}         // 0,
		window               => $payload->{window} // [],
		trees                => [],
		_use_c               => $Algorithm::Classifier::IsolationForest::HAS_C,
		_use_openmp          => $Algorithm::Classifier::IsolationForest::HAS_OPENMP,
	};

	my $trees = $payload->{trees};
	croak "model contains no trees" unless ref $trees eq 'ARRAY' && @$trees;

	my $model = bless $self, $class;

	# depth_limit is a pure function of the tree's count, so recompute it
	# rather than trusting a stored float.
	$self->{trees}
		= [ map { { count => $_->{count}, root => $_->{root}, depth_limit => $model->_rpl( $_->{count} ) } } @$trees ];

	return $model;
} ## end sub from_json

=head2 save($path)

Saves the model to the specified path.

    $oif->save($path);

=cut

sub save {
	my ( $self, $path ) = @_;
	write_file( $path, { 'atomic' => 1 }, $self->to_json );
}

=head2 load($path)

Init the object from the model in the specified file.

    my $oif = Algorithm::Classifier::IsolationForest::Online->load($path);

=cut

sub load {
	my ( $class, $path ) = @_;
	my $raw_model = read_file($path);
	return $class->from_json($raw_model);
}

=head2 to_prototype

Returns a prototype JSON string extracted from this model: its variable
schema (feature_names, feature_descriptions, mungers, missing policy)
plus its current tuning knobs, with C<"class": "online">.  Identical
semantics to the parent class's method -- see PROTOTYPES in
L<Algorithm::Classifier::IsolationForest> for the file format and the
croak/placeholder rules.  C<seed> is not emitted; pass it as an override
when creating from the prototype.

    my $proto_json = $oif->to_prototype;

=cut

sub to_prototype {
	my ($self) = @_;
	croak "to_prototype: this model has no feature_names; a prototype's variable " . "schema needs named features"
		unless ref $self->{feature_names} eq 'ARRAY' && @{ $self->{feature_names} };

	my $schema = {
		feature_names => $self->{feature_names},
		missing       => $self->{missing},
	};
	$schema->{feature_descriptions} = $self->{feature_descriptions}
		if ref $self->{feature_descriptions} eq 'HASH' && %{ $self->{feature_descriptions} };
	$schema->{mungers} = $self->{mungers}
		if ref $self->{mungers} eq 'HASH' && %{ $self->{mungers} };

	my $params = {
		n_trees          => $self->{n_trees},
		window_size      => $self->{window_size},
		max_leaf_samples => $self->{max_leaf_samples},
		growth           => $self->{growth},
		subsample        => $self->{subsample},
	};
	$params->{contamination} = $self->{contamination} if defined $self->{contamination};

	return JSON::PP->new->canonical(1)->encode(
		{
			format             => 'Algorithm::Classifier::IsolationForest::Prototype',
			version            => 1,
			class              => 'online',
			schema_version     => $self->{schema_version} // '0',
			schema_description => $self->{schema_description}
				// '(none recorded; describe this schema and bump schema_version)',
			schema => $schema,
			params => $params,
		}
	);
} ## end sub to_prototype

=head1 REFERENCES

Filippo Leveni, Guilherme Weigert Cassales, Bernhard Pfahringer, Albert
Bifet, Giacomo Boracchi (2024). Online Isolation Forest.

L<https://arxiv.org/abs/2505.09593>

L<https://github.com/ineveLoppiliF/Online-Isolation-Forest>

L<https://proceedings.mlr.press/v235/leveni24a.html>

=cut

###
###
### internal stuff below
###
###

sub _check_learned {
	my ($self) = @_;
	croak "model has not learned any data yet; call learn() first"
		unless $self->{seen} > 0;
}

# Validate one incoming sample, apply the missing-value strategy, and
# return a fresh dense copy (the window owns its rows; the caller may
# reuse or mutate the original).  Locks in n_features on first contact.
sub _prep_row {
	my ( $self, $row, $caller ) = @_;
	croak "$caller: each sample must be an arrayref of features"
		unless ref $row eq 'ARRAY' && @$row;

	if ( !defined $self->{n_features} ) {
		$self->{n_features} = scalar @$row;
	} elsif ( scalar @$row != $self->{n_features} ) {
		croak "$caller: sample has " . scalar(@$row) . " features but model expects " . $self->{n_features};
	}

	if ( $self->{missing} eq 'die' ) {
		for my $f ( 0 .. $#$row ) {
			next if defined $row->[$f];
			croak "$caller: undef feature value at column $f; "
				. "construct with missing => 'zero' to learn from data with missing values";
		}
		return [@$row];
	}

	# zero: a missing cell counts as the value 0.
	return [ map { $_ // 0 } @$row ];
} ## end sub _prep_row

# The depth budget for n points: how deep a tree fed n points is allowed
# (learn) or expected (scoring normalisation, per-leaf adjustment) to
# go.  log base 4 = log(2 * branching_factor) with binary trees.  Under
# max_leaf_samples points there is nothing to isolate: 0.
sub _rpl {
	my ( $self, $n ) = @_;
	my $eta = $self->{max_leaf_samples};
	return 0 if $n < $eta;
	return log( $n / $eta ) / _LOG4;
}

# How many points a node at $depth needs before it may split (or below
# which, on forgetting, it collapses back into a leaf).
sub _split_threshold {
	my ( $self, $depth ) = @_;
	return $self->{max_leaf_samples} * ( $self->{growth} eq 'adaptive' ? 2**$depth : 1 );
}

# Number of points the model currently reflects: the window fill, or the
# whole stream when forgetting is disabled.
sub _data_size {
	my ($self) = @_;
	return $self->{window_size} ? scalar @{ $self->{window} } : $self->{seen};
}

# exp() multiplier turning a per-sample depth SUM into the normalised
# anomaly score: 2**(-(sum/t)/norm) == exp(-sum * log(2)/(t*norm)).
# _EPS keeps a zero normaliser (fewer than max_leaf_samples points seen)
# well-defined; every depth is 0 then, so everything scores 1.0.
sub _score_inv {
	my ($self) = @_;
	my $norm = $self->_rpl( $self->_data_size * $self->{subsample} );
	return _LOG2 / ( $self->{n_trees} * ( $norm + _EPS ) );
}

#-------------------------------------------------------------------------------
# Learning.
#-------------------------------------------------------------------------------

# Advance the stream by one (already prepped) row: every tree learns it
# (subject to subsampling), it enters the window, and the oldest point
# beyond the window is forgotten.  This is the single choke point through
# which every tree mutation flows, so it is also where the packed C
# scoring snapshot gets invalidated.
#
# With use_c the per-tree learn and eviction loops run inside the
# parent's C backend (online_learn_row_xs / online_unlearn_row_xs),
# mutating the same live trees this file's Perl recursion would.  Random
# draws go through the same generator in the same order, so the trees
# built are bit-identical either way (on nvsize == 8 perls) -- use_c
# only changes speed, matching fit()'s guarantee.
sub _learn_row {
	my ( $self, $r ) = @_;
	my $sub = $self->{subsample};

	$self->_invalidate_c_trees;

	if ( _HAS_ONLINE_XS && $self->{_use_c} ) {
		Algorithm::Classifier::IsolationForest::online_learn_row_xs(
			$self->{trees}, $r, $self->{n_features},
			$self->{max_leaf_samples},
			( $self->{growth} eq 'adaptive' ? 1 : 0 ), $sub
		);
	} else {
		for my $tree ( @{ $self->{trees} } ) {
			next if $sub < 1 && rand() >= $sub;
			$self->_tree_learn( $tree, $r );
		}
	}
	$self->{seen}++;

	if ( $self->{window_size} ) {
		push @{ $self->{window} }, $r;
		if ( @{ $self->{window} } > $self->{window_size} ) {
			my $old = shift @{ $self->{window} };
			if ( _HAS_ONLINE_XS && $self->{_use_c} ) {
				Algorithm::Classifier::IsolationForest::online_unlearn_row_xs(
					$self->{trees}, $old, $self->{n_features},
					$self->{max_leaf_samples},
					( $self->{growth} eq 'adaptive' ? 1 : 0 ), $sub
				);
			} else {
				for my $tree ( @{ $self->{trees} } ) {
					next if $sub < 1 && rand() >= $sub;
					$self->_tree_unlearn( $tree, $old );
				}
			}
		} ## end if ( @{ $self->{window} } > $self->{window_size...})
	} ## end if ( $self->{window_size} )
	return;
} ## end sub _learn_row

sub _tree_learn {
	my ( $self, $tree, $x ) = @_;
	$tree->{count}++;
	$tree->{depth_limit} = $self->_rpl( $tree->{count} );
	if ( !defined $tree->{root} ) {
		$tree->{root} = [ _NT_LEAF, 1, [@$x], [@$x] ];
	} else {
		$tree->{root} = $self->_node_learn( $tree->{root}, $x, 0, $tree->{depth_limit} );
	}
	return;
} ## end sub _tree_learn

# Route $x down to its leaf, growing counts and bounding boxes along the
# path.  A leaf that has accumulated its split requirement (and still has
# depth budget) is replaced by a subtree built from synthetic points
# sampled inside its box -- the return value replaces the node in the
# parent, which is how leaves turn into subtrees in place.
sub _node_learn {
	my ( $self, $node, $x, $depth, $limit ) = @_;

	$node->[_N_COUNT]++;
	if ( !defined $node->[_N_LO] ) {

		# Leaf born from an empty synthetic partition: first real point
		# initialises the box.
		$node->[_N_LO] = [@$x];
		$node->[_N_HI] = [@$x];
	} else {
		my ( $lo, $hi ) = ( $node->[_N_LO], $node->[_N_HI] );
		for my $f ( 0 .. $#$x ) {
			my $v = $x->[$f];
			$lo->[$f] = $v if $v < $lo->[$f];
			$hi->[$f] = $v if $v > $hi->[$f];
		}
	}

	if ( $node->[_N_TYPE] == _NT_LEAF ) {
		if ( $node->[_N_COUNT] >= $self->_split_threshold($depth) && $depth < $limit ) {
			my $pts = $self->_sample_box( $node->[_N_LO], $node->[_N_HI], $node->[_N_COUNT] );
			return $self->_build_from_points( $pts, $depth, $limit );
		}
		return $node;
	}

	my $ci = $x->[ $node->[_N_ATTR] ] < $node->[_N_SPLIT] ? _N_LEFT : _N_RIGHT;
	$node->[$ci] = $self->_node_learn( $node->[$ci], $x, $depth + 1, $limit );
	return $node;
} ## end sub _node_learn

# $n synthetic points drawn uniformly inside the box -- the stand-in for
# the real points the tree never stored.
sub _sample_box {
	my ( $self, $lo, $hi, $n ) = @_;
	my @pts;
	for ( 1 .. $n ) {
		push @pts, [ map { my $w = $hi->[$_] - $lo->[$_]; $w > 0 ? $lo->[$_] + rand() * $w : $lo->[$_] } 0 .. $#$lo ];
	}
	return \@pts;
}

# Recursively build a subtree over (synthetic) points: random feature,
# uniform split value within the points' range on it, recurse on the
# partitions.  Leaves keep the partition's count and box.
sub _build_from_points {
	my ( $self, $pts, $depth, $limit ) = @_;
	my $n = scalar @$pts;
	my ( $lo, $hi ) = _box_of($pts);

	if ( $n < $self->_split_threshold($depth) || $depth >= $limit ) {
		return [ _NT_LEAF, $n, $lo, $hi ];
	}

	my $attr = int( rand( $self->{n_features} ) );
	my ( $pmin, $pmax ) = ( $pts->[0][$attr], $pts->[0][$attr] );
	for my $p (@$pts) {
		$pmin = $p->[$attr] if $p->[$attr] < $pmin;
		$pmax = $p->[$attr] if $p->[$attr] > $pmax;
	}
	my $split = $pmin + rand() * ( $pmax - $pmin );

	my ( @l, @r );
	for my $p (@$pts) {
		if   ( $p->[$attr] < $split ) { push @l, $p }
		else                          { push @r, $p }
	}

	my $left  = $self->_build_from_points( \@l, $depth + 1, $limit );
	my $right = $self->_build_from_points( \@r, $depth + 1, $limit );
	return [ _NT_AXIS, $n, $lo, $hi, $attr, $split, $left, $right ];
} ## end sub _build_from_points

#-------------------------------------------------------------------------------
# Forgetting.
#-------------------------------------------------------------------------------

sub _tree_unlearn {
	my ( $self, $tree, $x ) = @_;
	$tree->{count}--;
	$tree->{depth_limit} = $self->_rpl( $tree->{count} );
	return unless defined $tree->{root};
	$tree->{root} = $self->_node_unlearn( $tree->{root}, $x, 0 );
	return;
}

# Route the forgotten point down its (current) path, decrementing counts.
# An internal node whose count no longer justifies its split collapses
# back into a leaf; otherwise its box is refreshed to the union of its
# children's, which is how boxes shrink as old extremes age out.
sub _node_unlearn {
	my ( $self, $node, $x, $depth ) = @_;

	$node->[_N_COUNT]--;
	return $node            if $node->[_N_TYPE] == _NT_LEAF;
	return _collapse($node) if $node->[_N_COUNT] < $self->_split_threshold($depth);

	my $ci = $x->[ $node->[_N_ATTR] ] < $node->[_N_SPLIT] ? _N_LEFT : _N_RIGHT;
	$node->[$ci] = $self->_node_unlearn( $node->[$ci], $x, $depth + 1 );

	my ( $lo, $hi ) = _box_union( $node->[_N_LEFT], $node->[_N_RIGHT] );
	if ( defined $lo ) {
		$node->[_N_LO] = $lo;
		$node->[_N_HI] = $hi;
	}
	return $node;
} ## end sub _node_unlearn

# Aggregate a subtree back into a single leaf holding the subtree's
# (already decremented) count and the union of its descendants' boxes.
sub _collapse {
	my ($node) = @_;
	return $node if $node->[_N_TYPE] == _NT_LEAF;
	my $l = _collapse( $node->[_N_LEFT] );
	my $r = _collapse( $node->[_N_RIGHT] );
	my ( $lo, $hi ) = _box_union( $l, $r );
	if ( !defined $lo ) {

		# Both children empty: keep the node's own box.
		( $lo, $hi ) = ( $node->[_N_LO], $node->[_N_HI] );
	}
	return [ _NT_LEAF, $node->[_N_COUNT], $lo, $hi ];
} ## end sub _collapse

# (lo, hi) of the union of two nodes' boxes, as fresh arrays (parent
# boxes grow in place, so they must never alias a child's).  Nodes with
# no box yet (empty leaves) are skipped; (undef, undef) if neither has
# one.
sub _box_union {
	my ( $a, $b ) = @_;
	my @boxed = grep { defined $_->[_N_LO] } ( $a, $b );
	return ( undef, undef ) unless @boxed;
	my $lo = [ @{ $boxed[0][_N_LO] } ];
	my $hi = [ @{ $boxed[0][_N_HI] } ];
	if ( @boxed == 2 ) {
		my ( $blo, $bhi ) = ( $boxed[1][_N_LO], $boxed[1][_N_HI] );
		for my $f ( 0 .. $#$lo ) {
			$lo->[$f] = $blo->[$f] if $blo->[$f] < $lo->[$f];
			$hi->[$f] = $bhi->[$f] if $bhi->[$f] > $hi->[$f];
		}
	}
	return ( $lo, $hi );
} ## end sub _box_union

# (lo, hi) bounding box of a point set; (undef, undef) when empty.
sub _box_of {
	my ($pts) = @_;
	return ( undef, undef ) unless @$pts;
	my $lo = [ @{ $pts->[0] } ];
	my $hi = [ @{ $pts->[0] } ];
	for my $p (@$pts) {
		for my $f ( 0 .. $#$p ) {
			$lo->[$f] = $p->[$f] if $p->[$f] < $lo->[$f];
			$hi->[$f] = $p->[$f] if $p->[$f] > $hi->[$f];
		}
	}
	return ( $lo, $hi );
} ## end sub _box_of

#-------------------------------------------------------------------------------
# Scoring.
#-------------------------------------------------------------------------------

# Depth of the leaf $x lands in, plus the leaf's own depth budget -- the
# streaming analogue of the batch scorer's c(leaf size) adjustment.
# Scoring tolerates undef cells (mapped to 0), matching the parent class.
sub _depth_of {
	my ( $self, $x, $node ) = @_;
	my $depth = 0;
	while ( $node->[_N_TYPE] ) {
		$node = ( $x->[ $node->[_N_ATTR] ] // 0 ) < $node->[_N_SPLIT] ? $node->[_N_LEFT] : $node->[_N_RIGHT];
		$depth++;
	}
	return $depth + $self->_rpl( $node->[_N_COUNT] );
}

# Per-sample depth sums across all trees (tree-outer, sample-inner for
# cache locality, mirroring the parent's pure-Perl loops).
sub _depth_sums {
	my ( $self, $data ) = @_;
	my @sums = (0) x @$data;
	for my $tree ( @{ $self->{trees} } ) {
		my $root = $tree->{root};
		next unless defined $root;
		for my $i ( 0 .. $#$data ) {
			$sums[$i] += $self->_depth_of( $data->[$i], $root );
		}
	}
	return \@sums;
} ## end sub _depth_sums

# Single-row score against the current model state; used by the
# prequential score_learn loop, where the normaliser moves as points are
# learned and so must be recomputed per row.
sub _score_row {
	my ( $self, $r ) = @_;
	if ( _HAS_ONLINE_XS && $self->{_use_c} ) {

		# Walks the live trees in C -- no packed snapshot involved, so
		# this stays fast even though score_learn mutates the trees
		# between rows.
		my $sum = Algorithm::Classifier::IsolationForest::online_score_row_xs( $self->{trees}, $r,
			$self->{n_features}, $self->{max_leaf_samples} );
		return exp( -$sum * $self->_score_inv );
	}
	my $sum = 0;
	for my $tree ( @{ $self->{trees} } ) {
		$sum += $self->_depth_of( $r, $tree->{root} ) if defined $tree->{root};
	}
	return exp( -$sum * $self->_score_inv );
} ## end sub _score_row

#-------------------------------------------------------------------------------
# C-accelerated scoring.
#
# The parent class's Inline::C scorer walks immutable packed node buffers;
# online trees mutate on every learned point.  The bridge is a lazily
# built snapshot: the first scoring call after any mutation flattens the
# live trees into the parent's packed node layout (below) and every
# scoring call until the next mutation reuses it.  _learn_row -- the one
# choke point all mutations flow through -- drops the snapshot.
#
# Online trees are axis-only, so they map onto the parent's 6-double node
# records directly:
#
#   leaf:  [0, count, _rpl(count), 0, 0, 0]
#   axis:  [1, attr,  split,       li, ri, 0]
#
# The parent packs c(leaf size) into slot 2 and its C walker returns
# depth + slot2 at a leaf; packing the online depth-budget adjustment
# _rpl(count) there instead makes score_all_xs compute exactly the
# pure-Perl _depth_of value, so every downstream C helper (finalize_*,
# predict_sums_xs, score_predict_*) applies unchanged.  The per-tree
# coefficient buffers are empty -- there are no oblique nodes -- and only
# exist because score_all_xs expects them.
#
# score_learn deliberately never uses this path: it mutates the trees
# after every single point, so the snapshot could never be reused and
# repacking per point would cost more than the walks it replaces.
#-------------------------------------------------------------------------------

# Drop the packed snapshot; called on every mutation.
sub _invalidate_c_trees {
	delete @{ $_[0] }{qw(_c_nodes _c_coef_idx _c_coef_val)};
	return;
}

# Build (or reuse) the packed snapshot.  Returns true when the C scoring
# path may be taken, false when the caller must use the pure-Perl walk.
sub _ensure_c_trees {
	my ($self) = @_;
	return 0 unless $self->{_use_c};
	return 1 if $self->{_c_nodes};

	my ( @c_nodes, @c_coef_idx, @c_coef_val );
	my $empty_idx = pack('l*');
	my $empty_val = pack('d*');
	for my $tree ( @{ $self->{trees} } ) {
		push @c_nodes,    $self->_pack_online_tree( $tree->{root} );
		push @c_coef_idx, $empty_idx;
		push @c_coef_val, $empty_val;
	}
	$self->{_c_nodes}    = \@c_nodes;
	$self->{_c_coef_idx} = \@c_coef_idx;
	$self->{_c_coef_val} = \@c_coef_val;
	return 1;
} ## end sub _ensure_c_trees

# Flatten one live tree into the parent's packed node buffer (DFS
# pre-order, root at index 0 -- the origin score_all_xs walks from).
sub _pack_online_tree {
	my ( $self, $root ) = @_;

	# A tree that has not learned anything walks as depth 0 with a zero
	# adjustment: one empty leaf record.
	return pack( 'd*', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 ) unless defined $root;

	my @node_data;
	my $assign;
	$assign = sub {
		my ($node) = @_;
		my $my_idx = scalar @node_data;
		push @node_data, undef;    # reserve slot; filled in after children
		if ( $node->[_N_TYPE] == _NT_LEAF ) {
			$node_data[$my_idx]
				= [ 0.0, $node->[_N_COUNT] + 0.0, $self->_rpl( $node->[_N_COUNT] ) + 0.0, 0.0, 0.0, 0.0 ];
		} else {
			my $li = $assign->( $node->[_N_LEFT] );
			my $ri = $assign->( $node->[_N_RIGHT] );
			$node_data[$my_idx]
				= [ 1.0, $node->[_N_ATTR] + 0.0, $node->[_N_SPLIT] + 0.0, $li + 0.0, $ri + 0.0, 0.0 ];
		}
		return $my_idx;
	}; ## end $assign = sub
	$assign->($root);
	return pack( 'd*', map { @$_ } @node_data );
} ## end sub _pack_online_tree

# Pack the query rows into the row-major double buffer score_all_xs
# reads, via the parent's C row walker.  miss_mode 0 maps an undef cell
# to 0.0, matching the pure-Perl walk's "// 0".
sub _pack_input {
	my ( $self, $data ) = @_;
	my $n_pts    = scalar @$data;
	my $nf       = $self->{n_features};
	my $x_packed = "\0" x ( $n_pts * $nf * 8 );
	Algorithm::Classifier::IsolationForest::pack_input_xs( $data, $x_packed, $n_pts, $nf, 0, '' );
	return ( $n_pts, $x_packed );
}

# Lazily learn the contamination threshold from the current window the
# first time a predict-family method needs it.  A model with no retained
# window (window_size 0) stays on the 0.5 fallback until the caller runs
# relearn_threshold with data.
sub _ensure_threshold {
	my ($self) = @_;
	return
		   if !defined $self->{contamination}
		|| defined $self->{threshold}
		|| !@{ $self->{window} };
	$self->relearn_threshold;
	return;
}

1;
