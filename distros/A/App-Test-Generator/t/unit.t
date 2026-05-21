#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird 0.10;
use File::Temp qw(tempdir tempfile);
use File::Spec;

BEGIN {
	use_ok('App::Test::Generator::Mutator');
	use_ok('App::Test::Generator::Mutant');
}

# --------------------------------------------------
# Shared minimal Perl source file used across
# multiple subtests
# --------------------------------------------------
my ($src_fh, $src_file) = tempfile(SUFFIX => '.pm', UNLINK => 1);
print {$src_fh} <<'PERL';
package Foo;
sub bar {
	my $x = shift;
	if($x > 0) {
		return 1;
	}
	return 0;
}
1;
PERL
close $src_fh;

# --------------------------------------------------
# Source file rooted under a lib/ directory, needed
# for prepare_workspace and apply_mutant tests where
# the relative path stripping must work correctly
# --------------------------------------------------
my $ws_tmpdir = tempdir(CLEANUP => 1);
my $ws_lib    = File::Spec->catdir($ws_tmpdir, 'lib');
File::Path::make_path($ws_lib);
my $ws_src    = File::Spec->catfile($ws_lib, 'Foo.pm');
open my $ws_fh, '>', $ws_src or die "Cannot write $ws_src: $!";
print {$ws_fh} <<'PERL';
package Foo;
sub bar { return 1; }
1;
PERL
close $ws_fh;

# --------------------------------------------------
# Helper: build a minimal no-op Mutant object
# --------------------------------------------------
sub _stub_mutant {
	my (%args) = @_;
	return App::Test::Generator::Mutant->new(
		id          => $args{id}          // 'TEST_1',
		file        => $args{file}        // $src_file,
		line        => $args{line}        // 1,
		description => $args{description} // 'stub mutant',
		original    => $args{original}    // '',
		transform   => $args{transform}   // sub {},
	);
}

# --------------------------------------------------
# Stub mutant factory for use in mocked strategy calls
# --------------------------------------------------
sub _make_stub_mutant {
	my ($line) = @_;
	return App::Test::Generator::Mutant->new(
		id          => "STUB_$line",
		file        => $src_file,
		line        => $line,
		description => 'stub',
		original    => 'x',
		transform   => sub {},
	);
}

# ==================================================================
# new()
# POD: croaks if file is missing or does not exist; returns a
# blessed App::Test::Generator::Mutator on success.
# ==================================================================
subtest 'Mutator::new - croaks when file argument omitted' => sub {
	# POD states file is required — omitting it must croak
	throws_ok {
		App::Test::Generator::Mutator->new()
	} qr/file required/, 'croaks with no file argument';

	done_testing();
};

subtest 'Mutator::new - croaks for non-existent file' => sub {
	throws_ok {
		App::Test::Generator::Mutator->new(file => '/no/such/file.pm')
	} qr/file not found/, 'croaks for missing file';

	done_testing();
};

subtest 'Mutator::new - returns blessed object for valid file' => sub {
	my $m = App::Test::Generator::Mutator->new(file => $src_file);
	isa_ok($m, 'App::Test::Generator::Mutator');

	done_testing();
};

subtest 'Mutator::new - lib_dir defaults to lib' => sub {
	my $m = App::Test::Generator::Mutator->new(file => $src_file);
	is($m->{lib_dir}, 'lib', 'lib_dir defaults to lib');

	done_testing();
};

subtest 'Mutator::new - mutation_level defaults to full' => sub {
	my $m = App::Test::Generator::Mutator->new(file => $src_file);
	is($m->{mutation_level}, 'full', 'mutation_level defaults to full');

	done_testing();
};

subtest 'Mutator::new - accepts custom lib_dir' => sub {
	my $m = App::Test::Generator::Mutator->new(
		file    => $src_file,
		lib_dir => 'src',
	);
	is($m->{lib_dir}, 'src', 'custom lib_dir accepted');

	done_testing();
};

