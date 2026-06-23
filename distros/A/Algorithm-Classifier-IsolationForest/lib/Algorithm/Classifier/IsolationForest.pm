package Algorithm::Classifier::IsolationForest;

use strict;
use warnings;
use Carp        qw(croak);
use List::Util  qw(min);
use POSIX       qw(ceil);
use JSON::PP    ();
use File::Slurp qw(read_file write_file);

our $VERSION = '0.1.0';

use constant EULER  => 0.5772156649015329;
use constant TWO_PI => 6.283185307179586;

=head1 NAME

Algorithm::Classifier::IsolationForest - unsupervised anomaly detection via Isolation Forest or Extended Isolation Forest

=head1 SYNOPSIS

    use Algorithm::Classifier::IsolationForest;

    my @data = ([0.1, -0.2], [0.0, 0.1], [5.0, 6.0], ...);

    # Classic, axis-parallel Isolation Forest
    my $iforest = Algorithm::Classifier::IsolationForest->new(
        n_trees     => 100,
        sample_size => 256,
        seed        => 42,
    );
    $iforest->fit(\@data);

    my $scores = $iforest->score_samples(\@data);  # arrayref, each in (0,1]
    my $flags  = $iforest->predict(\@data, 0.6);    # arrayref of 0/1

    # Save and reload
    $iforest->save('model.json');
    my $reloaded = Algorithm::Classifier::IsolationForest->load('model.json');

    # Extended Isolation Forest (oblique hyperplane splits)
    my $eif = IsolationForest->new(mode => 'extended', seed => 42);
    $eif->fit(\@data);

=head1 DESCRIPTION

Isolation Forest (Liu, Fei Tony & Ting, Kai & Zhou, Zhi-Hua, 2008) detects anomalies by random
partitioning rather than by modelling normal points. Each tree repeatedly
splits the data. Points that get isolated after only a few splits are likely
anomalies. The score is the average isolation depth across many trees,
normalised so values approach 1 for anomalies and stay below 0.5 for normal
points.

In extended mode the module implements the Extended Isolation Forest
variant. Each split is a random hyperplane instead of an axis-aligned cut,
which removes the rectangular, axis-aligned bias in the score field and
tends to help on elongated or multi-modal data.

psi refernced below is ψ or the pitchfork math symbol refrenced in paper,
Liu, Fei Tony & Ting, Kai & Zhou, Zhi-Hua. (2008). Isolation Forest. 413 - 422. 10.1109/ICDM.2008.17.

... or max samples.

L<https://www.researchgate.net/publication/224384174_Isolation_Forest>

=head1 GENERAL METHODS

=head2 new(%args)

Inits the object.

  - n_trees :: number of isolation trees in the ensemble
      default :: 100

  - sample_size :: sub-sample size used to build each tree... max samples
      default :: 256

   - max_depth :: per-tree height limit... if not defined is set to ceil(log2(psi))
       default :: undef

   - seed :: optional integer to seed srand with for reproducible trees...
           see perldoc -f srand for more info. This number is processed via abs(int()).
       default :: undef

   - mode :: if it should be IF or EIF
        axis :: classic axis-parallel splits (IF)
        extended :: oblique hyperplane splits (EIF)
      default :: axis

   - extension_level :: extended mode only... how many features take partin each
           split. 0 behaves like a single-feature (axis) cut; the
           maximum (n_features - 1) uses every varying feature. undef
           => maximum. Clamped to [0, n_features - 1] at fit time.

    - contamination :: expected fraction of anomalies, in (0, 0.5]. When given,
          fit() learns a score threshold that flags this fraction of
          the training set, and predict() uses it by default. undef
          => no learned threshold (predict() falls back to 0.5).
        default :: undef

Note: log2 under Perl is as below...

    log($psi) / log(2)

=cut

