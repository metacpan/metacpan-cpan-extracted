#!/usr/bin/env perl

# Tests for the --versions option of "ghgen generate" and the
# versions option of App::GHGen::Generator::generate_workflow

use v5.36;
use Test::Most;
use IPC::Run3 qw(run3);
use Path::Tiny;
use File::Temp qw(tempdir);
use YAML::XS qw(Load);

use_ok('App::GHGen::Generator', qw(generate_workflow));

my $lib = path(__FILE__)->parent->parent->child('lib')->absolute->stringify;
my $bin = path(__FILE__)->parent->parent->child('bin/ghgen')->absolute->stringify;

# Matrix key and the default list for each language with a version matrix
my %C = (
	node   => { key => 'node-version',   default => [qw(18.x 20.x 22.x)] },
	python => { key => 'python-version', default => [qw(3.9 3.10 3.11 3.12)] },
	ruby   => { key => 'ruby-version',   default => [qw(3.1 3.2 3.3)] },
	java   => { key => 'java-version',   default => [qw(11 17 21)] },
	php    => { key => 'php-version',    default => [qw(8.1 8.2 8.3)] },
);

# Run ghgen generate with extra args; return (yaml, stderr, exit)
sub generate(@args) {
	my $dir = tempdir(CLEANUP => 1);
	my $file = "$dir/out.yml";
	my ($out, $err);
	run3([ $^X, "-I$lib", $bin, 'generate', "--output=$file", @args ],
		\undef, \$out, \$err);
	my $status = $? >> 8;
	my $yaml = path($file)->exists ? path($file)->slurp_utf8 : '';
	diag "stderr: $err" if $ENV{TEST_VERBOSE} && $err;
	return ($yaml, $err, $status);
}

sub matrix_of($yaml, $key) {
	return Load($yaml)->{jobs}{test}{strategy}{matrix}{$key};
}

subtest 'perl default matrix is 5.36-5.42' => sub {
	my ($yaml, undef, $rc) = generate('--type=perl');
	is($rc, 0, 'exit 0');
	my @got = $yaml =~ /^\s+-\s+"(5\.\d+)"\s*$/mg;
	is_deeply(\@got, [qw(5.36 5.38 5.40 5.42)], 'default versions');
};

