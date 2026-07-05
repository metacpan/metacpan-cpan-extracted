package Algorithm::Classifier::IsolationForest::App::Command::info;

use strict;
use warnings;
use Algorithm::Classifier::IsolationForest ();
use Algorithm::Classifier::IsolationForest::App -command;

sub opt_spec {
	return (
		[
			'm=s',
			'Input model JSON file path/name.',
			{ 'default' => 'iforest_model.json', 'completion' => 'files' }
		],
		[ 'json', 'Emit machine-readable JSON instead of the text table.' ],
	);
} ## end sub opt_spec

sub abstract { 'Show the constructor params, fit-time metadata, and tree stats of a saved model' }

sub description {
	'Loads a saved Algorithm::Classifier::IsolationForest model and prints the
constructor params, fit-time metadata, and a handful of derived tree
statistics (count, average/max depth, total nodes).

Use --json for a machine-readable dump suitable for piping into jq.
'
}

sub validate {
	my ( $self, $opt, $args ) = @_;

	if ( !-f $opt->{'m'} ) {
		$self->usage_error( '-m, "' . $opt->{'m'} . '", is not a file or does not exist' );
	} elsif ( !-r $opt->{'m'} ) {
		$self->usage_error( '-m, "' . $opt->{'m'} . '", is not readable' );
	}
	return 1;
} ## end sub validate

# Tree-shape stats are derived once at load time.  Each tree is a
# nested arrayref structure -- leaf [0, size] or interior [1, ...] /
# [2, ...] with children at fixed slots.
sub _walk_tree {
	my ( $node, $depth, $acc ) = @_;
	$acc->{nodes}++;
	if ( $node->[0] == 0 ) {    # leaf
		$acc->{leaves}++;
		$acc->{max_depth} = $depth if $depth > $acc->{max_depth};
		$acc->{depth_sum} += $depth;
		return;
	}
	# Axis interior nodes have children at slots 3,4; oblique at 4,5.
	my ( $li, $ri ) = $node->[0] == 1 ? ( 3, 4 ) : ( 4, 5 );
	_walk_tree( $node->[$li], $depth + 1, $acc );
	_walk_tree( $node->[$ri], $depth + 1, $acc );
} ## end sub _walk_tree

sub _tree_stats {
	my ($trees) = @_;
	my $acc = { nodes => 0, leaves => 0, max_depth => 0, depth_sum => 0 };
	_walk_tree( $_, 0, $acc ) for @$trees;
	return $acc;
}

sub execute {
	my ( $self, $opt, $args ) = @_;

	my $model = Algorithm::Classifier::IsolationForest->load( $opt->{'m'} );

	# Tree stats are not stored on the model -- they're cheap to derive.
	my $stats     = _tree_stats( $model->{trees} );
	my $n_trees   = scalar @{ $model->{trees} };
	my $avg_depth = $stats->{leaves} ? $stats->{depth_sum} / $stats->{leaves} : 0;
	my $avg_nodes = $n_trees         ? $stats->{nodes} / $n_trees             : 0;

	# Feature-name tags are stored as an arrayref (via -t at fit time).
	my $tags   = $model->{feature_names};
	my $tagged = ( ref $tags eq 'ARRAY' && @$tags ) ? 1 : 0;

	my %info = (
		'file'              => $opt->{'m'},
		'mode'              => $model->{mode},
		'voting'            => $model->{voting},
		'tagged'            => $tagged,
		'feature_names'     => $tagged ? $tags : undef,
		'n_trees'           => $n_trees,
		'n_features'        => $model->{n_features},
		'sample_size'       => $model->{sample_size},
		'psi_used'          => $model->{psi_used},
		'c_psi'             => $model->{c_psi},
		'max_depth_used'    => $model->{max_depth_used},
		'extension_level'   => $model->{extension_level_used},
		'contamination'     => $model->{contamination},
		'threshold'         => $model->{threshold},
		'tree_total_nodes'  => $stats->{nodes},
		'tree_total_leaves' => $stats->{leaves},
		'tree_max_depth'    => $stats->{max_depth},
		'tree_avg_depth'    => $avg_depth,
		'tree_avg_nodes'    => $avg_nodes,
	);

	if ( $opt->{'json'} ) {
		require JSON::PP;
		print JSON::PP->new->canonical(1)->pretty->encode( \%info );
		return 1;
	}

	# Text-table output, in a stable order, with undef shown as "(unset)".
	# feature_names is an arrayref -- rendered separately below.
	my @order = qw(
		file mode voting tagged n_trees n_features sample_size psi_used c_psi
		max_depth_used extension_level contamination threshold
		tree_total_nodes tree_total_leaves tree_max_depth
		tree_avg_depth tree_avg_nodes
	);

	for my $k (@order) {
		my $v = $info{$k};
		$v = '(unset)' unless defined $v;
		# Pretty-print floats with a couple of decimals; leave ints raw.
		$v = sprintf( '%.4f', $v )
			if defined $v
			&& $v =~ /^-?\d+\.\d+/
			&& $k !~ /^tree_total_/;
		printf "  %-20s  %s\n", $k, $v;
	} ## end for my $k (@order)

	# Feature-name tags, one per line, in stored (positional) order.
	if ($tagged) {
		printf "  %-20s  %s\n", 'feature_names', join( ', ', @$tags );
		for my $i ( 0 .. $#$tags ) {
			printf "    [%d]  %s\n", $i, $tags->[$i];
		}
	}
	return 1;
} ## end sub execute

return 1;
