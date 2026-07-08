package Devel::App::Test::Generator::LCSAJ::Runtime;

use strict;
use warnings;
use autodie     qw(open close);
use Carp        qw(croak);
use Cwd         qw(abs_path);
use JSON::MaybeXS;
use File::Path  qw(make_path);
use Readonly;

# --------------------------------------------------
# Output directory for per-process hit JSON files.
# One file is written per process (PID) so parallel
# test runs do not overwrite each other's output.
# --------------------------------------------------
Readonly my $OUT_DIR => 'cover_html/lcsaj_hits';

=head1 NAME

Devel::App::Test::Generator::LCSAJ::Runtime - Debugger backend for LCSAJ coverage

=encoding UTF-8

=head1 VERSION

Version 0.42

=cut

our $VERSION = '0.42';

=head1 SYNOPSIS

  PERL5OPT='-d:App::Test::Generator::LCSAJ::Runtime -Mblib' prove -l t

=head1 DESCRIPTION

This module is loaded as a Perl debugger backend using the C<-d:Module> flag.

When Perl sees C<-d:App::Test::Generator::LCSAJ::Runtime> it prepends C<Devel::>
and loads C<Devel/App/Test/Generator/LCSAJ/Runtime.pm> from C<@INC>.
The file must therefore live at that path - typically C<lib/Devel/App/Test/Generator/LCSAJ/Runtime.pm>.

Perl automatically calls C<DB::DB> before executing each statement while the
debugger is active. We record (file, line) pairs to build runtime hit data for
later LCSAJ analysis.

Results are written to C<cover_html/lcsaj_hits/hits_PID.json> at process exit,
one file per process so that parallel test runs do not overwrite each other.

=head1 ENVIRONMENT

=over 4

=item LCSAJ_TARGETS

Optional colon-separated list of B<absolute> paths (as produced by C<realpath>)
to restrict recording to specific source files. When empty or unset every
non-internal file is recorded.

=back

=cut

# --------------------------------------------------
# %HITS       - { normalised_path => { line_number => hit_count } }
# %TARGET     - set of normalised paths to record (empty means record everything)
# %NORM_CACHE - { raw_file => normalised_path }, memoises abs_path()
#               since DB::DB sees the same $file on every consecutive
#               statement within a source file
#
# These must be package globals (our) rather than lexicals because DB::DB
# is called by the Perl debugger infrastructure and needs to access them
# without a closure. Lexical vars would not be visible in DB::DB.
# --------------------------------------------------
our %HITS;
our %TARGET;
our %NORM_CACHE;

# --------------------------------------------------
# Populate %TARGET from LCSAJ_TARGETS at compile time.
# The env var contains absolute realpath() output
# separated by colons. Stray newlines from broken
# shell pipelines are stripped defensively.
# --------------------------------------------------
BEGIN {
	my $targets_env = $ENV{LCSAJ_TARGETS} // '';
	$targets_env =~ s/\n//g;

	for my $t (split /:/, $targets_env) {
		next unless length $t;

		# Inline normalisation — cannot call _normalize here since
		# BEGIN runs before named subs are compiled when BEGIN
		# appears at the top of the file
		my $f = $t;
		$f =~ s{^.*/blib/lib/}{lib/};
		$f =~ s{^.*/lib/}{lib/};
		$TARGET{$f} = 1;
	}
}

END {
	_write_results();
}

# --------------------------------------------------
# _normalize
#
# Purpose:    Convert an absolute or build-tree path
#             to a canonical lib-relative form so that
#             paths recorded at runtime match the
#             targets derived from LCSAJ_TARGETS.
#
# Entry:      $path - an absolute or relative file path.
#
# Exit:       Returns a lib-relative path string,
#             e.g. lib/Foo/Bar.pm
#
# Side effects: None.
#
# Notes:      Must be defined before the BEGIN block
#             that calls it, since BEGIN runs at compile
#             time and later subs may not yet be compiled.
#
# Examples:
#   /home/user/proj/blib/lib/Foo/Bar.pm  ->  lib/Foo/Bar.pm
#   /home/user/proj/lib/Foo/Bar.pm       ->  lib/Foo/Bar.pm
# --------------------------------------------------
sub _normalize {
	my $f = $_[0];

	# Strip everything up to and including blib/lib/ or lib/
	$f =~ s{^.*/blib/lib/}{lib/};
	$f =~ s{^.*/lib/}{lib/};
	return $f;
}

# --------------------------------------------------
# DB::DB
#
# Purpose:    Called by the Perl debugger before every
#             statement. Records (file, line) hits for
#             later LCSAJ coverage analysis.
#
# Entry:      No arguments — caller(0) is used to get
#             the current file and line number.
#
# Exit:       Returns nothing. Updates %HITS in place.
#
# Side effects: Increments %HITS{$norm}{$line}.
#
# Notes:      This sub lives in the DB:: package as
#             required by Perl's debugger protocol.
#             It is called for every statement executed
#             while the debugger is active, so it must
#             be as fast as possible.
#             Internal files and out-of-target files
#             are skipped immediately.
#             abs_path() resolution is memoised in
#             %NORM_CACHE per raw $file, since the same
#             file is seen on every consecutive statement.
# --------------------------------------------------
=head2 DB::DB

