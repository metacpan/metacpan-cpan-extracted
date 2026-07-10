#!perl
# 42-prototype.t
#
# Prototype support: a small JSON document carrying the variable schema
# (feature_names, feature_descriptions, mungers, missing policy), a
# required user-owned schema_version and schema_description, and
# optional per-class tuning params, from which fresh models are created.
# Covers the structural validator's croak matrix, creation and dispatch
# via new_from_prototype/load_prototype, override semantics (params may
# be overridden, the schema may not), the three schema-metadata knobs
# and accessors on both classes, their persistence, and the
# to_prototype extraction round trip.

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use JSON::PP   ();

use Algorithm::Classifier::IsolationForest         ();
use Algorithm::Classifier::IsolationForest::Online ();

my $batch_class  = 'Algorithm::Classifier::IsolationForest';
my $online_class = 'Algorithm::Classifier::IsolationForest::Online';

# A fresh, known-good prototype hashref to mutate per test.
sub proto_online {
	return {
		format             => 'Algorithm::Classifier::IsolationForest::Prototype',
		version            => 1,
		class              => 'online',
		schema_version     => '2026.07.08-1',
		schema_description => 'two synthetic metrics',
		schema             => {
			feature_names        => [ 'cpu', 'mem' ],
			feature_descriptions => { cpu => 'cpu utilisation fraction' },
			missing              => 'zero',
		},
		params => { n_trees => 30, window_size => 128, max_leaf_samples => 8 },
	};
} ## end sub proto_online

sub proto_batch {
	return {
		format             => 'Algorithm::Classifier::IsolationForest::Prototype',
		class              => 'batch',
		schema_version     => 'b1',
		schema_description => 'batch variant',
		schema             => { feature_names => [ 'cpu', 'mem' ] },
		params             => { n_trees       => 25, sample_size => 64, voting => 'majority' },
	};
} ## end sub proto_batch

sub rows {
	my ($n) = @_;
	return [ map { [ rand, rand ] } 1 .. $n ];
}

subtest 'schema metadata knobs on new()' => sub {
	my $f = $batch_class->new(
		feature_names        => [ 'a', 'b' ],
		schema_version       => 'v9',
		schema_description   => 'desc',
		feature_descriptions => { a => 'the a column' },
	);
	is( $f->schema_version,     'v9',   'schema_version accessor' );
	is( $f->schema_description, 'desc', 'schema_description accessor' );
	is_deeply( $f->feature_descriptions, { a => 'the a column' }, 'feature_descriptions accessor' );

	ok( !eval { $batch_class->new( schema_version       => {} );           1 }, 'ref schema_version croaks' );
	ok( !eval { $batch_class->new( feature_descriptions => { a => 'x' } ); 1 },
		'feature_descriptions without feature_names croaks' );
	like( $@, qr/requires feature_names/, 'error says why' );
	ok(
		!eval {
			$batch_class->new( feature_names => ['a'], feature_descriptions => { zzz => 'x' } );
			1;
		},
		'describing a feature that does not exist croaks'
	);
	like( $@, qr/'zzz', which is not in feature_names/, 'error names the stray key' );
	ok(
		!eval {
			$batch_class->new( feature_names => ['a'], feature_descriptions => { a => [] } );
			1;
		},
		'non-string description croaks'
	);

	# The Online class mirrors all of it.
	my $o = $online_class->new(
		feature_names        => [ 'a', 'b' ],
		schema_version       => 'v9',
		schema_description   => 'desc',
		feature_descriptions => { b => 'the b column' },
	);
	is( $o->schema_version, 'v9', 'Online: schema_version accessor' );
	is_deeply( $o->feature_descriptions, { b => 'the b column' }, 'Online: feature_descriptions accessor' );
	ok(
		!eval {
			$online_class->new( feature_names => ['a'], feature_descriptions => { zzz => 'x' } );
			1;
		},
		'Online: stray feature description croaks'
	);
}; ## end 'schema metadata knobs on new()' => sub

