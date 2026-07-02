package App::Project::Doctor::Check::Pod;

# This check verifies that every .pm file under lib/ contains valid POD
# documentation.  It uses Pod::Checker to detect syntax errors.
# Modules with no POD at all get a fixable finding that writes a skeleton.

use strict;
use warnings;
use autodie qw(:all);

# Inherit the standard check interface from Check::Base.
use parent -norequire, 'App::Project::Doctor::Check::Base';

# croak dies with the caller's location; carp warns there.
use Carp qw(croak carp);

our $VERSION = '0.02';

# Short name used in Finding.check_name and text-report columns.
sub name        { 'POD' }
# One-line description for --help and verbose output.
sub description { 'Every .pm file contains valid, parseable POD documentation.' }
# This check can offer a fix (append a POD skeleton).
sub can_fix     { 1 }
# Run after Dependencies (50) but before Security (60).
sub order       { 40 }

sub check {
	my ($self, $ctx) = @_;
	# Guard: require a proper Context object.
	croak 'check requires an App::Project::Doctor::Context' unless ref $ctx;

	my @findings;
	# lib_modules() returns an arrayref of .pm paths relative to the distro root.
	my $modules = $ctx->lib_modules;

	# If there are no .pm files at all there is nothing to check.
	unless (@{$modules}) {
		return _f(
			severity => 'info',
			message  => 'No .pm files under lib/ -- nothing to check.',
		);
	}

	for my $mod (@{$modules}) {
		# Try to read the module source; skip it with a carp if reading fails.
		my $content = eval { $ctx->slurp($mod) } // do { carp "Cannot slurp $mod: $@"; next };

		# Quick check: does the file contain any POD at all?
		# A line beginning with '=' followed by a word character starts a POD block.
		unless ($content =~ /^=\w/m) {
			# No POD found -- offer to append a skeleton.
			push @findings, _f(
				severity => 'error',
				message  => "No POD found in $mod.",
				file     => $mod,
				fix      => _fix_scaffold_pod($ctx, $mod),
			);
			# No point running Pod::Checker on a file with no POD at all.
			next;
		}

		# Validate the existing POD with Pod::Checker and collect any errors.
		for my $err (_check_pod($ctx->abs_path($mod))) {
			push @findings, _f(
				severity => 'error',
				message  => "POD error in $mod: $err->{message}",
				file     => $mod,
				# Only include a line number when Pod::Checker provided one.
				defined $err->{line} ? (line => $err->{line}) : (),
			);
		}
	}

	# If we collected no error findings, all modules have valid POD.
	unless (@findings) {
		push @findings, _f(
			severity => 'pass',
			message  => sprintf('%d module(s) checked -- all have valid POD.', scalar @{$modules}),
		);
	}

	return @findings;
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

# Purpose:    Create a Finding with check_name pre-filled to 'POD'.
# Entry:      %args is a valid Finding constructor argument list.
# Exit:       App::Project::Doctor::Finding object.
# Side effects: None.
sub _f {
	require App::Project::Doctor::Finding;
	return App::Project::Doctor::Finding->new(check_name => 'POD', @_);
}

# Purpose:    Run Pod::Checker on a single file and return a list of errors.
# Entry:      $abs_path is the absolute path to the .pm file to check.
# Exit:       List of hashrefs with 'message' string and optional 'line' int.
# Side effects: Loads Pod::Checker if not already in memory; writes to an in-memory
#               filehandle (no disk I/O).
sub _check_pod {
	my $abs_path = shift;
	require Pod::Checker;

	# Capture Pod::Checker's diagnostic output into a scalar instead of STDERR.
	my $captured = '';
	open my $out_fh, '>', \$captured;
	my $checker = Pod::Checker->new;
	$checker->parse_from_file($abs_path, $out_fh);
	close $out_fh;

	# If Pod::Checker reported no errors, return an empty list immediately.
	return () if ($checker->num_errors // 0) == 0;

	# Parse the captured text output to extract individual error messages.
	my @errors;
	for my $line (split /\n/, $captured) {
		# Skip blank lines in the checker output.
		next unless $line =~ /\S/;
		# Try to extract the line number from the Pod::Checker message.
		my ($lineno) = $line =~ /line\s+(\d+)/i;
		push @errors, {
			message => $line,
			# Only include 'line' in the hashref when we actually found one.
			defined $lineno ? (line => $lineno) : (),
		};
	}
	return @errors;
}

# Purpose:    Return a coderef that rewrites a module file with a POD skeleton.
# Entry:      $ctx is the Context; $rel_path is the module path relative to root.
# Exit:       Coderef ($ctx) -> void; rewrites the module file with POD appended.
# Side effects: Modifies the module file on disk when the coderef is called.
sub _fix_scaffold_pod {
	my ($ctx, $rel_path) = @_;
	# Return the fix as a closure so it runs only when the user accepts it.
	return sub {
		# Protect caller's $@ from autodie's internal eval inside open().
		local $@;
		my $abs = $ctx->abs_path($rel_path);
		# Convert the relative file path to a Perl package name.
		# e.g. lib/My/Module.pm -> My::Module
		(my $pkg = $rel_path) =~ s{^lib/}{}; $pkg =~ s{/}{::}g; $pkg =~ s{\.pm$}{};

		# Read the existing file so we can rewrite it (not just append).
		open my $rfh, '<', $abs;
		my $content = do { local $/; <$rfh> };
		close $rfh;

		# Remove any trailing `1;` so the rewritten file has exactly one.
		# Without this, the original `1;` and the skeleton's `1;` would both appear.
		$content =~ s/\s*\n?1;\s*\z//s;

		# Write the existing content back followed by the POD skeleton.
		open my $wfh, '>', $abs;
		print {$wfh} $content, <<"END_POD";

1;

__END__

=head1 NAME

$pkg - (description goes here)

=head1 SYNOPSIS

  use $pkg;

=head1 DESCRIPTION

(description goes here)

=head1 AUTHOR

Nigel Horne C<< <njh\@nigelhorne.com> >>

=head1 LICENSE

Copyright (C) 2026 Nigel Horne.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
END_POD
		close $wfh;
	};
}

1;

__END__

=head1 NAME

App::Project::Doctor::Check::Pod - Check POD presence and validity in all modules

=head1 DESCRIPTION

Uses L<Pod::Checker> to validate every C<.pm> under C<lib/>.  Modules with no
POD at all get a fixable finding that appends a minimal skeleton.

=head3 MESSAGES

  Code | Trigger                  | Resolution
  -----|--------------------------|-----------------------------------------------
  P001 | No POD in a .pm file     | Fix appends a skeleton; fill in by hand
  P002 | Pod::Checker error       | Correct the malformed POD

=head3 FORMAL SPECIFICATION

  check : Context -> [Finding]
  check ctx ==
    concat [ check_one m | m <- lib_modules ctx ]
    where check_one m ==
            (if no_pod m then [error+fix] else [])
            ++ pod_errors m

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENSE

Copyright (C) 2026 Nigel Horne.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