sub new {
	my ( $class, %args ) = @_;

	my $mode = $args{mode} // 'axis';
	croak "mode must be 'axis' or 'extended'"
		unless $mode eq 'axis' || $mode eq 'extended';

	if ( defined( $args{seed} ) ) {
		$args{seed} = abs( int( $args{seed} ) );
	}

	my $self = {
		n_trees         => $args{n_trees}     // 100,
		sample_size     => $args{sample_size} // 256,
		max_depth       => $args{max_depth},          # undef => auto
		seed            => $args{seed},               # undef => non-deterministic
		mode            => $mode,
		extension_level => $args{extension_level},    # undef => max, resolved in fit()
		contamination   => $args{contamination},      # undef => no learned threshold
		threshold       => undef,                     # learned in fit() if contamination set
		trees           => [],
		c_psi           => undef,                     # c(psi), set during fit()
		n_features      => undef,
	};

	croak "n_trees must be >= 1"     unless $self->{n_trees} >= 1;
	croak "sample_size must be >= 1" unless $self->{sample_size} >= 1;
	croak "extension_level must be >= 0"
		if defined $self->{extension_level} && $self->{extension_level} < 0;
	croak "contamination must be a number in (0, 0.5]"
		if defined $self->{contamination}
		&& !( $self->{contamination} > 0 && $self->{contamination} <= 0.5 );

	return bless $self, $class;
} ## end sub new

=head2 decision_threshold

The score cutoff C<predict> uses by default; undef unless C<contamination> was
set.

=cut

sub decision_threshold { return $_[0]->{threshold} }

=head2 fit

Trains the model on the specified data.

The data taken is a array of arrays, with each sub array containing two numbers.

    @training_data = (
        [ 3, 5 ],
        [ 2.3, 1 ],
        [ 5, 9 ],
        ...
    );

Below shows a example of building a gausing cluster and using that for training.

    # so it is reproducible
    srand(7);

    # build a gaussian cluster and add a handful out outliers...

    use constant PI => 3.14159265358979;
    sub gaussian {
        my ($mu, $sigma) = @_;
        my $u1 = rand() || 1e-12;
        my $u2 = rand();
        my $z  = sqrt(-2 * log($u1)) * cos(2 * PI * $u2);
        return $mu + $sigma * $z;
    }

    # add some normal items
    for (1 .. 500) {
        push @data,  [ gaussian(0, 1), gaussian(0, 1) ];
        push @truth, 0;
    }
    # add some outliers
    for (1 .. 20) {
        my $angle  = rand() * 2 * PI;
        my $radius = 5 + rand() * 3;             # distance 5..8 from the origin
        push @data,  [ $radius * cos($angle), $radius * sin($angle) ];
        push @truth, 1;
    }

    $iforest->fit(\@training_data);

=cut