subtest 'validate_prototype croak matrix' => sub {
	my @cases = (
		[ 'not json',              'not { json',                                  qr/did not parse as JSON/ ],
		[ 'non-object',            '[1,2]',                                       qr/expected a JSON object/ ],
		[ 'wrong format tag',      { %{ proto_online() }, format => 'Nope' },     qr/format/ ],
		[ 'future version',        { %{ proto_online() }, version => 2 },         qr/newer than this module/ ],
		[ 'unknown top-level key', { %{ proto_online() }, bogus => 1 },           qr/unknown top-level key 'bogus'/ ],
		[ 'missing class',         { %{ proto_online() }, class => undef },       qr/class of 'batch' or 'online'/ ],
		[ 'bad class',             { %{ proto_online() }, class => 'streaming' }, qr/class of 'batch' or 'online'/ ],
		[
			'missing schema_version', { %{ proto_online() }, schema_version => undef },
			qr/non-empty schema_version/
		],
		[ 'empty schema_version', { %{ proto_online() }, schema_version => '' }, qr/non-empty schema_version/ ],
		[
			'missing schema_description',
			{ %{ proto_online() }, schema_description => undef },
			qr/non-empty schema_description/
		],
		[ 'missing schema',        { %{ proto_online() }, schema => undef }, qr/needs a schema object/ ],
		[ 'missing feature_names', { %{ proto_online() }, schema => {} },    qr/non-empty feature_names/ ],
		[
			'empty feature_names',
			{ %{ proto_online() }, schema => { feature_names => [] } },
			qr/non-empty feature_names/
		],
		[
			'ref feature name',
			{ %{ proto_online() }, schema => { feature_names => [ 'a', [] ] } },
			qr/feature_names entries must be non-empty strings/
		],
		[
			'unknown schema key',
			{ %{ proto_online() }, schema => { feature_names => ['a'], bogus => 1 } },
			qr/schema has unknown key 'bogus'/
		],
		[
			'impute_with is batch-only',
			{ %{ proto_online() }, schema => { feature_names => ['a'], impute_with => 'mean' } },
			qr/schema has unknown key 'impute_with' for a online prototype/
		],
		[
			'stray feature description',
			{ %{ proto_online() }, schema => { feature_names => ['a'], feature_descriptions => { zzz => 'x' } } },
			qr/'zzz', which is not in feature_names/
		],
		[
			'non-hash mungers',
			{ %{ proto_online() }, schema => { feature_names => ['a'], mungers => [] } },
			qr/mungers must be an object/
		],
		[ 'non-hash params', { %{ proto_online() }, params => [] },                  qr/params must be an object/ ],
		[ 'unknown param',   { %{ proto_online() }, params => { windowsize => 1 } }, qr/unknown key 'windowsize'/ ],
		[
			'machine-local knob',
			{ %{ proto_online() }, params => { use_c => 1 } },
			qr/machine-local knobs like use_c/
		],
		[
			'batch param on an online prototype',
			{ %{ proto_online() }, params => { sample_size => 64 } },
			qr/unknown key 'sample_size' for a online prototype/
		],
	);

	for my $case (@cases) {
		my ( $name, $proto, $re ) = @$case;
		ok( !eval { $batch_class->validate_prototype($proto); 1 }, "$name croaks" );
		like( $@, $re, "$name error message" );
	}

	# The happy paths: a hashref and its JSON encoding both validate,
	# and the JSON form decodes back to the same structure.
	my $ok = $batch_class->validate_prototype( proto_online() );
	is( ref $ok, 'HASH', 'valid hashref prototype returns the hashref' );
	my $from_json = $batch_class->validate_prototype( JSON::PP->new->encode( proto_online() ) );
	is_deeply( $from_json, proto_online(), 'valid JSON string prototype decodes and validates' );

	# Munger-bearing prototypes validate structurally without
	# Algorithm::ToNumberMunger -- compilation happens at creation.
	my $with_mungers = proto_online();
	$with_mungers->{schema}{mungers} = { cpu => { munger => 'anything_here' } };
	ok(
		eval { $batch_class->validate_prototype($with_mungers); 1 },
		'munger-bearing prototype validates structurally'
	) or diag $@;
}; ## end 'validate_prototype croak matrix' => sub

