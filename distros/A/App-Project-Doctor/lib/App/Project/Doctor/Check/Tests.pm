package App::Project::Doctor::Check::Tests;

# This check verifies that the distribution has a working test suite.
# It runs in three stages: (1) does t/ exist? (2) are there .t files?
# (3) does 'prove -l' exit 0?  The first two failures are auto-fixable.

use strict;
use warnings;
use autodie qw(:all);

# Inherit the standard interface from Check::Base.
use parent -norequire, 'App::Project::Doctor::Check::Base';

# croak reports errors at the caller's location, not inside this module.
use Carp qw(croak carp);
# File::Path::make_path creates directory trees in the fix closure.
use File::Path ();
# File::Spec builds cross-platform file paths (forward slashes on Windows too).
use File::Spec;
# Readonly makes constants truly immutable at runtime.
use Readonly;

our $VERSION = '0.02';

# The prove command to run.  --nocolor avoids ANSI codes in the captured output.
Readonly::Scalar my $PROVE_CMD => 'prove -l --nocolor 2>&1';

# Short name used in Finding.check_name and report column headings.
sub name        { 'Tests' }
# One-line description shown in verbose / help output.
sub description { 'Test suite exists, contains .t files, and passes cleanly.' }
# This check can offer an automated fix (scaffold a smoke test).
sub can_fix     { 1 }
# Run first; everything else depends on a working test suite.
sub order       { 10 }

sub check {
	my ($self, $ctx) = @_;
	# Require a Context object so we can use its filesystem helpers.
	croak 'check requires an App::Project::Doctor::Context' unless ref $ctx;

	# -----------------------------------------------------------------------
	# Stage 1: the t/ directory must exist.
	# -----------------------------------------------------------------------
	unless ($ctx->has_file('t')) {
		# No t/ at all -- return immediately with a fixable error.
		return _f(
			severity => 'error',
			message  => 'No t/ directory -- distribution has no test suite.',
			fix      => _fix_scaffold($ctx),
		);
	}

	# -----------------------------------------------------------------------
	# Stage 2: at least one .t file must be in t/.
	# -----------------------------------------------------------------------
	my $test_files = $ctx->test_files;
	unless (@{$test_files}) {
		# The directory exists but is empty of test files.
		return _f(
			severity => 'error',
			message  => 't/ directory exists but contains no .t files.',
			fix      => _fix_scaffold($ctx),
		);
	}

	# -----------------------------------------------------------------------
	# Stage 3: run prove and check the exit status.
	# -----------------------------------------------------------------------
	# We use Perl's chdir instead of shell 'cd && prove' because quotemeta
	# on a Windows path (C:\Tmp) produces C\:\\Tmp which cmd.exe rejects.
	my $root = $ctx->root;
	require Cwd;
	my $orig   = Cwd::cwd();    # Save the current directory so we can restore it.
	chdir $root;
	my $output = qx{$PROVE_CMD};    # Capture all prove output for the detail field.
	my $status = $?;                # $? holds the child process exit status.
	chdir $orig;                    # Always restore the working directory.

	if ($status != 0) {
		# prove reported failures; include the captured output as detail.
		return _f(
			severity => 'error',
			message  => sprintf('Test suite FAILED (%d file(s) with failures).', scalar @{$test_files}),
			detail   => $output,
		);
	}

	# All stages passed -- report success with the file count.
	return _f(
		severity => 'pass',
		message  => sprintf('%d test file(s) found -- all pass.', scalar @{$test_files}),
	);
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

# Purpose:    Build a Finding with check_name pre-filled to 'Tests'.
# Entry:      %args is a valid Finding constructor argument list.
# Exit:       App::Project::Doctor::Finding object.
# Side effects: None.
sub _f {
	require App::Project::Doctor::Finding;
	return App::Project::Doctor::Finding->new(check_name => 'Tests', @_);
}

# Purpose:    Return a coderef that creates a minimal t/00-smoke.t scaffold.
# Entry:      $ctx is the current App::Project::Doctor::Context.
# Exit:       Coderef ($ctx) -> void; creates t/ and t/00-smoke.t on disk.
# Side effects: Creates directories and files under $ctx->root.
sub _fix_scaffold {
	my $ctx = shift;
	# Return the fix as a closure so it captures $ctx without running now.
	return sub {
		# Build the absolute path to the t/ directory.
		my $t_dir = File::Spec->catdir($ctx->root, 't');
		# make_path creates the directory and any missing parent directories.
		File::Path::make_path($t_dir);
		# The smoke test file that will be written.
		my $smoke = File::Spec->catfile($t_dir, '00-smoke.t');
		open my $fh, '>', $smoke;
		# Write a minimal but valid Test::More script that always passes.
		print {$fh} <<'END_SMOKE';
use strict;
use warnings;
use Test::More;

ok(1, 'module loads');
done_testing;
END_SMOKE
		close $fh;
	};
}

1;

__END__

=head1 NAME

App::Project::Doctor::Check::Tests - Check that a test suite exists and passes

=head1 VERSION

0.02

=head1 SYNOPSIS

  my $check    = App::Project::Doctor::Check::Tests->new;
  my @findings = $check->check($ctx);

=head1 DESCRIPTION

Three-stage check: (1) C<t/> directory present, (2) at least one C<.t> file
present, (3) C<prove -l> exits 0.  A missing test suite generates a fixable
finding that creates a minimal C<t/00-smoke.t> scaffold.

=head1 METHODS

=head2 check( $context )

=head3 API SPECIFICATION

=head4 Input

  $context : App::Project::Doctor::Context

=head4 Output

  List of App::Project::Doctor::Finding (at most one per stage)

=head3 MESSAGES

  Code | Trigger                     | Resolution
  -----|-----------------------------|-----------------------------------------
  T001 | t/ missing                  | Fix creates t/ and a minimal t/00-smoke.t
  T002 | t/ present, no .t files     | Fix creates a minimal t/00-smoke.t
  T003 | prove exits non-zero        | Fix failing tests manually

=head3 FORMAL SPECIFICATION

  check : Context -> [Finding]
  check ctx ==
    if not exists "t/"         then [error+fix]
    else if |test_files| = 0   then [error+fix]
    else if prove_fails        then [error]
    else                            [pass]

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENSE

Copyright (C) 2026 Nigel Horne.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