subtest 'Mutator::new - accepts fast mutation_level' => sub {
	my $m = App::Test::Generator::Mutator->new(
		file           => $src_file,
		mutation_level => 'fast',
	);
	is($m->{mutation_level}, 'fast', 'fast mutation_level accepted');

	done_testing();
};

# ==================================================================
# generate_mutants()
# POD: returns a list of Mutant objects; lines within
# MUTANT_SKIP_BEGIN/END blocks are excluded; skip_lines
# hashref is populated after call; mismatched markers croak.
# ==================================================================
subtest 'Mutator::generate_mutants - returns list of mutants' => sub {
	my $guard = mock_scoped('App::Test::Generator::Mutator::system' => sub { 0 });

	my $m = App::Test::Generator::Mutator->new(file => $src_file);
	my @mutants = $m->generate_mutants();

	ok(scalar(@mutants) > 0, 'at least one mutant generated');
	for my $mutant (@mutants) {
		isa_ok($mutant, 'App::Test::Generator::Mutant');
	}

	done_testing();
};

subtest 'Mutator::generate_mutants - populates skip_lines hashref' => sub {
	my $guard = mock_scoped('App::Test::Generator::Mutator::system' => sub { 0 });

	my $m = App::Test::Generator::Mutator->new(file => $src_file);
	$m->generate_mutants();

	# POD states skip_lines is always set after the call
	is(ref($m->{skip_lines}), 'HASH', 'skip_lines is a hashref after call');

	done_testing();
};

subtest 'Mutator::generate_mutants - skip block excludes lines from mutants' => sub {
	my $guard = mock_scoped('App::Test::Generator::Mutator::system' => sub { 0 });

	my ($fh, $file) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print {$fh} <<'PERL';
package Skip;
sub safe {
	if(my $x > 0) { return 1; }
	return 0;
}
sub risky {
	## MUTANT_SKIP_BEGIN
	kill 'HUP', $$;
	waitpid $$, 0;
	## MUTANT_SKIP_END
	return 1;
}
1;
PERL
	close $fh;

	my $m = App::Test::Generator::Mutator->new(file => $file);
	my @mutants = $m->generate_mutants();

	# No mutant should reference a line inside the skip block
	my %skip = %{$m->{skip_lines}};
	for my $mutant (@mutants) {
		ok(!$skip{$mutant->line},
			'mutant line ' . $mutant->line . ' is not in skip block');
	}

	done_testing();
};

subtest 'Mutator::generate_mutants - unclosed MUTANT_SKIP_BEGIN croaks' => sub {
	my $guard = mock_scoped('App::Test::Generator::Mutator::system' => sub { 0 });

	my ($fh, $file) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print {$fh} <<'PERL';
package Bad;
sub x {
	## MUTANT_SKIP_BEGIN
	return 1;
}
1;
PERL
	close $fh;

	my $m = App::Test::Generator::Mutator->new(file => $file);
	throws_ok {
		$m->generate_mutants()
	} qr/MUTANT_SKIP_BEGIN/, 'unclosed MUTANT_SKIP_BEGIN croaks';

	done_testing();
};

subtest 'Mutator::generate_mutants - unmatched MUTANT_SKIP_END croaks' => sub {
	my $guard = mock_scoped('App::Test::Generator::Mutator::system' => sub { 0 });

	my ($fh, $file) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print {$fh} <<'PERL';
package Bad2;
sub x {
	return 1;
	## MUTANT_SKIP_END
}
1;
PERL
	close $fh;

	my $m = App::Test::Generator::Mutator->new(file => $file);
	throws_ok {
		$m->generate_mutants()
	} qr/MUTANT_SKIP_END/, 'unmatched MUTANT_SKIP_END croaks';

	done_testing();
};

subtest 'Mutator::generate_mutants - fast mode returns mutants' => sub {
	my $guard = mock_scoped('App::Test::Generator::Mutator::system' => sub { 0 });

	my $m = App::Test::Generator::Mutator->new(
		file           => $src_file,
		mutation_level => 'fast',
	);
	my @mutants = $m->generate_mutants();

	# fast mode must still return Mutant objects
	for my $mutant (@mutants) {
		isa_ok($mutant, 'App::Test::Generator::Mutant');
	}

	done_testing();
};