Perl debugger hook, automatically invoked by the interpreter before every
statement while this module is active as a C<-d:> debugger backend.
Records a per-(file, line) hit count used later for LCSAJ coverage
analysis.

=head3 Arguments

None. Perl calls this sub directly; the current execution location is
obtained internally via C<caller(0)>.

=head3 Returns

Nothing meaningful — this is a void debugger callback.

=head3 Side effects

Increments C<%HITS{$norm}{$line}> for the normalised path and line number
of the statement about to execute. Resolves each distinct raw filename
via C<Cwd::abs_path> once, memoising the result in C<%NORM_CACHE>.

=head3 Usage example

Not called directly — activated via the Perl debugger flag:

    PERL5OPT='-d:App::Test::Generator::LCSAJ::Runtime -Mblib' prove -l t

=head3 API specification

=head4 input

    { }

=head4 output

    { type => UNDEF }

=head3 Formal specification

Let H be the hits relation (file x line) → ℕ, T be the target-file set,
and I be the internal-file predicate (true only for this module's own
source path).

  ┌ DB_DB ──────────────────────────────────────────
  │ ΔH
  │ file? : FilePath
  │ line? : ℕ
  ├─────────────────────────────────────────────────
  │ norm == normalize(file?)
  │ ¬I(norm) ∧ (T = ∅ ∨ norm ∈ T)
  │   ⟹ H′(norm, line?) = H(norm, line?) + 1
  │ I(norm) ∨ (T ≠ ∅ ∧ norm ∉ T)
  │   ⟹ H′ = H
  └─────────────────────────────────────────────────

=cut

sub DB::DB {
	my (undef, $file, $line) = caller(0);

	return unless defined $file && defined $line;

	# Resolve symlinks and relative components to a stable absolute path,
	# cached per raw $file to avoid a stat() on every statement
	my $norm = $NORM_CACHE{$file} //= _normalize(abs_path($file) // $file);

	# Never record hits inside this module itself — suffix match is used
	# so it works regardless of CWD or install prefix
	return if $norm =~ m{(?:^|/)Devel/App/Test/Generator/LCSAJ/Runtime\.pm$};

	# If a target list was provided, skip files not in it
	if(%TARGET) {
		return unless $TARGET{$norm};
	}

	$HITS{$norm}{$line}++;
}

# --------------------------------------------------
# _write_results
#
# Purpose:    Serialise %HITS to a per-process JSON
#             file in the output directory.
#
# Entry:      None. Reads %HITS and $OUT_DIR.
#
# Exit:       Returns nothing. Writes a JSON file.
#             Returns immediately if %HITS is empty.
#
# Side effects: Creates $OUT_DIR if absent.
#               Writes cover_html/lcsaj_hits/hits_PID.json
#
# Notes:      Called from END so it runs even when
#             prove exits non-zero — mutation tests
#             are expected to fail. PID is included
#             in the filename so parallel test runs
#             produce separate files without collision.
# --------------------------------------------------
sub _write_results {
	return unless %HITS;

	# Include PID in filename to support parallel test runs
	my $out_file = "$OUT_DIR/hits_$$.json";

	make_path($OUT_DIR) unless -d $OUT_DIR;

	# autodie is disabled for this open -- under "use autodie qw(open)"
	# open() never returns false on failure, it throws its own exception
	# instead, which would silently make the "or croak" below dead code
	no autodie qw(open);
	open my $fh, '>', $out_file or croak "Cannot write $out_file: $!";

	print $fh encode_json(\%HITS);
	close $fh;
}

1;

__END__

=head1 OUTPUT FORMAT

C<cover_html/lcsaj_hits/hits_PID.json> is a JSON object of the form:

  {
    "lib/Foo/Bar.pm": { "12": 3, "15": 1, ... },
    ...
  }

Keys are lib-relative paths (C<lib/...>); values are objects mapping line
numbers (as strings) to hit counts. One file is written per process so
parallel test runs produce separate files.

=head1 NOTES ON FILE PLACEMENT

The C<-d:App::Test::Generator::LCSAJ::Runtime> flag causes Perl to load
C<Devel::App::Test::Generator::LCSAJ::Runtime>, which it finds at:

  lib/Devel/App/Test/Generator/LCSAJ/Runtime.pm

Ensure this path is on C<@INC> (C<-Mblib> or C<-Ilib> in PERL5OPT).

=head1 SEE ALSO

L<Devel::Cover>, L<App::Test::Generator>

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

Portions of this module's initial design and documentation were created
with the assistance of AI.

=head1 LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to the terms of GPL2.
If you use it,
please let me know.

=cut
