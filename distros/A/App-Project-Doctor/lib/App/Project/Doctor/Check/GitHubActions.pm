package App::Project::Doctor::Check::GitHubActions;

# This check validates that GitHub Actions workflow files are present and
# syntactically correct.  It uses App::Workflow::Lint for the actual YAML
# validation.  Note: it does NOT own the "missing CI entirely" error --
# that belongs to Check::CI.  When the workflow directory is absent this
# check emits only an informational finding.

use strict;
use warnings;
use autodie qw(:all);

# Inherit the standard check interface from Check::Base.
use parent -norequire, 'App::Project::Doctor::Check::Base';

# croak dies at the caller's location; carp warns there.
use Carp qw(croak carp);
# File::Spec builds OS-portable paths for the fix closure.
use File::Spec;
# Readonly makes constants truly immutable at runtime.
use Readonly;

our $VERSION = '0.02';

# The directory under the repo root where workflow files live.
Readonly::Scalar my $WORKFLOW_DIR => '.github/workflows';

# Short name used in Finding.check_name and the text-report column.
sub name        { 'GitHub Actions' }
# One-line description for --help and verbose output.
sub description { 'Workflow files are present and lint cleanly.' }
# This check can offer a fix (generate a workflow) when no files exist.
sub can_fix     { 1 }
# Run after CI (20) but before Meta (30).
sub order       { 25 }

sub check {
	my ($self, $ctx) = @_;
	# Guard: require a proper Context object with filesystem helpers.
	croak 'check requires an App::Project::Doctor::Context' unless ref $ctx;

	my @findings;

	# If the workflow directory doesn't exist at all, emit info and stop.
	# Check::CI already emits the error for a missing CI setup.
	unless ($ctx->has_file($WORKFLOW_DIR)) {
		return _f(
			severity => 'info',
			message  => 'No .github/workflows/ -- skipping GitHub Actions validation.',
		);
	}

	# The directory exists; find all YAML files inside it.
	my $workflow_files = $ctx->find_files($WORKFLOW_DIR, qr/\.ya?ml$/i);

	# Directory present but empty of YAML: warn and offer to generate a default workflow.
	unless (@{$workflow_files}) {
		return _f(
			severity => 'warning',
			message  => '.github/workflows/ exists but contains no YAML files.',
			fix      => _fix_generate($ctx),
		);
	}

	# Lint each workflow file and collect errors.
	for my $wf (@{$workflow_files}) {
		my @errors = _lint_workflow($ctx->abs_path($wf));
		for my $err (@errors) {
			# Each lint error becomes a separate Finding with file and optional line.
			push @findings, _f(
				severity => 'error',
				message  => "Workflow '$wf': $err->{message}",
				file     => $wf,
				defined $err->{line} ? (line => $err->{line}) : (),
			);
		}
	}

	# Only add a pass finding when no errors were collected.
	unless (@findings) {
		push @findings, _f(
			severity => 'pass',
			message  => sprintf('%d workflow file(s) validated OK.', scalar @{$workflow_files}),
		);
	}

	return @findings;
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

# Purpose:    Create a Finding with check_name pre-filled to 'GitHub Actions'.
# Entry:      %args is a valid Finding constructor argument list.
# Exit:       App::Project::Doctor::Finding object.
# Side effects: None.
sub _f {
	require App::Project::Doctor::Finding;
	return App::Project::Doctor::Finding->new(check_name => 'GitHub Actions', @_);
}

# Purpose:    Run App::Workflow::Lint against a single workflow file and
#             normalise its output into a consistent list of error hashrefs.
# Entry:      $abs_path is the absolute path to the YAML file being linted.
# Exit:       List of hashrefs, each with 'message' (string) and optional 'line' (int).
# Side effects: Loads App::Workflow::Lint if not already in memory.
sub _lint_workflow {
	my $abs_path = shift;
	require App::Workflow::Lint;
	# App::Workflow::Lint is instantiated fresh per call to avoid any state leakage.
	my $linter = App::Workflow::Lint->new;
	my @raw    = $linter->lint($abs_path);

	# Normalise: linter may return hashrefs OR plain strings.
	return map {
		ref $_ eq 'HASH'
			? {
				# Use the message key when present; fall back to a generic string.
				message => $_->{message} // '(unknown lint error)',
				# Only include 'line' when the linter actually provided one.
				(defined $_->{line} ? (line => $_->{line}) : ()),
			  }
			: { message => "$_" }    # Plain string errors have no line number.
	} @raw;
}

# Purpose:    Return a coderef that generates a GitHub Actions workflow file.
# Entry:      $ctx is the current App::Project::Doctor::Context.
# Exit:       Coderef ($ctx) -> void; creates .github/workflows/perl-ci.yml.
# Side effects: Creates directories and files under $ctx->root when called.
sub _fix_generate {
	my $ctx = shift;
	# Return the fix as a closure; it captures $ctx but does not run yet.
	return sub {
		my $root = $ctx->root;
		require App::GHGen::Generator;
		# generate_workflow returns a YAML string or undef on failure.
		my $yaml = App::GHGen::Generator::generate_workflow('perl');
		return unless $yaml;    # Nothing to write if generation failed.
		# Build the target directory path in a cross-platform way.
		my $wf_dir = File::Spec->catdir($root, '.github', 'workflows');
		require File::Path;
		# make_path creates .github/ and .github/workflows/ if they don't exist.
		File::Path::make_path($wf_dir);
		# Write the generated YAML to the standard workflow file name.
		open my $fh, '>', File::Spec->catfile($wf_dir, 'perl-ci.yml');
		print {$fh} $yaml;
		close $fh;
	};
}

1;

__END__

=head1 NAME

App::Project::Doctor::Check::GitHubActions - Validate GitHub Actions workflows

=head1 DESCRIPTION

Uses L<App::Workflow::Lint> to validate every C<.yml>/C<.yaml> file under
C<.github/workflows/>.  A fix via L<App::GHGen::Generator> is offered when no files exist.

=head1 METHODS

=head2 check( $context )

Validates all GitHub Actions workflow YAML files.

=head3 API SPECIFICATION

=head4 Input

  $context : App::Project::Doctor::Context

=head4 Output

  List of App::Project::Doctor::Finding --
    info    when .github/workflows/ is absent (CI check owns the error),
    warning (fixable) when directory exists but contains no YAML,
    one error per lint violation found,
    pass    when all workflow files validate cleanly.

=head3 MESSAGES

  Code | Trigger                       | Resolution
  -----|-------------------------------|-------------------------------------
  G001 | workflows/ has no YAML files  | Fix generates a workflow via App::GHGen::Generator
  G002 | Lint error in a workflow file | Edit the file to correct syntax

=head3 FORMAL SPECIFICATION

  check : Context -> [Finding]
  check ctx ==
    if not exists WORKFLOW_DIR then [info]
    else if |workflow_files| = 0 then [warning+fix]
    else concat { lint_errors f | f <- workflow_files }
         ++ (if all clean then [pass] else [])

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENSE

Copyright (C) 2026 Nigel Horne.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
