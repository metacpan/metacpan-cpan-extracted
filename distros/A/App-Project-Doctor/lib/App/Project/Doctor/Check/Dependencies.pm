package App::Project::Doctor::Check::Dependencies;

use strict;
use warnings;
use autodie qw(:all);

use parent -norequire, 'App::Project::Doctor::Check::Base';

use Carp qw(croak carp);
use Readonly;

our $VERSION = '0.02';

# Modules that ship with Perl core and need no prereq declaration.
# 'lib' and 'Cwd' are pragmas/modules commonly seen in source but not CPAN deps.
Readonly::Hash my %CORE => map { $_ => 1 } qw(
	strict warnings autodie Carp Scalar::Util List::Util POSIX Storable
	File::Spec File::Find File::Path File::Temp File::Basename File::Copy
	Data::Dumper Exporter base parent lib overload constant vars utf8 feature
	Getopt::Long Pod::Usage Params::Validate::Strict Params::Get Readonly
	Cwd Encode Fcntl IO::File IO::Handle
);

# Short name shown in check_name and report column headings.
sub name        { 'Dependencies' }
# One-line description for verbose and --help output.
sub description { 'All used modules are declared as build prerequisites.' }
# This check can auto-fix by appending a 'requires' line to cpanfile.
sub can_fix     { 1 }
# Run after POD (40) so dependency errors appear together at the end.
sub order       { 50 }