sub fit {
	my ( $self, $data ) = @_;

	croak "fit() expects a non-empty arrayref of samples"
		unless ref $data eq 'ARRAY' && @$data;
	croak "each sample must be an arrayref of features"
		unless ref $data->[0] eq 'ARRAY' && @{ $data->[0] };

	my $n          = scalar @$data;
	my $n_features = scalar @{ $data->[0] };
	$self->{n_features} = $n_features;

	# The sub-sample cannot be larger than the data set itself.
	my $psi = min( $self->{sample_size}, $n );
	$self->{c_psi}    = _c($psi);
	$self->{psi_used} = $psi;

	# Resolve the extension level against the data's dimensionality.
	if ( $self->{mode} eq 'extended' ) {
		my $max_ext = $n_features - 1;
		my $ext
			= defined $self->{extension_level}
			? $self->{extension_level}
			: $max_ext;
		$ext                          = 0        if $ext < 0;
		$ext                          = $max_ext if $ext > $max_ext;
		$self->{extension_level_used} = $ext;
	} else {
		$self->{extension_level_used} = undef;
	}

	# Height limit: the average tree height ceil(log2(psi)). Past this depth the
	# remaining points are scored using the c(size) adjustment instead.
	my $limit
		= defined $self->{max_depth}
		? $self->{max_depth}
		: ceil( log($psi) / log(2) );
	$limit = 1 if $limit < 1;
	$self->{max_depth_used} = $limit;

	srand( $self->{seed} ) if defined $self->{seed};

	my @trees;
	for ( 1 .. $self->{n_trees} ) {
		my $sample = _subsample( $data, $psi );
		push @trees, $self->_build_tree( $sample, 0, $limit );
	}
	$self->{trees} = \@trees;

	# If a contamination rate was requested, learn the score cutoff that flags
	# that fraction of the training set. We place the threshold midway between
	# the k-th and (k+1)-th highest training scores, so it sits in the gap
	# between flagged and unflagged points -- unambiguous and robust to the
	# tiny float rounding introduced by JSON serialisation.
	if ( defined $self->{contamination} ) {
		my $scores = $self->score_samples($data);
		my @desc   = sort { $b <=> $a } @$scores;
		my $n_pts  = scalar @desc;
		my $k      = int( $self->{contamination} * $n_pts + 0.5 );
		$k                 = 1      if $k < 1;
		$k                 = $n_pts if $k > $n_pts;
		$self->{threshold} = $k < $n_pts
			? ( $desc[ $k - 1 ] + $desc[$k] ) / 2.0    # midpoint of the boundary
			: $desc[ $n_pts - 1 ] - 1e-9;              # k == n: flag everything
	} ## end if ( defined $self->{contamination} )

	return $self;
} ## end sub fit

=head2 path_lengths(\@data)

Returns the mean isolation depth per sample, for inspection.

    my @lenghts = $forest->path_lengths(\@data);

    print "x, y, length\n";

    my $int=0;
    while (defined($data[$int])) {
        print $data[$int][0].', '.$data[$int][1].', '.$lenghts[$int]."\n";

        $int++;
    }

=cut

sub path_lengths {
	my ( $self, $data ) = @_;
	$self->_check_fitted;
	my $t = scalar @{ $self->{trees} };
	my @out;
	for my $x (@$data) {
		my $sum = 0;
		$sum += $self->_path_length( $x, $_, 0 ) for @{ $self->{trees} };
		push @out, $sum / $t;
	}
	return \@out;
} ## end sub path_lengths

=head predict(\@data, $threshold)

Returns an arrayref of 0/1 labels for the specified data.

If theshold is not specified it uses whatever the set default.

    my $results = $forest->predict(\@data, $threshold);

    print "x, y, result\n";

    my $int=0;
    while (defined($data[$int])) {
        print $data[$int][0].', '.$data[$int][1].', '.$results->[$int]."\n";

        $int++;
    }

=cut

sub predict {
	my ( $self, $data, $threshold ) = @_;
	$threshold
		= defined $threshold         ? $threshold
		: defined $self->{threshold} ? $self->{threshold}
		:                              0.5;
	my $scores = $self->score_samples($data);
	return [ map { $_ >= $threshold ? 1 : 0 } @$scores ];
}

=head2 score_samples(\@data)

Returns an arrayref of anomaly scores, between 0 and 1.

Scores near 1 are strong anomalies (isolated quickly).

Scores well below 0.5 are normal.

Scores ~0.5 means the points are hard to tell apart.

    my $scores = $forest->path_lengths(\@data);

    print "x, y, length\n";

    my $int=0;
    while (defined($data[$int])) {
        print $data[$int][0].', '.$data[$int][1].', '.$scores->[$int]."\n";

        $int++;
    }

=cut

sub score_samples {
	my ( $self, $data ) = @_;
	$self->_check_fitted;
	my $c = $self->{c_psi};
	my $t = scalar @{ $self->{trees} };

	my @scores;
	for my $x (@$data) {
		my $sum = 0;
		$sum += $self->_path_length( $x, $_, 0 ) for @{ $self->{trees} };
		my $avg = $sum / $t;
		push @scores, $c > 0 ? 2**( -$avg / $c ) : 0.5;
	}
	return \@scores;
} ## end sub score_samples

