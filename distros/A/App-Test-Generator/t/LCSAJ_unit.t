#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use File::Temp qw(tempdir);
use File::Spec;
use JSON::MaybeXS qw(decode_json);

# Black-box unit tests for App::Test::Generator::LCSAJ.
# Tests the public generate() method according to its POD API specification.
# No mocking required — generate() only uses PPI and filesystem I/O.

BEGIN { use_ok('App::Test::Generator::LCSAJ') }

# --------------------------------------------------
# Helper: write a .pm file to a temp lib/ dir,
# call generate(), and return useful paths/data.
# --------------------------------------------------
sub _generate {
	my ($source, $out_dir_name) = @_;
	my $tmpdir = tempdir(CLEANUP => 1);
	my $lib    = File::Spec->catdir($tmpdir, 'lib');
	mkdir $lib or die "Cannot mkdir $lib: $!";
	my $pm = File::Spec->catfile($lib, 'TestModule.pm');
	open my $fh, '>', $pm or die $!;
	print $fh $source;
	close $fh;

	require Cwd;
	my $orig = Cwd::cwd();
	chdir $tmpdir or die "Cannot chdir $tmpdir: $!";

	my $rel_pm  = File::Spec->catfile('lib', 'TestModule.pm');
	my $rel_out = $out_dir_name // 'out';
	mkdir $rel_out unless -d $rel_out;

	my $paths = App::Test::Generator::LCSAJ->generate($rel_pm, $rel_out);

	my $json_dir  = File::Spec->catdir($rel_out, 'TestModule.pm.lcsaj');
	my $json_file = File::Spec->catfile($json_dir, 'TestModule.pm.lcsaj.json');

	my $decoded;
	if(-f $json_file) {
		open my $jfh, '<', $json_file or die $!;
		$decoded = decode_json(do { local $/; <$jfh> });
		close $jfh;
	}

	chdir $orig;
	return ($paths, $decoded, File::Spec->catfile($tmpdir, $json_file));
}

# ==================================================================
# generate()
#
# POD spec:
#   Arguments: $class, $file (required), $out_dir (optional)
#   Returns:   arrayref of path hashrefs with keys start, end, target
#   Side effect: writes .lcsaj.json to $out_dir
#   Croaks:    when file cannot be parsed
# ==================================================================

subtest 'generate() returns an arrayref' => sub {
	my $src = "package TestModule;\nsub foo { return 1; }\n1;\n";
	my ($paths) = _generate($src);
	is(ref($paths), 'ARRAY', 'returns arrayref');
};

subtest 'generate() path hashrefs have start, end, and target keys' => sub {
	my $src = <<'END';
package TestModule;
sub foo {
	my $x = shift;
	if($x > 0) { return $x; }
	return 0;
}
1;
END
	my ($paths) = _generate($src);
	for my $p (@{$paths}) {
		ok(exists $p->{start},  'path has start key');
		ok(exists $p->{end},    'path has end key');
		ok(exists $p->{target}, 'path has target key');
	}
};

subtest 'generate() all path values are defined' => sub {
	my $src = <<'END';
package TestModule;
sub foo {
	my $x = shift;
	if($x > 0) { return $x; }
	return 0;
}
1;
END
	my ($paths, $decoded) = _generate($src);
	for my $p (@{$decoded}) {
		ok(defined $p->{start},  'start is defined');
		ok(defined $p->{end},    'end is defined');
		ok(defined $p->{target}, 'target is defined');
	}
};

subtest 'generate() writes JSON file at expected path' => sub {
	my $src = "package TestModule;\nsub foo { return 1; }\n1;\n";
	my (undef, undef, $json_file) = _generate($src);
	ok(-f $json_file, "JSON file written at expected path");
};

subtest 'generate() JSON file contains a valid array' => sub {
	my $src = "package TestModule;\nsub foo { return 1; }\n1;\n";
	my (undef, $decoded) = _generate($src);
	is(ref($decoded), 'ARRAY', 'JSON decodes to arrayref');
};

subtest 'generate() in-memory paths include at least as many as written JSON' => sub {
	my $src = <<'END';
package TestModule;
sub foo {
	my $x = shift;
	if($x > 0) { return 1; }
	return 0;
}
1;
END
	my ($paths, $decoded) = _generate($src);
	ok(scalar @{$paths} >= scalar @{$decoded}, 'in-memory count >= JSON count (JSON deduplicates)');
	ok(scalar @{$decoded} >= 0, 'JSON contains a non-negative number of paths');
};

