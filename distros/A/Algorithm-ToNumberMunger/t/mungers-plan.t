#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use Algorithm::ToNumberMunger;
my $M = 'Algorithm::ToNumberMunger';

my $FMT = '%Y-%m-%dT%H:%M:%S';

# A set with a sin/cos time expander, a scalar log column, and a raw column.
my $plan = $M->compile(
	tags    => [qw(time_sin time_cos bytes status)],
	mungers => {
		time_of_week => {
			munger => 'datetime',
			from   => 'timestamp',
			format => $FMT,
			parts  => [qw(sin_week cos_week)],
			into   => [qw(time_sin time_cos)],
		},
		bytes => { munger => 'log', offset => 1 },
	},
);
isa_ok( $plan, 'Algorithm::ToNumberMunger::Plan' );

# ---- apply_named: the expander fills both columns from one source -----------
{
	# 2026-07-05 is Sunday: midnight is frac_week 0 -> sin 0, cos 1.
	my $row = $plan->apply_named( { timestamp => '2026-07-05T00:00:00', bytes => 0, status => 200 } );
	is_deeply( $row, [ 0, 1, 0, 200 ], 'apply_named: sin/cos pair + log1p(0) + raw status, in tag order' );

	eval { $plan->apply_named( { bytes => 0, status => 200 } ) };
	like( $@, qr/missing value for 'timestamp'/, 'apply_named croaks when an expander source is missing' );
}

# ---- from-alias on a scalar munger -----------------------------------------
{
	my $al = $M->compile(
		tags    => ['x'],
		mungers => { x => { munger => 'log', offset => 1, from => 'src' } },
	);
	is( $al->apply_named( { src => 0 } )->[0], 0, 'scalar from-alias reads source' );
	eval { $al->apply_named( { x => 0 } ) };
	like( $@, qr/missing value for 'src'/, 'from-alias requires the source field' );
}

# ---- apply_positional: scalars only, no mutation ---------------------------
{
	my $p = $M->compile(
		tags    => [qw(a b)],
		mungers => { a => { munger => 'log', offset => 1 } }
	);
	my $orig = [ 3, 5 ];
	my $out  = $p->apply_positional($orig);
	ok( abs( $out->[0] - log(4) ) < 1e-9, 'positional applies the scalar munger' );
	is( $out->[1], 5, 'positional passes a raw column through' );
	is_deeply( $orig, [ 3, 5 ], 'positional does not mutate the caller row' );

	eval { $p->apply_positional( [1] ) };
	like( $@, qr/declares 2/, 'positional arity check' );

	eval { $plan->apply_positional( [ 1, 2, 3, 4 ] ) };
	like( $@, qr/expanding mungers/, 'positional is rejected when the set has expanders' );
}

# ---- multi-input combiners: ratio and combine -------------------------------
{
	my $p = $M->compile(
		tags    => [qw(io_ratio total)],
		mungers => {
			io_ratio => { munger => 'ratio',   from => [qw(bytes_out bytes_in)] },
			total    => { munger => 'combine', from => [qw(bytes_out bytes_in extra)], op => 'sum' },
		},
	);
	is_deeply(
		$p->apply_named( { bytes_out => 6, bytes_in => 3, extra => 1 } ),
		[ 2, 10 ],
		'combiners fill their columns from several named sources'
	);
	is( $p->apply_named( { bytes_out => 6, bytes_in => 0, extra => 0 } )->[0],
		0, 'ratio zero denominator falls back to 0' );

	eval { $p->apply_named( { bytes_out => 6, bytes_in => 3 } ) };
	like( $@, qr/missing value for 'extra'/, 'combiner croaks when a source is missing' );

	eval { $p->apply_named( { bytes_out => 6, bytes_in => 'wat', extra => 1 } ) };
	like( $@, qr/'wat' is not numeric/, 'combiner croaks on a non-numeric source' );

	eval { $p->apply_positional( [ 1, 2 ] ) };
	like( $@, qr/multi-input mungers/, 'positional is rejected when the set has combiners' );

	my $z = $M->compile(
		tags    => ['r'],
		mungers => { r => { munger => 'ratio', from => [qw(a b)], zero => -1 } },
	);
	is( $z->apply_named( { a => 5, b => 0 } )->[0], -1, "ratio honors a custom 'zero'" );

	my $ops = $M->compile(
		tags    => [qw(s d p mn mx me)],
		mungers => {
			s  => { munger => 'combine', op => 'sum',     from => [qw(a b)] },
			d  => { munger => 'combine', op => 'diff',    from => [qw(a b)] },
			p  => { munger => 'combine', op => 'product', from => [qw(a b)] },
			mn => { munger => 'combine', op => 'min',     from => [qw(a b)] },
			mx => { munger => 'combine', op => 'max',     from => [qw(a b)] },
			me => { munger => 'combine', op => 'mean',    from => [qw(a b)] },
		},
	);
	is_deeply(
		$ops->apply_named( { a => 6, b => 3 } ),
		[ 9, 3, 18, 3, 6, 4.5 ],
		'combine folds: sum, diff, product, min, max, mean'
	);
}