subtest 'Mutator::generate_mutants - fast mode no more mutants than full' => sub {
	my $guard = mock_scoped('App::Test::Generator::Mutator::system' => sub { 0 });

	my $fast = App::Test::Generator::Mutator->new(
		file           => $src_file,
		mutation_level => 'fast',
	);
	my $full = App::Test::Generator::Mutator->new(file => $src_file);

	my @fast_mutants = $fast->generate_mutants();
	my @full_mutants = $full->generate_mutants();

	ok(scalar(@fast_mutants) <= scalar(@full_mutants),
		'fast mode produces no more mutants than full mode');

	done_testing();
};

# ==================================================================
# prepare_workspace()
# POD: returns absolute path to temp directory; sets
# $self->{workspace} and $self->{relative}; croaks if dircopy fails.
# ==================================================================
subtest 'Mutator::prepare_workspace - returns a directory path' => sub {
	# Mock dircopy so we do not touch the real filesystem
	my $m = App::Test::Generator::Mutator->new(file => $src_file);
	my $path = $m->prepare_workspace();

	ok(defined $path, 'prepare_workspace returns a path');
	ok(-d $path,      'returned path is a directory');

	done_testing();
};

subtest 'Mutator::prepare_workspace - sets workspace on object' => sub {
	my $guard = mock_scoped(
		'File::Copy::Recursive::dircopy' => sub { 1 }
	);

	my $m = App::Test::Generator::Mutator->new(file => $src_file);
	my $path = $m->prepare_workspace();

	is($m->{workspace}, $path, 'workspace stored on object matches return value');

	done_testing();
};

subtest 'Mutator::prepare_workspace - sets relative path on object' => sub {
	my $guard = mock_scoped(
		'File::Copy::Recursive::dircopy' => sub { 1 }
	);

	my $m = App::Test::Generator::Mutator->new(file => $src_file);
	$m->prepare_workspace();

	ok(defined $m->{relative}, 'relative path set on object');

	done_testing();
};

subtest 'Mutator::prepare_workspace - croaks when dircopy fails' => sub {
	my $guard = mock_scoped(
		'App::Test::Generator::Mutator::dircopy' => sub { 0 }
	);

	my $m = App::Test::Generator::Mutator->new(file => $src_file);
	throws_ok {
		$m->prepare_workspace()
	} qr/dircopy failed/, 'croaks when dircopy fails';

	done_testing();
};

# ==================================================================
# apply_mutant()
# POD: croaks if workspace not prepared; overwrites workspace
# copy of target file with mutated version.
# ==================================================================
subtest 'Mutator::apply_mutant - croaks without prepare_workspace' => sub {
	my $m = App::Test::Generator::Mutator->new(file => $ws_src, lib_dir => $ws_lib);
	my $mutant = _stub_mutant();

	throws_ok {
		$m->apply_mutant($mutant)
	} qr/Workspace not prepared/, 'croaks when workspace not prepared';

	done_testing();
};

subtest 'Mutator::apply_mutant - applies transform to workspace file' => sub {
	my $guard = mock_scoped(
		'App::Test::Generator::Mutator::dircopy' => sub { 1 }
	);
	my $m = App::Test::Generator::Mutator->new(file => $ws_src, lib_dir => $ws_lib);
	$m->prepare_workspace();

	# Write the source file into the workspace at the expected path
	my $ws_lib_dir = File::Spec->catfile($m->{workspace}, 'lib');
	File::Path::make_path($ws_lib_dir);
	my $ws_file = File::Spec->catfile($ws_lib_dir, $m->{relative});
	File::Copy::copy($src_file, $ws_file);

	# Transform that marks the file with a known string
	my $transform_called = 0;
	my $mutant = _stub_mutant(
		transform => sub { $transform_called = 1 },
	);
	lives_ok {
		$m->apply_mutant($mutant)
	} 'apply_mutant lives with prepared workspace';
	ok($transform_called, 'transform coderef was called');
	done_testing();
};

done_testing();
