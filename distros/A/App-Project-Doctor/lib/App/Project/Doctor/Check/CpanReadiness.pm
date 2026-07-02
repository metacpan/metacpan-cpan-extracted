package App::Project::Doctor::Check::CpanReadiness;

use strict;
use warnings;
use autodie qw(:all);

use parent -norequire, 'App::Project::Doctor::Check::Base';

use Carp qw(croak carp);
use Readonly;

our $VERSION = '0.02';

Readonly::Scalar my $VERSION_RE    => qr/^\d+\.\d+(?:\.\d+)?(?:_\d+)?$/;
# Changes and MANIFEST must use these exact names; README accepts variants below.
Readonly::Array  my @REQUIRED_FILES  => qw(Changes MANIFEST);
# CPAN and GitHub both accept any of these forms as the distribution README.
Readonly::Array  my @README_VARIANTS => qw(README README.md README.pod README.rst README.txt);

sub name        { 'CPAN Readiness' }
sub description { 'Version format, Changes, MANIFEST, and a README variant are present.' }
sub can_fix     { 0 }
sub order       { 90 }

sub check {
	my ($self, $ctx) = @_;
	croak 'check requires an App::Project::Doctor::Context' unless ref $ctx;

	my @findings;

	# Version format check.
	my $version = _read_version($ctx);
	if (defined $version) {
		if ($version !~ $VERSION_RE) {
			push @findings, _f(
				severity => 'error',
				message  => "Version '$version' does not match CPAN format (X.YY or X.YY.ZZ).",
			);
		}
	} else {
		push @findings, _f(
			severity => 'warning',
			message  => 'Could not determine distribution version from any module.',
		);
	}

	# Required release files (exact names required by CPAN toolchain).
	for my $file (@REQUIRED_FILES) {
		unless ($ctx->has_file($file)) {
			push @findings, _f(
				severity => 'error',
				message  => "'$file' is missing from the distribution root.",
			);
		}
	}

	# README is required but any common variant is acceptable.  README.md is the
	# norm on GitHub; CPAN itself accepts all of these without complaint.
	unless (grep { $ctx->has_file($_) } @README_VARIANTS) {
		push @findings, _f(
			severity => 'error',
			message  => 'README is missing -- none of ' . join(', ', @README_VARIANTS) . ' found.',
		);
	}

	# Changes file must have at least one version entry.
	if ($ctx->has_file('Changes')) {
		my $content = $ctx->slurp('Changes');
		unless ($content =~ /^\d+\.\d+/m || $content =~ /^v\d+/m) {
			push @findings, _f(
				severity => 'warning',
				message  => 'Changes file has no version entries.',
				file     => 'Changes',
			);
		}
	}

	# MANIFEST stale-check requires 'make manifest' -- too invasive; just advise.
	if ($ctx->has_file('MANIFEST')) {
		push @findings, _f(
			severity => 'info',
			message  => "MANIFEST present -- run 'make manifest' to verify it is not stale.",
		);
	}

	# Emit a pass only when there are no errors or warnings.
	my $has_problem = grep { $_->severity =~ /^(?:error|warning)$/ } @findings;
	unless ($has_problem) {
		push @findings, _f(
			severity => 'pass',
			message  => 'Distribution meets basic CPAN readiness requirements.',
		);
	}

	return @findings;
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

sub _f {
	require App::Project::Doctor::Finding;
	return App::Project::Doctor::Finding->new(check_name => 'CPAN Readiness', @_);
}

sub _read_version {
	my $ctx = shift;
	for my $mod (@{ $ctx->lib_modules }) {
		my $content = eval { $ctx->slurp($mod) } // next;
		if (my ($v) = $content =~ /^\s*our\s+\$VERSION\s*=\s*['"]?([^'";\s]+)['"]?/m) {
			return $v;
		}
	}
	return undef;
}

1;

__END__

=head1 NAME

App::Project::Doctor::Check::CpanReadiness - Pre-upload CPAN readiness check

=head1 DESCRIPTION

Performs a final pre-flight sweep: version format, C<Changes>, C<MANIFEST>,
README presence, and basic C<Changes> content.

For the README requirement any of the following file names is accepted:
C<README>, C<README.md>, C<README.pod>, C<README.rst>, C<README.txt>.
An error is only raised when B<none> of these exist.

=head1 METHODS

=head2 check( $context )

=head3 API SPECIFICATION

=head4 Input

  $context : App::Project::Doctor::Context

=head4 Output

  List of App::Project::Doctor::Finding with severities:
    error   -- version format wrong, required file absent, no README variant found
    warning -- version undetermined, Changes has no version entries
    info    -- MANIFEST present (stale-check advisory)
    pass    -- all criteria met (only when no errors or warnings)

=head3 MESSAGES

  Code | Trigger                                   | Resolution
  -----|-------------------------------------------|-------------------------------------------
  R001 | Version format invalid                    | Use X.YY or X.YY.ZZ
  R002 | Changes or MANIFEST missing               | Create the file
  R003 | No README variant found                   | Add README, README.md, README.pod, etc.
  R004 | Changes has no version entries            | Add a changelog entry

=head3 FORMAL SPECIFICATION

  README_VARIANTS = {README, README.md, README.pod, README.rst, README.txt}

  check : Context -> [Finding]
  check ctx ==
    version_check ctx
    ++ [file_check f | f <- REQUIRED_FILES]
    ++ (if (exists v in README_VARIANTS: ctx has_file v) then [] else [error])
    ++ changes_check ctx
    ++ (if no problems then [pass] else [])

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENSE

Copyright (C) 2026 Nigel Horne.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