# ---- combiner compile-time validation ---------------------------------------
{
	eval { $M->compile( tags => ['x'], mungers => { x => { munger => 'log', from => [qw(a b)] } } ) };
	like( $@, qr/does not support multiple inputs/, "rejects a 'from' list on a munger that cannot combine" );

	eval { $M->compile( tags => ['x'], mungers => { x => { munger => 'ratio', from => ['a'] } } ) };
	like( $@, qr/at least 2 source fields/, "rejects a 'from' list with one source" );

	eval { $M->compile( tags => ['x'], mungers => { x => { munger => 'ratio', from => [qw(a b)], into => ['x'] } } ) };
	like( $@, qr/'into' cannot be combined with a 'from' list/, "rejects 'into' plus a 'from' list" );

	eval { $M->compile( tags => ['x'], mungers => { zzz => { munger => 'ratio', from => [qw(a b)] } } ) };
	like( $@, qr/is not a declared tag/, 'a combiner must be keyed by a tag' );

	eval { $M->compile( tags => ['x'], mungers => { x => { munger => 'ratio', from => [qw(a b c)] } } ) };
	like( $@, qr/exactly 2 source fields/, 'ratio rejects more than 2 sources' );

	eval {
		$M->compile(
			tags    => ['x'],
			mungers => { x => { munger => 'combine', op => 'diff', from => [qw(a b c)] } }
		);
	};
	like( $@, qr/'diff' takes exactly 2/, 'combine diff needs exactly 2 sources' );

	eval { $M->compile( tags => ['x'], mungers => { x => { munger => 'combine', op => 'nope', from => [qw(a b)] } } ) };
	like( $@, qr/unknown op 'nope'/, 'combine rejects an unknown op' );

	eval { $M->compile( tags => ['x'], mungers => { x => { munger => 'combine', from => [qw(a b)] } } ) };
	like( $@, qr/requires an 'op'/, 'combine requires an op' );
}

# ---- chain with a multi-output terminal --------------------------------------
{
	my $p = $M->compile(
		tags    => [qw(t_sin t_cos)],
		mungers => {
			when => {
				munger => 'chain',
				from   => 'stamp',
				steps  => [ { op => 'trim' } ],
				then   => { munger => 'datetime', format => $FMT, parts => [qw(sin_week cos_week)] },
				into   => [qw(t_sin t_cos)],
			},
		},
	);
	is_deeply(
		$p->apply_named( { stamp => '  2026-07-05T00:00:00  ' } ),
		[ 0, 1 ],
		'chain trims its input before a datetime sin/cos expansion'
	);

	eval {
		$M->compile(
			tags    => ['a'],
			mungers => {
				g => {
					munger => 'chain',
					from   => 'src',
					steps  => [ { op => 'trim' } ],
					then   => { munger => 'log' },
					into   => ['a'],
				}
			},
		);
	};
	like( $@, qr/does not support\s+multiple outputs/, 'chain-multi rejects a scalar-only terminal' );
}

# ---- a set with no mungers is all-raw --------------------------------------
{
	my $raw = $M->compile( tags => [qw(a b)] );
	is_deeply( $raw->apply_named( { a => 1, b => 2 } ), [ 1, 2 ], 'no-munger named' );
	is_deeply( $raw->apply_positional( [ 3, 4 ] ),      [ 3, 4 ], 'no-munger positional' );
}

# ---- compile-time coverage validation --------------------------------------
{
	# two mungers claim the same column
	eval {
		$M->compile(
			tags    => ['x'],
			mungers => {
				x => { munger => 'log' },
				g => {
					munger => 'datetime',
					format => $FMT,
					parts  => ['epoch'],
					into   => ['x']
				},
			},
		);
	};
	like( $@, qr/two mungers write column 'x'/, 'rejects overlapping claims' );

	# into names an unknown column
	eval {
		$M->compile(
			tags    => ['a'],
			mungers => {
				g => {
					munger => 'datetime',
					format => $FMT,
					parts  => ['epoch'],
					into   => ['nope']
				}
			},
		);
	};
	like( $@, qr/unknown column 'nope'/, 'rejects into on an unknown column' );

	# a key that is neither a tag nor an expander
	eval { $M->compile( tags => ['a'], mungers => { zzz => { munger => 'log' } } ) };
	like( $@, qr/is not a declared tag and has no 'into'/, 'rejects orphan key' );

	# parts / into length mismatch
	eval {
		$M->compile(
			tags    => [qw(a b)],
			mungers => {
				g => {
					munger => 'datetime',
					format => $FMT,
					parts  => [qw(sin_week cos_week)],
					into   => ['a']
				}
			},
		);
	};
	like( $@, qr/produces 2 value\(s\) but 'into' lists 1/, 'rejects parts/into arity mismatch' );

	# into on a munger that cannot fan out
	eval { $M->compile( tags => ['a'], mungers => { g => { munger => 'log', into => ['a'] } }, ); };
	like( $@, qr/does not support multiple outputs/, 'rejects into on a single-output munger' );

	# scalar build path refuses 'parts'
	eval { $M->build( { munger => 'datetime', format => $FMT, parts => ['epoch'] } ) };
	like( $@, qr/'parts' is for the multi-output form/, 'scalar datetime rejects parts without into' );
}

done_testing;
