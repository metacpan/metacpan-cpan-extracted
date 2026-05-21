#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Capture::Tiny qw(capture);
use File::Temp qw(tempfile tempdir);
use File::Spec;

# Black-box unit tests for App::Test::Generator (Generator.pm).
# Tests the public generate() function according to its POD API spec.
# Uses module: builtin in all schemas to bypass _validate_module noise.

BEGIN { use_ok('App::Test::Generator', 'generate') }

# --------------------------------------------------
# Helper: write a minimal schema YAML file
# --------------------------------------------------
sub _schema_file {
	my (%opts) = @_;
	my ($fh, $path) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	my $module   = $opts{module}   // 'builtin';
	my $function = $opts{function} // 'my_func';
	my $input    = $opts{input}    // "input:\n  type: string";
	my $output   = $opts{output}   // "output:\n  type: string";
	my $extra    = $opts{extra}    // '';
	print $fh "module: $module\nfunction: $function\n$input\n$output\n$extra\n";
	close $fh;
	return $path;
}

# ==================================================================
# generate()
#
# POD spec:
#   Legacy API:  generate($schema_file [, $outfile])
#   Modern API:  generate(schema_file => ..., output_file => ...)
#                generate(input_file  => ..., output_file => ...)
#                generate(schema => \%schema, output_file => ...)
#   Croaks:      when called with no arguments
#                when no schema source is provided
#   Side effect: writes to output_file when supplied
#                prints to STDOUT when no output_file
# ==================================================================

subtest 'generate() croaks when called with no arguments' => sub {
	throws_ok(
		sub { App::Test::Generator->generate() },
		qr/Usage/,
		'no-argument call croaks with Usage message',
	);
};

subtest 'generate() legacy API returns without croaking' => sub {
	my $schema = _schema_file();
	my ($out, $err) = capture(sub {
		eval { App::Test::Generator->generate($schema) };
	});
	is($@, '', "generate() did not croak: $@");
};

subtest 'generate() legacy API prints to STDOUT' => sub {
	my $schema = _schema_file();
	my ($out) = capture(sub {
		App::Test::Generator->generate($schema);
	});
	ok(length($out) > 0, 'output written to STDOUT');
};

subtest 'generate() output contains use strict' => sub {
	my $schema = _schema_file();
	my ($out) = capture(sub {
		App::Test::Generator->generate($schema);
	});
	like($out, qr/use strict/, 'output contains use strict');
};

subtest 'generate() output contains use warnings' => sub {
	my $schema = _schema_file();
	my ($out) = capture(sub {
		App::Test::Generator->generate($schema);
	});
	like($out, qr/use warnings/, 'output contains use warnings');
};

subtest 'generate() output contains done_testing' => sub {
	my $schema = _schema_file();
	my ($out) = capture(sub {
		App::Test::Generator->generate($schema);
	});
	like($out, qr/done_testing/, 'output contains done_testing');
};

subtest 'generate() output contains the function name' => sub {
	my $schema = _schema_file(function => 'my_special_func');
	my ($out) = capture(sub {
		App::Test::Generator->generate($schema);
	});
	like($out, qr/my_special_func/, 'function name appears in output');
};

subtest 'generate() legacy API writes to file when outfile supplied' => sub {
	my $schema  = _schema_file();
	my $tmpdir  = tempdir(CLEANUP => 1);
	my $outfile = File::Spec->catfile($tmpdir, 'generated.t');
	capture(sub {
		App::Test::Generator->generate($schema, $outfile);
	});
	ok(-f $outfile, 'output file created');
	ok(-s $outfile, 'output file is non-empty');
};

subtest 'generate() output file content contains use strict' => sub {
	my $schema  = _schema_file();
	my $tmpdir  = tempdir(CLEANUP => 1);
	my $outfile = File::Spec->catfile($tmpdir, 'generated.t');
	capture(sub {
		App::Test::Generator->generate($schema, $outfile);
	});
	open my $fh, '<', $outfile or die $!;
	my $content = do { local $/; <$fh> };
	close $fh;
	like($content, qr/use strict/, 'written file contains use strict');
};

subtest 'generate() modern API writes to output_file' => sub {
	my $schema  = _schema_file();
	my $tmpdir  = tempdir(CLEANUP => 1);
	my $outfile = File::Spec->catfile($tmpdir, 'modern.t');
	capture(sub {
		App::Test::Generator->generate(
			schema_file => $schema,
			output_file => $outfile,
		);
	});
	ok(-f $outfile, 'output file created via modern API');
	ok(-s $outfile, 'output file is non-empty via modern API');
};

subtest 'generate() modern API with schema_file key' => sub {
	my $schema = _schema_file();
	my ($out) = capture(sub {
		eval { App::Test::Generator->generate({ schema_file => $schema }) };
	});
	is($@, '', "modern schema_file API did not croak: $@");
	like($out, qr/use strict/, 'output contains use strict');
};

subtest 'generate() modern API with input_file key' => sub {
	my $schema = _schema_file();
	my ($out) = capture(sub {
		eval { App::Test::Generator->generate({ input_file => $schema }) };
	});
	is($@, '', "modern input_file API did not croak: $@");
	like($out, qr/use strict/, 'output contains use strict');
};

subtest 'generate() modern API with inline schema hashref' => sub {
	my $schema = {
		module   => 'builtin',
		function => 'inline_func',
		input    => { type => 'string' },
		output   => { type => 'string' },
	};
	my ($out) = capture(sub {
		eval { App::Test::Generator->generate({ schema => $schema }) };
	});
	is($@, '', "inline schema hashref did not croak: $@");
	like($out, qr/use strict/, 'output contains use strict for inline schema');
};

subtest 'generate() output varies with function name' => sub {
	my $s1 = _schema_file(function => 'func_alpha');
	my $s2 = _schema_file(function => 'func_beta');
	my ($out1) = capture(sub { App::Test::Generator->generate($s1) });
	my ($out2) = capture(sub { App::Test::Generator->generate($s2) });
	isnt($out1, $out2, 'different function names produce different output');
};

subtest 'generate() respects seed in schema' => sub {
	my $s1 = _schema_file(extra => 'seed: 42');
	my $s2 = _schema_file(extra => 'seed: 42');
	my ($out1) = capture(sub { App::Test::Generator->generate($s1) });
	my ($out2) = capture(sub { App::Test::Generator->generate($s2) });
	is($out1, $out2, 'same seed produces identical output');
};

subtest 'generate() respects iterations in schema' => sub {
	my $schema = _schema_file(extra => 'iterations: 5');
	my ($out)  = capture(sub {
		App::Test::Generator->generate($schema);
	});
	like($out, qr/5/, 'iteration count appears in output');
};

subtest 'generate() can be called as exported function' => sub {
	my $schema = _schema_file();
	my ($out) = capture(sub {
		eval { App::Test::Generator->generate($schema) };
	});
	is($@, '', "exported generate() did not croak: $@");
	like($out, qr/use strict/, 'output contains use strict');
};

subtest 'generate() croaks for missing schema file' => sub {
	throws_ok(
		sub {
			capture(sub {
				App::Test::Generator->generate('/no/such/schema.yml');
			});
		},
		qr/Cannot|not found|does not exist|No such/i,
		'missing schema file croaks',
	);
};

done_testing();
