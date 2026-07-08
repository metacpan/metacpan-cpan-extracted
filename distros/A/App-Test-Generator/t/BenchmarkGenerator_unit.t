#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;

use App::Test::Generator::BenchmarkGenerator;

# ==================================================================
# Constructor
# ==================================================================

subtest 'new() dies when schema argument is missing' => sub {
	throws_ok(
		sub { App::Test::Generator::BenchmarkGenerator->new() },
		qr/schema/i,
		'missing schema croaks',
	);
};

subtest 'new() dies when schema is not a hashref' => sub {
	throws_ok(
		sub { App::Test::Generator::BenchmarkGenerator->new(schema => 'string') },
		qr/schema must be a hashref/,
		'non-hashref schema croaks',
	);
};

subtest 'new() succeeds with a valid schema hashref' => sub {
	my $bg = App::Test::Generator::BenchmarkGenerator->new(
		schema => { module => 'builtin', function => 'abs', input => {} },
	);
	isa_ok($bg, 'App::Test::Generator::BenchmarkGenerator');
};

# ==================================================================
# generate() — structural checks
# ==================================================================

subtest 'generate() includes a cmpthese call' => sub {
	my $bg = App::Test::Generator::BenchmarkGenerator->new(schema => {
		module   => 'builtin',
		function => 'abs',
		input    => { number => { type => 'number', position => 0 } },
	});
	my $src = $bg->generate();
	like($src, qr/cmpthese/, 'output contains cmpthese');
};