subtest 'new_from_prototype: creation, dispatch, overrides' => sub {
	my $b = $batch_class->new_from_prototype( proto_batch(), seed => 42 );
	isa_ok( $b, $batch_class, 'batch prototype creates the batch class' );
	is( $b->{n_trees},          25,              'params applied' );
	is( $b->{sample_size},      64,              'sample_size applied' );
	is( $b->{voting},           'majority',      'voting applied' );
	is( $b->{seed},             42,              'override applied' );
	is( $b->schema_version,     'b1',            'schema_version stamped' );
	is( $b->schema_description, 'batch variant', 'schema_description stamped' );
	is_deeply( $b->feature_names, [ 'cpu', 'mem' ], 'feature_names from the schema' );

	my $o = $online_class->new( n_trees => 1 );    # just to prove dispatch is by prototype, not caller
	$o = $batch_class->new_from_prototype( proto_online() );
	isa_ok( $o, $online_class, 'online prototype creates the online class through the parent' );
	is( $o->{window_size},      128,    'online params applied' );
	is( $o->{max_leaf_samples}, 8,      'eta applied' );
	is( $o->{missing},          'zero', 'schema missing policy applied' );
	is_deeply( $o->feature_descriptions, { cpu => 'cpu utilisation fraction' }, 'feature_descriptions applied' );

	my $tuned = $batch_class->new_from_prototype( proto_online(), n_trees => 99 );
	is( $tuned->{n_trees}, 99, 'override beats the prototype param' );

	ok( !eval { $batch_class->new_from_prototype( proto_online(), mungers => {} ); 1 },
		'overriding a schema key croaks' );
	like( $@, qr/may not be overridden/, 'schema override error says so' );
	ok( !eval { $batch_class->new_from_prototype( proto_online(), sample_size => 64 ); 1 },
		'unknown override croaks' );

	# Bad param VALUES croak too -- new() itself validates them.
	my $bad = proto_online();
	$bad->{params}{subsample} = 2;
	ok( !eval { $batch_class->new_from_prototype($bad); 1 }, 'invalid param value croaks from new()' );
}; ## end 'new_from_prototype: creation, dispatch, overrides' => sub

subtest 'load_prototype and persistence of the schema metadata' => sub {
	my $dir = tempdir( CLEANUP => 1 );

	my $path = "$dir/proto.json";
	open my $fh, '>', $path or die $!;
	print {$fh} JSON::PP->new->encode( proto_batch() );
	close $fh;

	my $f = $batch_class->load_prototype( $path, seed => 42, contamination => 0.05 );
	isa_ok( $f, $batch_class, 'load_prototype creates from the file' );
	is( $f->{contamination}, 0.05, 'override applied through load_prototype' );

	srand(11);
	$f->fit( rows(150) );
	$f->save("$dir/model.json");
	my $re = $batch_class->load("$dir/model.json");
	is( $re->schema_version,     'b1',            'batch: schema_version survives save/load' );
	is( $re->schema_description, 'batch variant', 'batch: schema_description survives save/load' );

	srand(12);
	my $o = $batch_class->new_from_prototype( proto_online(), seed => 7 );
	$o->learn( rows(100) );
	$o->save("$dir/omodel.json");
	my $ore = Algorithm::Classifier::IsolationForest->load("$dir/omodel.json");
	isa_ok( $ore, $online_class, 'parent load() dispatches the online model' );
	is( $ore->schema_version, '2026.07.08-1', 'online: schema_version survives save/load' );
	is_deeply(
		$ore->feature_descriptions,
		{ cpu => 'cpu utilisation fraction' },
		'online: feature_descriptions survive save/load'
	);
}; ## end 'load_prototype and persistence of the schema metadata' => sub