subtest 'perl --versions overrides the matrix' => sub {
	my ($yaml, undef, $rc) = generate('--type=perl', '--versions=5.40,5.42,5.44');
	is($rc, 0, 'exit 0');
	my @got = $yaml =~ /^\s+-\s+"(5\.\d+)"\s*$/mg;
	is_deeply(\@got, [qw(5.40 5.42 5.44)], 'requested versions only');
	unlike($yaml, qr/["']5\.36["']/, 'default version absent');
};

subtest 'perl --versions works with --os' => sub {
	my ($yaml, undef, $rc) = generate('--type=perl', '--os=linux', '--versions=5.42');
	is($rc, 0, 'exit 0');
	like($yaml, qr/["']5\.42["']/, 'version present');
	unlike($yaml, qr/windows-latest|macos-latest/, 'os restriction kept');
};

for my $lang (sort keys %C) {
	subtest "$lang default and --versions" => sub {
		my ($key, $default) = @{$C{$lang}}{qw(key default)};

		my ($yaml, undef, $rc) = generate("--type=$lang");
		is($rc, 0, 'exit 0');
		is_deeply(matrix_of($yaml, $key), $default, 'default matrix');

		($yaml, undef, $rc) = generate("--type=$lang", '--versions=3.10,3.12');
		is($rc, 0, 'exit 0');
		is_deeply(matrix_of($yaml, $key), ['3.10', '3.12'],
			'versions replaced and kept as strings');
	};
}

subtest 'go: single version by default, matrix with --versions' => sub {
	my ($yaml) = generate('--type=go');
	like($yaml, qr/go-version: '1\.22'/, 'default is a single version');
	unlike($yaml, qr/strategy:/, 'no matrix by default');

	($yaml) = generate('--type=go', '--versions=1.23,1.24');
	is_deeply(matrix_of($yaml, 'go-version'), ['1.23', '1.24'], 'matrix emitted');
	like($yaml, qr/go-version: \$\{\{ matrix\.go-version \}\}/, 'step uses matrix');
	lives_ok { Load($yaml) } 'valid YAML';
};

subtest 'rust: stable by default, toolchain matrix with --versions' => sub {
	my ($yaml) = generate('--type=rust');
	like($yaml, qr/rust-toolchain\@stable/, 'default is stable');
	unlike($yaml, qr/strategy:/, 'no matrix by default');

	($yaml) = generate('--type=rust', '--versions=stable,beta');
	is_deeply(matrix_of($yaml, 'rust-version'), [qw(stable beta)], 'matrix emitted');
	like($yaml, qr/toolchain: \$\{\{ matrix\.rust-version \}\}/, 'step uses matrix');
	lives_ok { Load($yaml) } 'valid YAML';
};

subtest 'types without a version matrix warn and are unchanged' => sub {
	for my $type (qw(cpp docker static)) {
		my ($plain) = generate("--type=$type");
		my ($yaml, $err, $rc) = generate("--type=$type", '--versions=1.0');
		is($rc, 0, "$type: exit 0");
		like($err, qr/--versions has no effect for type '$type'/, "$type: warning");
		is($yaml, $plain, "$type: output unchanged");
	}
};

subtest 'duplicates and whitespace are tolerated' => sub {
	my ($yaml, undef, $rc) = generate('--type=node', '--versions=20, 22,20');
	is($rc, 0, 'exit 0');
	is_deeply(matrix_of($yaml, 'node-version'), ['20', '22'], 'deduplicated');
};

subtest 'invalid --versions is rejected by the CLI' => sub {
	for my $bad ('20,"; rm -rf /', ',', '5.40 5.42') {
		my ($yaml, $err, $rc) = generate('--type=node', "--versions=$bad");
		isnt($rc, 0, "non-zero exit for '$bad'");
		is($yaml, '', 'no file written');
		like($err, qr/--versions|Invalid version/, 'error mentions --versions');
	}
};

subtest 'every type still yields a structurally valid workflow with --versions' => sub {
	my @types = qw(perl node python rust go ruby java cpp php docker static);
	for my $type (@types) {
		my ($yaml, undef, $rc) = generate("--type=$type", '--versions=1.1,1.2');
		is($rc, 0, "$type: exit 0");
		my $workflow = eval { Load($yaml) };
		ok($workflow, "$type: parses as YAML") or next;
		ok($workflow->{name}, "$type: has a name");
		my $jobs = $workflow->{jobs};
		ok($jobs && %{$jobs}, "$type: has jobs") or next;
		for my $job (sort keys %{$jobs}) {
			ok(defined $jobs->{$job}{'runs-on'}, "$type/$job: has runs-on");
			ok(ref $jobs->{$job}{steps} eq 'ARRAY' && @{ $jobs->{$job}{steps} },
				"$type/$job: has steps");
		}
	}
};

subtest 'generate_workflow API' => sub {
	my $yaml = generate_workflow('python', { versions => ['3.13'] });
	is_deeply(matrix_of($yaml, 'python-version'), ['3.13'], 'versions applied');

	is(generate_workflow('python', { versions => [] }), generate_workflow('python'),
		'empty list means default');
	is(generate_workflow('python', {}), generate_workflow('python'),
		'no versions means default');
	ok(!defined generate_workflow('cobol', { versions => ['1'] }), 'unknown type is undef');

	throws_ok { generate_workflow('node', { versions => ["1\n  evil: x"] }) }
		qr/Invalid version/, 'unsafe version croaks';

	like(generate_workflow('perl', { versions => ['5.38'] }), qr/["']5\.38["']/,
		'perl honours versions');
};

done_testing();
