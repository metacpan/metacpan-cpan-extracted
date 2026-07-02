package App::Project::Doctor::Check::CI;

# This check answers a single question: does the distribution have any CI
# configuration at all?  The detailed per-file validation of GitHub Actions
# YAML is handled separately by Check::GitHubActions.

use strict;
use warnings;
use autodie qw(:all);

# Inherit the standard check interface (name, description, order, can_fix, check).
use parent -norequire, 'App::Project::Doctor::Check::Base';

# croak dies with the caller's file/line instead of this module's line.
use Carp qw(croak);
# File::Spec builds OS-portable paths so the fix works on Windows too.
use File::Spec;
# Readonly creates true constants; assigning to them throws at runtime.
use Readonly;

our $VERSION = '0.02';

# Map human-readable CI system names to the path that indicates each one.
# The check passes as soon as any of these paths exists under the distro root.
Readonly::Hash my %CI_PATHS => (
	'GitHub Actions' => '.github/workflows',
	'Travis CI'      => '.travis.yml',
	'CircleCI'       => '.circleci/config.yml',
	'AppVeyor'       => 'appveyor.yml',
);

# Return the canonical name used in Finding check_name and report headings.
sub name        { 'CI' }
# One-line description shown in --help and verbose output.
sub description { 'At least one CI configuration is present.' }
# Signal that this check can offer an automated fix.
sub can_fix     { 1 }
# Lower number = runs earlier; CI runs after Tests (10) but before GitHubActions (25).
sub order       { 20 }

sub check {
	my ($self, $ctx) = @_;
	# Guard: $ctx must be an object with file-system helpers.
	croak 'check requires an App::Project::Doctor::Context' unless ref $ctx;

	# Walk through each known CI system and return a pass finding as soon as
	# we spot one.  We sort the keys so the result is deterministic.
	for my $label (sort keys %CI_PATHS) {
		if ($ctx->has_file($CI_PATHS{$label})) {
			# Found a CI config: report success and stop checking.
			return _f(
				severity => 'pass',
				message  => "CI configuration found ($label).",
			);
		}
	}

	# No CI config was found at all; offer to generate a GitHub Actions workflow.
	return _f(
		severity => 'error',
		message  => 'No CI configuration found (GitHub Actions, Travis, CircleCI, AppVeyor).',
		fix      => sub {
			# The fix creates .github/workflows/perl-ci.yml using the
			# App::GHGen::Generator functional API.
			my $root = $_[0]->root;
			require App::GHGen::Generator;
			# generate_workflow returns a YAML string or undef if it fails.
			my $yaml = App::GHGen::Generator::generate_workflow('perl');
			return unless $yaml;    # Nothing to write if generation failed.
			# Build the target directory path in a cross-platform way.
			my $wf_dir = File::Spec->catdir($root, '.github', 'workflows');
			require File::Path;
			# make_path creates the directory and all missing parents.
			File::Path::make_path($wf_dir);
			# Write the generated YAML to the standard workflow file.
			open my $fh, '>', File::Spec->catfile($wf_dir, 'perl-ci.yml');
			print {$fh} $yaml;
			close $fh;
		},
	);
}

# ---------------------------------------------------------------------------
# Private helper
# ---------------------------------------------------------------------------

# Purpose:    Build a Finding object pre-filled with check_name => 'CI'.
# Entry:      %args is a valid Finding constructor argument list.
# Exit:       App::Project::Doctor::Finding object.
# Side effects: None.
sub _f {
	require App::Project::Doctor::Finding;
	# Prepend check_name so callers don't have to repeat it every time.
	return App::Project::Doctor::Finding->new(check_name => 'CI', @_);
}

1;

__END__

=head1 NAME

App::Project::Doctor::Check::CI - Check that a CI configuration exists

=head1 DESCRIPTION

Reports an error when no supported CI configuration is found.  Detailed
GitHub Actions validation is handled by L<App::Project::Doctor::Check::GitHubActions>.

=head1 METHODS

=head2 check( $context )

Inspects the distro root for any recognised CI configuration.

=head3 API SPECIFICATION

=head4 Input

  $context : App::Project::Doctor::Context

=head4 Output

  List of exactly one App::Project::Doctor::Finding --
    pass    when at least one CI config file or directory is present,
    error   (fixable) when none are found.

=head3 MESSAGES

  Code | Trigger           | Resolution
  -----|-------------------|------------------------------------
  C001 | No CI config      | Fix generates a workflow via App::GHGen::Generator

=head3 FORMAL SPECIFICATION

  check : Context -> [Finding]
  check ctx == if exists any CI_PATH in ctx then [pass] else [error+fix]

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENSE

Copyright (C) 2026 Nigel Horne.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