=head2 score_predict_samples

Returns a array ref of arrays. First value of each sub array is the score with the second being
0/1 for if it is a anomaly or not.

    my $results = $forest->predict(\@data, $threshold);

    print "x, y, score, result\n";

    my $int=0;
    while (defined($data[$int])) {
        print $data[$int][0].', '.$data[$int][1].', '.$results->[$int][0].', '.$results->[$int][1]."\n";

        $int++;
    }

=cut

sub score_predict_samples {
	my ( $self, $data, $threshold ) = @_;
	$threshold
		= defined $threshold         ? $threshold
		: defined $self->{threshold} ? $self->{threshold}
		:                              0.5;
	my $scores = $self->score_samples($data);

	my @to_return;
	foreach my $score ( @{$scores} ) {
		if ( $score >= $threshold ) {
			push @to_return, [ $score, 1 ];
		} else {
			push @to_return, [ $score, 0 ];
		}
	}

	return \@to_return;
} ## end sub score_predict_samples

=head1 MODEL SAVE/LOAD METHODS

=head2 to_json

Returns a JSON representation of the module.

Required being fit having to be called.

    my $json = $iforest->to_json;

=cut

sub to_json {
	my ($self) = @_;
	$self->_check_fitted;
	my $payload = {
		format  => 'Algorithm::Classifier::IsolationForest',
		version => 0,
		params  => {
			n_trees         => $self->{n_trees},
			sample_size     => $self->{sample_size},
			mode            => $self->{mode},
			extension_level => $self->{extension_level_used},
			contamination   => $self->{contamination},
			threshold       => $self->{threshold},
			n_features      => $self->{n_features},
			psi_used        => $self->{psi_used},
			c_psi           => $self->{c_psi},
			max_depth_used  => $self->{max_depth_used},
		},
		trees => $self->{trees},
	};
	return JSON::PP->new->canonical(1)->encode($payload);
} ## end sub to_json

=head2 from_json($json)

Init the object from the model in the specified JSON string.

    my $iforest = Algorithm::Classifier::IsolationForest->from_json($json);

=cut

sub from_json {
	my ( $class, $text ) = @_;
	my $payload = JSON::PP->new->decode($text);
	croak "not an IsolationForest model"
		unless ref $payload eq 'HASH'
		&& defined $payload->{format}
		&& $payload->{format} eq 'Algorithm::Classifier::IsolationForest';

	my $p    = $payload->{params} || {};
	my $self = {
		n_trees              => $p->{n_trees},
		sample_size          => $p->{sample_size},
		max_depth            => undef,
		seed                 => undef,
		mode                 => $p->{mode} // 'axis',
		extension_level      => $p->{extension_level},
		extension_level_used => $p->{extension_level},
		contamination        => $p->{contamination},
		threshold            => $p->{threshold},
		n_features           => $p->{n_features},
		psi_used             => $p->{psi_used},
		c_psi                => $p->{c_psi},
		max_depth_used       => $p->{max_depth_used},
		trees                => $payload->{trees} || [],
	};
	croak "model contains no trees" unless @{ $self->{trees} };

	# Recompute the normalising constant from the (integer, exact) sub-sample
	# size rather than trusting the stored float, so a reloaded model's scores
	# are bit-for-bit identical to the original's.
	$self->{c_psi} = _c( $self->{psi_used} ) if defined $self->{psi_used};

	return bless $self, $class;
} ## end sub from_json

=head2 save($path)

Saves the model to the specified path.

    $iforest->save($path);

=cut

sub save {
	my ( $self, $path ) = @_;
	write_file( $path, { 'atomic' => 1 }, $self->to_json );
}

=head2 load($path);

Init the object from the model in the specified file.

    my $iforest = Algorithm::Classifier::IsolationForest->load($path);

=cut