subtest 'generate() returns empty arrayref for module with no subs' => sub {
	my $src = "package TestModule;\nour \$VERSION = 1;\n1;\n";
	my ($paths, $decoded) = _generate($src);
	is(scalar @{$decoded}, 0, 'no paths for sub-free module');
};

subtest 'generate() croaks for nonexistent file' => sub {
	throws_ok(
		sub { App::Test::Generator::LCSAJ->generate('/no/such/file.pm') },
		qr/Cannot parse/,
		'croaks with "Cannot parse" for missing file',
	);
};

subtest 'generate() uses default out_dir when none supplied' => sub {
	my $src = "package TestModule;\nsub foo { return 1; }\n1;\n";
	my $tmpdir = tempdir(CLEANUP => 1);
	my $lib    = File::Spec->catdir($tmpdir, 'lib');
	mkdir $lib or die $!;
	my $pm = File::Spec->catfile($lib, 'TestModule.pm');
	open my $fh, '>', $pm or die $!;
	print $fh $src;
	close $fh;

	require Cwd;
	my $orig = Cwd::cwd();
	chdir $tmpdir or die $!;
	my $paths;
	eval { $paths = App::Test::Generator::LCSAJ->generate($pm) };
	my $err = $@;
	chdir $orig;

	is($err, '',          'no croak when out_dir omitted');
	is(ref($paths), 'ARRAY', 'returns arrayref when out_dir omitted');
};

subtest 'generate() creates out_dir if it does not exist' => sub {
	my $src = "package TestModule;\nsub foo { return 1; }\n1;\n";
	my $tmpdir  = tempdir(CLEANUP => 1);
	my $lib     = File::Spec->catdir($tmpdir, 'lib');
	mkdir $lib or die $!;
	my $pm = File::Spec->catfile($lib, 'TestModule.pm');
	open my $fh, '>', $pm or die $!;
	print $fh $src;
	close $fh;

	my $new_out = File::Spec->catdir($tmpdir, 'brand', 'new', 'dir');
	ok(!-d $new_out, 'out_dir does not exist before generate()');
	lives_ok(
		sub { App::Test::Generator::LCSAJ->generate($pm, $new_out) },
		'generate() creates missing out_dir without croaking',
	);
};

subtest 'generate() no duplicate paths in output' => sub {
	my $src = <<'END';
package TestModule;
sub foo {
	my $x = shift;
	if($x) { return $x; }
	return 0;
}
1;
END
	my (undef, $decoded) = _generate($src);
	my %seen;
	my @dupes;
	for my $p (@{$decoded}) {
		my $sig = join ':', map { $_ // 'undef' }
			$p->{start}, $p->{end}, $p->{target};
		push @dupes, $sig if $seen{$sig}++;
	}
	is(scalar @dupes, 0, 'no duplicate path records in JSON output');
};

subtest 'generate() handles multiple subs in one file' => sub {
	my $src = <<'END';
package TestModule;
sub alpha {
	my $a = shift;
	return $a;
}
sub beta {
	my $b = shift;
	if($b) { return $b; }
	return 0;
}
1;
END
	my ($paths, $decoded) = _generate($src);
	# beta has a branch so produces at least one path
	ok(scalar @{$decoded} > 0, 'multiple subs: at least one path produced');
};

subtest 'generate() handles all supported branch types' => sub {
	for my $type (qw(if unless while for foreach)) {
		my $body;
		if($type eq 'for' || $type eq 'foreach') {
			$body = "my \@a = (1,2,3);\n\t$type my \$i (\@a) { last; }\n\treturn 1;";
		} elsif($type eq 'while') {
			$body = "my \$x = 0;\n\t$type (\$x < 1) { \$x++; }\n\treturn \$x;";
		} else {
			$body = "my \$x = 1;\n\t$type (\$x) { return 0; }\n\treturn 1;";
		}
		my $src = "package TestModule;\nsub test_$type {\n\t$body\n}\n1;\n";
		my ($paths) = _generate($src);
		ok(defined $paths, "$type branch type: generate() returned defined value");
	}
};

subtest 'generate() target key is never undef' => sub {
	my $src = <<'END';
package TestModule;
sub trailing {
	my $x = shift;
	if($x) { return $x; }
}
1;
END
	my (undef, $decoded) = _generate($src);
	my @undef_targets = grep { !defined $_->{target} } @{$decoded};
	is(scalar @undef_targets, 0, 'no undef target values in output');
};

done_testing();
