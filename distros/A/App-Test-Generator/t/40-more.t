#!/usr/bin/env perl

use strict;
use warnings;

use File::Temp qw(tempdir tempfile);
use Test::Most;
use YAML::XS;

BEGIN { use_ok('App::Test::Generator') }

# Helper functions for the tests
sub write_yaml {
	my ($file, $data) = @_;
	YAML::XS::DumpFile($file, $data);
}

sub slurp {
	my $file = shift;
	open my $fh, '<', $file or die "Cannot read $file: $!";
	local $/;
	my $content = <$fh>;
	close $fh;
	return $content;
}

my $dir = tempdir(CLEANUP => 1);

# Test invalid input specification
subtest 'invalid input handling' => sub {
	my $bad_conf = File::Spec->catfile($dir, 'bad_input.yml');

	# Config with invalid input (not a hash)
	write_yaml($bad_conf, {
		module => 'Test::Most',
		function => 'test',
		input => 'invalid',  # Should be hash
		output => { type => 'string' }
	});

	throws_ok { App::Test::Generator->generate($bad_conf) } qr/input should be a hash/, 'should croak on non-hash input';

	unlink $bad_conf;
};

# Test invalid output specification
subtest 'invalid output handling' => sub {
	my $bad_conf = File::Spec->catfile($dir, 'bad_ouput.yml');

	write_yaml($bad_conf, {
		module => 'Test::Most',
		function => 'test',
		input => { test => { type => 'string' } },
		output => 'invalid'  # Should be hash
	});

	throws_ok { App::Test::Generator->generate($bad_conf) } qr/output should be a hash/, 'should croak on non-hash output';

	unlink $bad_conf;
};

# Test invalid transforms specification
subtest 'invalid transforms handling' => sub {
	my $bad_conf = File::Spec->catfile($dir, 'bad_transforms.yml');

	write_yaml($bad_conf, {
		module => 'Test::Most',
		function => 'test',
		input => { test => { type => 'string' } },
		output => { type => 'string' },
		transforms => 'invalid'  # Should be hash
	});

	throws_ok { App::Test::Generator->generate($bad_conf) } qr/transforms should be a hash/, 'should croak on non-hash transforms';

	unlink $bad_conf;
};