subtest 'generate() emits a shebang line' => sub {
	my $bg = App::Test::Generator::BenchmarkGenerator->new(schema => {
		module   => 'builtin',
		function => 'length',
		input    => {},
	});
	my $src = $bg->generate();
	like($src, qr{^#!/usr/bin/env perl}, 'starts with shebang');
};

subtest 'generate() mentions the function name' => sub {
	my $bg = App::Test::Generator::BenchmarkGenerator->new(schema => {
		module   => 'builtin',
		function => 'reverse',
		input    => {},
	});
	my $src = $bg->generate();
	like($src, qr/reverse/, 'function name appears in output');
};

# ==================================================================
# generate() — builtin (no 'use Module' emitted)
# ==================================================================

subtest 'generate() does not emit a use statement for builtin module' => sub {
	my $bg = App::Test::Generator::BenchmarkGenerator->new(schema => {
		module   => 'builtin',
		function => 'abs',
		input    => { n => { type => 'number', position => 0 } },
	});
	my $src = $bg->generate();
	unlike($src, qr/^use builtin/m, 'no "use builtin" line emitted');
};

# ==================================================================
# generate() — OOP (new: key present)
# ==================================================================

subtest 'generate() emits use + constructor for OOP schema' => sub {
	my $bg = App::Test::Generator::BenchmarkGenerator->new(schema => {
		module   => 'My::Module',
		function => 'greet',
		new      => undef,
		input    => { name => { type => 'string' } },
	});
	my $src = $bg->generate();
	like($src, qr/use My::Module/,       'use statement emitted');
	like($src, qr/My::Module->new\(\)/, 'constructor call emitted');
	like($src, qr/\$obj->greet/,        'method call via $obj');
};

subtest 'generate() passes constructor args when new: is a hashref' => sub {
	my $bg = App::Test::Generator::BenchmarkGenerator->new(schema => {
		module   => 'My::Module',
		function => 'run',
		new      => { verbose => 0 },
		input    => {},
	});
	my $src = $bg->generate();
	like($src, qr/My::Module->new\(.*verbose/s, 'constructor args present');
};

# ==================================================================
# generate() — transforms become cmpthese variants
# ==================================================================

subtest 'generate() creates one variant per transform' => sub {
	my $bg = App::Test::Generator::BenchmarkGenerator->new(schema => {
		module   => 'builtin',
		function => 'abs',
		input    => { n => { type => 'number', position => 0 } },
		transforms => {
			positive => { input => { n => { type => 'number', position => 0, min => 0 } } },
			negative => { input => { n => { type => 'number', position => 0, max => 0 } } },
		},
	});
	my $src = $bg->generate();
	like($src, qr/'positive'/, 'positive variant present');
	like($src, qr/'negative'/, 'negative variant present');
	unlike($src, qr/'default'/, 'no default variant when transforms exist');
};

subtest 'generate() emits a single default variant when no transforms' => sub {
	my $bg = App::Test::Generator::BenchmarkGenerator->new(schema => {
		module   => 'builtin',
		function => 'abs',
		input    => { n => { type => 'number', position => 0 } },
	});
	my $src = $bg->generate();
	like($src, qr/'default'/, 'default variant present');
};

# ==================================================================
# generate() — representative values per type
# ==================================================================

subtest 'generate() uses -1 for a number param constrained to max => 0' => sub {
	my $bg = App::Test::Generator::BenchmarkGenerator->new(schema => {
		module     => 'builtin',
		function   => 'abs',
		input      => {},
		transforms => {
			negative => { input => { n => { type => 'number', position => 0, max => 0 } } },
		},
	});
	my $src = $bg->generate();
	like($src, qr/abs\(-1\)/, 'negative-constrained arg is -1');
};

subtest 'generate() uses 42 for an unconstrained number param' => sub {
	my $bg = App::Test::Generator::BenchmarkGenerator->new(schema => {
		module     => 'builtin',
		function   => 'abs',
		input      => {},
		transforms => {
			positive => { input => { n => { type => 'number', position => 0, min => 0 } } },
		},
	});
	my $src = $bg->generate();
	like($src, qr/abs\(42\)/, 'positive-constrained arg uses default 42');
};

subtest 'generate() uses midpoint for a number param with both min and max' => sub {
	my $bg = App::Test::Generator::BenchmarkGenerator->new(schema => {
		module     => 'builtin',
		function   => 'abs',
		input      => {},
		transforms => {
			bounded => { input => { n => { type => 'number', position => 0, min => 10, max => 20 } } },
		},
	});
	my $src = $bg->generate();
	like($src, qr/abs\(15\)/, 'midpoint 15 used for [10,20] range');
};

subtest 'generate() uses quoted string for a string param' => sub {
	my $bg = App::Test::Generator::BenchmarkGenerator->new(schema => {
		module   => 'My::Mod',
		function => 'process',
		input    => { text => { type => 'string' } },
	});
	my $src = $bg->generate();
	like($src, qr/'hello'/, 'string param gets a quoted default');
};

# ==================================================================
# generate() — named (non-positional) params
# ==================================================================

subtest 'generate() emits key => value pairs for named params' => sub {
	my $bg = App::Test::Generator::BenchmarkGenerator->new(schema => {
		module   => 'My::Mod',
		function => 'compute',
		input    => { x => { type => 'number' }, y => { type => 'number' } },
	});
	my $src = $bg->generate();
	like($src, qr/x => 42/, 'named param x with value');
	like($src, qr/y => 42/, 'named param y with value');
};

# ==================================================================
# generate() — generated output is syntactically valid Perl
# ==================================================================

subtest 'generate() produces syntactically valid Perl for builtin schema' => sub {
	my $bg = App::Test::Generator::BenchmarkGenerator->new(schema => {
		module     => 'builtin',
		function   => 'abs',
		input      => { n => { type => 'number', position => 0 } },
		transforms => {
			positive => { input => { n => { type => 'number', position => 0, min => 0 } } },
			negative => { input => { n => { type => 'number', position => 0, max => 0 } } },
		},
	});
	my $src = $bg->generate();
	# Write to temp file and perl -c it
	require File::Temp;
	my $tmp = File::Temp->new(SUFFIX => '.pl', UNLINK => 1);
	print $tmp $src;
	close $tmp;
	my $result = system($^X, '-c', "$tmp");
	is($result, 0, 'generated Perl parses without errors');
};

done_testing();