sub load {
	my ( $class, $path ) = @_;
	my $raw_model = read_file($path);
	return $class->from_json($raw_model);
}

=head1 REFERENCES

Liu, Fei Tony & Ting, Kai & Zhou, Zhi-Hua. (2008). Isolation Forest. 413 - 422. 10.1109/ICDM.2008.17.

L<https://www.researchgate.net/publication/224384174_Isolation_Forest>

L<https://ieeexplore.ieee.org/abstract/document/4781136>

Sahand Hariri, Matias Carrasco Kind, Robert J. Brunner (2020). Extended Isolation Forest. 1479 - 1489. 10.1109/TKDE.2019.2947676

L<https://ieeexplore.ieee.org/document/8888179>

=cut

###
###
### internal stuff below
###
###

#-------------------------------------------------------------------------------
# c(n): the expected path length of an unsuccessful search in a binary search
# tree of n nodes. Isolation Forest uses it (a) to adjust the path length when a
# leaf still holds more than one point (depth limit reached), and (b) to
# normalise the average path length into a 0..1 anomaly score.
#-------------------------------------------------------------------------------
sub _c {
	my ($n) = @_;
	return 0.0 if $n <= 1;
	return 1.0 if $n == 2;
	my $harmonic = log( $n - 1 ) + EULER;    # H(n-1) ~= ln(n-1) + gamma
	return 2.0 * $harmonic - ( 2.0 * ( $n - 1 ) / $n );
}

# One draw from the standard normal N(0,1) via Box-Muller. Used to pick the
# random hyperplane orientations in Extended Isolation Forest mode.
sub _randn {
	my $u1 = rand() || 1e-12;
	my $u2 = rand();
	return sqrt( -2.0 * log($u1) ) * cos( TWO_PI * $u2 );
}

#-------------------------------------------------------------------------------
# Draw $k samples without replacement via a partial Fisher-Yates shuffle of the
# index array. Returns an arrayref of (shared, read-only) sample refs.
#-------------------------------------------------------------------------------
sub _subsample {
	my ( $data, $k ) = @_;
	my $n   = scalar @$data;
	my @idx = ( 0 .. $n - 1 );
	for my $i ( 0 .. $k - 1 ) {
		my $j = $i + int( rand( $n - $i ) );
		@idx[ $i, $j ] = @idx[ $j, $i ];
	}
	my @chosen = @idx[ 0 .. $k - 1 ];
	return [ @{$data}[@chosen] ];
} ## end sub _subsample

#-------------------------------------------------------------------------------
# Recursively build one isolation tree.
#
# A node is one of:
#   leaf     { leaf => 1, size => N }
#   axis     { attr => A, split => S,            left => ..., right => ... }
#   oblique  { idx => [..], coef => [..], b => B, left => ..., right => ... }
#
# In both split styles the choice is restricted to features that actually vary
# across the points reaching the node: this avoids wasted levels on constant
# columns and lets a node leaf out exactly when its points are indistinguishable.
#-------------------------------------------------------------------------------
sub _build_tree {
	my ( $self, $X, $depth, $limit ) = @_;

	my $size = scalar @$X;
	return { leaf => 1, size => $size }
		if $depth >= $limit || $size <= 1;

	my $nf = $self->{n_features};

	# Per-feature min and max within this node, in a single pass.
	my ( @lo, @hi );
	for my $row (@$X) {
		for my $f ( 0 .. $nf - 1 ) {
			my $v = $row->[$f];
			$lo[$f] = $v if !defined $lo[$f] || $v < $lo[$f];
			$hi[$f] = $v if !defined $hi[$f] || $v > $hi[$f];
		}
	}

	# Features with spread are the only ones that can split the data.
	my @varying = grep { $lo[$_] < $hi[$_] } 0 .. $nf - 1;

	# No spread on any feature => all points identical => cannot isolate.
	return { leaf => 1, size => $size } unless @varying;

	my $node
		= $self->{mode} eq 'extended'
		? $self->_oblique_split( $X, \@varying, \@lo, \@hi )
		: _axis_split( $X, \@varying, \@lo, \@hi );

	$node->{left}  = $self->_build_tree( $node->{_left},  $depth + 1, $limit );
	$node->{right} = $self->_build_tree( $node->{_right}, $depth + 1, $limit );
	delete @{$node}{qw(_left _right)};

	return $node;
} ## end sub _build_tree