sub check {
	my ($self, $ctx) = @_;
	# Guard: $ctx must support has_file(), abs_path(), and perl_files().
	croak 'check requires an App::Project::Doctor::Context' unless ref $ctx;

	my @findings;

	# Try to parse the distribution's declared prerequisites.  Returns undef
	# when no supported builder file exists.
	my $declared = _collect_declared($ctx);
	unless (defined $declared) {
		# Without a builder file we cannot compare; warn rather than error
		# because the distribution might be using a non-standard build system.
		return _f(
			severity => 'warning',
			message  => 'No Makefile.PL, Build.PL, or cpanfile -- cannot check prerequisites.',
		);
	}

	# Collect every module referenced via 'use' or 'require' in source files.
	my $used = _collect_used($ctx);

	# Build the set of modules this distribution provides.  A module that
	# lives under lib/ is part of the distribution itself and cannot be its
	# own prerequisite -- flagging it would be a false positive.
	my %own_modules = map { _path_to_module($_) => 1 } @{ $ctx->lib_modules };

	# Any module that is used but neither declared nor bundled in Perl core
	# is a missing prerequisite -- users of the distribution won't have it.
	for my $mod (sort keys %{$used}) {
		next if $CORE{$mod};          # Core modules need no declaration.
		next if $declared->{$mod};    # Already listed as a prereq -- fine.
		next if $own_modules{$mod};   # Provided by this distribution itself.
		push @findings, _f(
			severity => 'error',
			message  => "Module '$mod' used in source but not declared as a prerequisite.",
			detail   => 'Found in: ' . join(', ', @{ $used->{$mod} }),
			fix      => _fix_add_prereq($ctx, $mod),
		);
	}

	# Only emit a pass finding when every used module is accounted for.
	unless (@findings) {
		push @findings, _f(
			severity => 'pass',
			message  => 'All non-core used modules are declared as prerequisites.',
		);
	}

	return @findings;
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

# Purpose:    Build a Finding with check_name pre-filled to 'Dependencies'.
# Entry:      %args is a valid Finding constructor argument list.
# Exit:       App::Project::Doctor::Finding object.
# Side effects: None.
sub _f {
	require App::Project::Doctor::Finding;
	# Prepend check_name so every call site stays concise.
	return App::Project::Doctor::Finding->new(check_name => 'Dependencies', @_);
}

# Purpose:    Scan source files for 'use' and 'require' statements and return
#             a map of module name -> list of files where it appears.
# Entry:      $ctx is a valid Context object with perl_files() support.
# Exit:       Hashref { module_name => [file, ...] }.
# Side effects: None (file reads are read-only).
sub _collect_used {
	my $ctx = shift;
	my %used;
	my $files = $ctx->perl_files('lib', 'script', 'bin');
	for my $rel (@{$files}) {
		my $content = eval { $ctx->slurp($rel) } // next;

		# Remove __END__ and __DATA__ sections.  Everything after either token
		# is non-executable and may contain stray 'use' keywords (e.g. in
		# embedded scripts or heredoc data) that are not real dependencies.
		$content =~ s/^__(?:END|DATA)__\b.*\z//ms;

		# Remove POD blocks before scanning.  A SYNOPSIS example such as
		#   "use L<Foo::Bar>"
		# fools the regex below into capturing 'L' as a module name because
		# '<' terminates the [\w:]+ match.  Each POD block runs from any
		# =word line to the matching =cut (or end of file if =cut is absent).
		$content =~ s/^=[a-z]\w*\b.*?(?:^=cut\b[^\n]*\n|\z)//gms;

		# Now scan what remains (executable code only) for load statements.
		while ($content =~ /^\s*(?:use|require)\s+([\w:]+)/mg) {
			my $mod = $1;
			next if $mod =~ /^\d/;    # bare version number, e.g. 'use 5.010'
			push @{ $used{$mod} }, $rel;
		}
	}
	return \%used;
}

# Purpose:    Parse the distribution's declared prerequisites from cpanfile
#             or Makefile.PL (via App::makefilepl2cpanfile).
# Entry:      $ctx is a valid Context object.
# Exit:       Hashref { module_name => 1 }, or undef when no builder file found.
# Side effects: May carp if App::makefilepl2cpanfile fails.
sub _collect_declared {
	my $ctx = shift;

	# cpanfile is the preferred format; check it first.
	if ($ctx->has_file('cpanfile')) {
		return _parse_cpanfile($ctx->abs_path('cpanfile'));
	}

	# Fall back to Makefile.PL by converting it to cpanfile syntax in memory.
	if ($ctx->has_file('Makefile.PL')) {
		my $text = eval {
			require App::makefilepl2cpanfile;
			App::makefilepl2cpanfile::generate(makefile => $ctx->abs_path('Makefile.PL'))
		};
		# Carp rather than die so a broken Makefile.PL doesn't abort the whole run.
		carp "App::makefilepl2cpanfile failed: $@" if $@;
		return defined $text ? _parse_cpanfile_text($text) : undef;
	}

	# No supported builder file found; caller will emit a warning.
	return undef;
}

# Purpose:    Parse a cpanfile on disk and return its required modules.
# Entry:      $path is the absolute path to a cpanfile.
# Exit:       Hashref { module_name => 1 }.
# Side effects: Opens and reads the file.
sub _parse_cpanfile {
	my $path = shift;
	my %mods;
	open my $fh, '<', $path;
	while (<$fh>) {
		# Match lines like: requires 'Foo::Bar';   or   requires "Foo::Bar" => '1.00';
		# \s* allows for indented requires inside 'on' phase blocks, e.g.:
		#   on 'runtime' => sub { requires 'Foo'; };
		$mods{$1} = 1 if /^\s*requires\s+['"]?([\w:]+)['"]?/;
	}
	close $fh;
	return \%mods;
}

# Purpose:    Parse an in-memory cpanfile string (produced by makefilepl2cpanfile).
# Entry:      $text is a cpanfile-format string.
# Exit:       Hashref { module_name => 1 }.
# Side effects: None.
sub _parse_cpanfile_text {
	my $text = shift;
	my %mods;
	# Use the same pattern as _parse_cpanfile but on a string instead of a file.
	# \s* handles indented requires inside 'on' phase blocks.
	for my $line (split /\n/, $text) {
		$mods{$1} = 1 if $line =~ /^\s*requires\s+['"]?([\w:]+)['"]?/;
	}
	return \%mods;
}

# Purpose:    Convert a lib/-relative file path to a Perl module name.
# Entry:      $rel is a path like 'lib/Foo/Bar.pm' (forward slashes, always).
# Exit:       String module name, e.g. 'Foo::Bar'.
# Side effects: None.
sub _path_to_module {
	my $rel = shift;
	# Strip the lib/ prefix, convert path separators to ::, remove .pm.
	$rel =~ s{^lib/}{};
	$rel =~ s{/}{::}g;
	$rel =~ s{\.pm$}{};
	return $rel;
}

# Purpose:    Return a coderef that appends a 'requires' line to cpanfile.
# Entry:      $ctx is the Context; $mod is the undeclared module name.
# Exit:       Coderef ($ctx) -> void; appends one line to cpanfile on disk.
# Side effects: Modifies cpanfile when the coderef is called.
sub _fix_add_prereq {
	my ($ctx, $mod) = @_;
	return sub {
		if ($ctx->has_file('cpanfile')) {
			# Append rather than rewrite so we don't disturb the existing content.
			open my $fh, '>>', $ctx->abs_path('cpanfile');
			print {$fh} "requires '$mod';\n";
			close $fh;
		} else {
			# We can only auto-fix cpanfile; Makefile.PL edits need human judgement.
			carp "Auto-fix for Makefile.PL not implemented; add '$mod' manually.";
		}
	};
}

1;

__END__

=head1 NAME

App::Project::Doctor::Check::Dependencies - Check that used modules are declared

=head1 DESCRIPTION

Scans all C<.pm>, C<.pl>, and script files for C<use>/C<require> statements
and compares against C<cpanfile> or C<Makefile.PL> prerequisites
(via L<App::makefilepl2cpanfile>).  Core modules are excluded.

=head3 MESSAGES

  Code | Trigger                      | Resolution
  -----|------------------------------|-------------------------------------------
  D001 | No builder or cpanfile found | Add a Makefile.PL or cpanfile
  D002 | Module used but not declared | Fix appends a 'requires' line to cpanfile

=head3 FORMAL SPECIFICATION

  used     = { mod | (use|require mod) in source_files ctx }
  declared = parse_prereqs (builder_file ctx)
  missing  = used \\ (declared union CORE)

  check ctx ==
    if declared = undef then [warning]
    else [error+fix per m in missing] ++ (if missing = {} then [pass] else [])

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENSE

Copyright (C) 2026 Nigel Horne.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