subtest 'to_prototype extraction round trip' => sub {
	my $data = do { srand(13); rows(150) };

	my $a = $batch_class->new_from_prototype( proto_batch(), seed => 42, contamination => 0.1 );
	$a->fit($data);

	my $extracted = $a->to_prototype;
	my $decoded   = $batch_class->validate_prototype($extracted);
	is( $decoded->{class},                 'batch', 'extracted prototype is valid and batch' );
	is( $decoded->{schema_version},        'b1',    'extracted prototype keeps the schema_version' );
	is( $decoded->{params}{contamination}, 0.1,     'override made it into the extracted params' );

	# Recreate from the extraction with the same seed: identical model.
	my $b = $batch_class->new_from_prototype( $extracted, seed => 42 );
	$b->fit($data);
	is( $b->to_json, $a->to_json, 'model recreated from the extracted prototype is byte-identical' );

	# Online extraction round-trips through the validator too.
	my $o  = $batch_class->new_from_prototype( proto_online() );
	my $op = $batch_class->validate_prototype( $o->to_prototype );
	is( $op->{class},               'online', 'online extraction carries class online' );
	is( $op->{params}{window_size}, 128,      'online extraction keeps window_size' );

	# A model with no feature_names has no variable schema to extract.
	my $bare = $batch_class->new;
	srand(14);
	$bare->fit( rows(80) );
	ok( !eval { $bare->to_prototype; 1 }, 'to_prototype without feature_names croaks' );
	like( $@, qr/no feature_names/, 'error says why' );

	# No recorded metadata -> placeholder values, still a valid file.
	my $plain = $batch_class->new( feature_names => [ 'x', 'y' ] );
	srand(15);
	$plain->fit( rows(80) );
	my $placeholder = $batch_class->validate_prototype( $plain->to_prototype );
	is( $placeholder->{schema_version}, '0', 'placeholder schema_version when none recorded' );
	like(
		$placeholder->{schema_description},
		qr/none recorded/,
		'placeholder schema_description when none recorded'
	);
}; ## end 'to_prototype extraction round trip' => sub

subtest 'munger-bearing prototype creation' => sub {
	plan skip_all => 'Algorithm::ToNumberMunger is not installed'
		unless eval { require Algorithm::ToNumberMunger; 1 };

	my $proto = {
		format             => 'Algorithm::Classifier::IsolationForest::Prototype',
		class              => 'batch',
		schema_version     => 'm1',
		schema_description => 'munged http rows',
		schema             => {
			feature_names => [ 'method', 'path_len' ],
			mungers       => {
				method   => { munger => 'http_method_enum', default => -1 },
				path_len => { munger => 'length' },
			},
		},
		params => { n_trees => 20, sample_size => 32 },
	};

	my $f = $batch_class->new_from_prototype( $proto, seed => 5 );
	srand(16);
	$f->fit_tagged(
		[ map { { method => ( $_ % 4 ? 'GET' : 'POST' ), path_len => '/' . ( 'p' x ( 3 + $_ % 15 ) ) } } 1 .. 120 ]
	);
	my $score = $f->score_sample_tagged( { method => 'GET', path_len => '/ppppp.html' } );
	cmp_ok( $score, '>', 0, 'munger-bearing prototype fits and scores tagged rows' );

	# A bogus munger spec dies at creation, not first use.
	my $bad
		= { %$proto, schema => { feature_names => ['method'], mungers => { method => { munger => 'bogus' } } } };
	ok( !eval { $batch_class->new_from_prototype($bad); 1 }, 'bogus munger spec croaks at creation' );
	like( $@, qr/unknown munger 'bogus'/, 'error names the munger' );
}; ## end 'munger-bearing prototype creation' => sub

done_testing;