# Axis-parallel cut: random varying feature, random threshold in its range.
sub _axis_split {
	my ( $X, $varying, $lo, $hi ) = @_;

	my $attr  = $varying->[ int( rand( scalar @$varying ) ) ];
	my $split = $lo->[$attr] + rand() * ( $hi->[$attr] - $lo->[$attr] );

	my ( @left, @right );
	for my $row (@$X) {
		if   ( $row->[$attr] < $split ) { push @left,  $row }
		else                            { push @right, $row }
	}
	return { attr => $attr, split => $split, _left => \@left, _right => \@right };
} ## end sub _axis_split

# Oblique cut (Extended Isolation Forest): a random hyperplane. We activate
# (extension_level + 1) of the varying features, give each a Gaussian
# coefficient, and place the plane through a random point in the bounding box.
# A point goes left when coef . x <= b, where b = coef . p.
sub _oblique_split {
	my ( $self, $X, $varying, $lo, $hi ) = @_;

	my $active = $self->{extension_level_used} + 1;
	$active = scalar @$varying if $active > scalar @$varying;

	# Pick which varying features take part (partial shuffle of their indices).
	my @pool = @$varying;
	for my $i ( 0 .. $active - 1 ) {
		my $j = $i + int( rand( scalar(@pool) - $i ) );
		@pool[ $i, $j ] = @pool[ $j, $i ];
	}
	my @idx = @pool[ 0 .. $active - 1 ];

	my ( @coef, $b );
	$b = 0.0;
	for my $f (@idx) {
		my $c = _randn();
		my $p = $lo->[$f] + rand() * ( $hi->[$f] - $lo->[$f] );    # point in the box
		push @coef, $c;
		$b += $c * $p;
	}

	my ( @left, @right );
	for my $row (@$X) {
		my $dot = 0.0;
		$dot += $coef[$_] * $row->[ $idx[$_] ] for 0 .. $#idx;
		if   ( $dot <= $b ) { push @left,  $row }
		else                { push @right, $row }
	}
	return {
		idx    => \@idx,
		coef   => \@coef,
		b      => $b,
		_left  => \@left,
		_right => \@right
	};
} ## end sub _oblique_split

#-------------------------------------------------------------------------------
# Path length of a single point in a single tree: edges traversed until a leaf,
# plus c(leaf size) when the leaf still holds several points. Handles both axis
# and oblique internal nodes, so a model of either mode scores correctly.
#-------------------------------------------------------------------------------
sub _path_length {
	my ( $self, $x, $node, $depth ) = @_;
	while ( !$node->{leaf} ) {
		my $left;
		if ( exists $node->{attr} ) {    # axis-parallel split
			$left = $x->[ $node->{attr} ] < $node->{split};
		} else {                         # oblique (hyperplane) split
			my ( $idx, $coef ) = ( $node->{idx}, $node->{coef} );
			my $dot = 0.0;
			$dot += $coef->[$_] * $x->[ $idx->[$_] ] for 0 .. $#$idx;
			$left = $dot <= $node->{b};
		}
		$node = $left ? $node->{left} : $node->{right};
		$depth++;
	} ## end while ( !$node->{leaf} )
	return $depth + _c( $node->{size} );
} ## end sub _path_length

sub _check_fitted {
	my ($self) = @_;
	croak "model is not fitted yet; call fit() first"
		unless ref $self->{trees} eq 'ARRAY' && @{ $self->{trees} };
}

1;