# Test builtin function configuration
subtest 'builtin functions' => sub {
	my $builtin_conf = File::Spec->catfile($dir, 'builtin_test.yml');
	my $builtin_t = File::Spec->catfile($dir, 'builtin_test.t');

	write_yaml($builtin_conf, {
		module => 'builtin',
		function => 'length',
		input => { type => 'string' },
		output => { type => 'integer' }
	});

	App::Test::Generator->generate($builtin_conf, $builtin_t);

	my $content = slurp($builtin_t);
	like($content, qr/length\(/, 'should generate test for builtin function');
	unlike($content, qr/use_ok\('length/, 'should not use_ok for builtin functions');

	unlink $builtin_conf, $builtin_t;
};

# Test config boolean value processing
subtest 'config boolean processing' => sub {
	my $bool_conf = File::Spec->catfile($dir, 'bool_config.yml');
	my $bool_t = File::Spec->catfile($dir, 'bool_config.t');

	write_yaml($bool_conf, {
		module => 'Test::Most',
		function => 'test',
		input => { test => { type => 'string' } },
		output => { type => 'string' },
		config => {
			test_nuls => 'off',
			test_undef => 'no',
			test_empty => 'false',
			dedup => 'on'
		}
	});

	App::Test::Generator->generate($bool_conf, $bool_t);

	# Verify the generated test has correct boolean values
	my $content = slurp($bool_t);
	like($content, qr/'test_nuls' => 0/, 'should convert "off" to 0');
	like($content, qr/'test_undef' => 0/, 'should convert "no" to 0');
	like($content, qr/'test_empty' => 0/, 'should convert "false" to 0');
	like($content, qr/'dedup' => 1/, 'should convert "on" to 1');

	unlink $bool_conf, $bool_t;
};

# Test module name guessing from filename
subtest 'module name guessing' => sub {
	my $guess_conf = File::Spec->catfile($dir, 'My-Test-Module.yml');

	write_yaml($guess_conf, {
		function => 'test',
		input => { test => { type => 'string' } },
		output => { type => 'string' }
		# No module specified - should guess from filename
	});

	pass('TODO When Legacy Files Removed');
	# App::Test::Generator->generate($guess_conf, 't/guess_test.t');

	# my $content = slurp('t/guess_test.t');
	# like($content, qr/My::Test::Module/, 'should guess module name from filename');

	# unlink $guess_conf, 't/guess_test.t';
	unlink $guess_conf;
};

# Test YAML corpus validation
subtest 'YAML corpus validation' => sub {
	my $corpus_conf = File::Spec->catfile($dir, 'corpus_test.yml');
	my $corpus_t = File::Spec->catfile($dir, 'corpus_test.t');
	my $bad_corpus = File::Spec->catfile($dir, 'bad_corpus.yml');

	# Create invalid YAML corpus (non-array values)
	write_yaml($bad_corpus, {
		'expected1' => 'not_an_array',  # Invalid - should be array
		'expected2' => { hash => 'value' }  # Invalid - should be array
	});

	write_yaml($corpus_conf, {
		module => 'Test::Most',
		function => 'test',
		input => { test => { type => 'string' } },
		output => { type => 'string' },
		yaml_cases => $bad_corpus
	});

	# Capture warnings about invalid corpus
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	App::Test::Generator->generate($corpus_conf, $corpus_t);

	like($warnings[0], qr/does not point to an array ref/,
		'should warn about invalid YAML corpus entries');

	unlink $corpus_conf, $bad_corpus, $corpus_t;
};

# Test case merging between YAML and Perl cases
subtest 'case merging' => sub {
	my $merge_conf = File::Spec->catfile($dir, 'merge_test.yml');
	my $merge_t = File::Spec->catfile($dir, 'merge_test.t');
	my $yaml_corpus = File::Spec->catfile($dir, 'merge_corpus.yml');

	# Create YAML corpus
	write_yaml($yaml_corpus, {
		'yaml_only' => ['yaml_input'],
		'shared_key' => ['yaml_value']
	});

	write_yaml($merge_conf, {
		module => 'Test::Most',
		function => 'test',
		input => { test => { type => 'string' } },
		output => { type => 'string' },
		yaml_cases => $yaml_corpus,
		cases => {
			'perl_only' => ['perl_input'],
			'shared_key' => ['perl_value']
		}
	});

	App::Test::Generator->generate($merge_conf, $merge_t);

	my $content = slurp($merge_t);
	# Should contain both YAML and Perl cases
	like($content, qr/yaml_only/, 'should include YAML-only cases');
	like($content, qr/perl_only/, 'should include Perl-only cases');
	like($content, qr/shared_key/, 'should handle shared keys');

	unlink $merge_conf, $yaml_corpus, $merge_t;
};

# Test empty new configuration
subtest 'empty new configuration' => sub {
	my $empty_new_conf = File::Spec->catfile($dir, 'empty_new.yml');
	my $empty_new_t = File::Spec->catfile($dir, 'empty_new.t');

	write_yaml($empty_new_conf, {
		module => 'Test::Most',
		function => 'test_method',
		new => undef,  # Explicitly undefined
		input => { test => { type => 'string' } },
		output => { type => 'string' }
	});

	App::Test::Generator->generate($empty_new_conf, $empty_new_t);

	my $content = slurp($empty_new_t);
	like($content, qr/new_ok.*Test::Most/,
		'should handle undefined new configuration');

	unlink $empty_new_conf, $empty_new_t;
};

# Test edge_case_array functionality
subtest 'edge_case_array' => sub {
	my $edge_array_conf = File::Spec->catfile($dir, 'edge_array.yml');
	my $edge_array_t = File::Spec->catfile($dir, 'edge_array.t');

	write_yaml($edge_array_conf, {
		module => 'Test::Most',
		function => 'test',
		input => { type => 'string' },
		output => { type => 'string' },
		edge_case_array => [
			'case1',
			'case2',
			'case3'
		]
	});

	App::Test::Generator->generate($edge_array_conf, $edge_array_t);

	my $content = slurp($edge_array_t);
	like($content, qr/edge_case_array/, 'should include edge_case_array');
	like($content, qr/case1/, 'should include edge case values');

	unlink $edge_array_conf, $edge_array_t;
};

# Test OO configuration with new parameters
subtest 'OO with new parameters' => sub {
	my $oo_conf = File::Spec->catfile($dir, 'oo_test.yml');
	my $oo_t = File::Spec->catfile($dir, 'oo_test.t');

	write_yaml($oo_conf, {
		module => 'Test::Most',
		function => 'test_method',
		new => {
			param1 => 'value1',
			param2 => 'value2'
		},
		input => { test => { type => 'string' } },
		output => { type => 'string' }
	});

	App::Test::Generator->generate($oo_conf, $oo_t);

	my $content = slurp($oo_t);
	like($content, qr/new_ok.*Test::Most.*param1.*value1/, 'should generate OO test with constructor parameters');

	unlink $oo_conf, $oo_t;
};

subtest 'builtin with new field should not generate use_ok' => sub {
	my $conf = File::Spec->catfile($dir, 'builtin_new.yml');
	my $t	= File::Spec->catfile($dir, 'builtin_new.t');

	write_yaml($conf, {
		module   => 'builtin',
		function => 'abs',
		new	  => undef,
		input	=> { number => { type => 'number', position => 0 } },
		output   => { type => 'number' },
	});

	App::Test::Generator->generate($conf, $t);

	my $content = slurp($t);

	# When module is builtin, no use_ok should be emitted even
	# when new: is present in the schema
	unlike($content, qr/use_ok\('abs'\)/, 'builtin + new should not emit use_ok');
	unlike($content, qr/new_ok\(''\)/, 'builtin + new should not emit new_ok with empty module');
	like($content,   qr/\babs\(/, 	 'builtin function should be called directly');

	unlink $conf, $t;
};

subtest 'config with undef field is ignored' => sub {
	my $conf = File::Spec->catfile($dir, 'undef_config.yml');
	my $t	= File::Spec->catfile($dir, 'undef_config.t');

	write_yaml($conf, {
		module   => 'Test::Most',
		function => 'test',
		input	=> { test => { type => 'string' } },
		output   => { type => 'string' },
		config   => {
			test_nuls  => 'off',
			test_undef => undef,	# Explicitly undef — should be ignored
		},
	});

	App::Test::Generator->generate($conf, $t);

	my $content = slurp($t);

	# Undef config fields should not cause warnings or errors
	unlike($content, qr/Use of uninitialized/, 'undef config field should not cause warnings');

	unlink $conf, $t;
};

done_testing();
