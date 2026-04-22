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

our $VERSION = '0.33';

=head1 NAME

Devel::App::Test::Generator::LCSAJ::Runtime - Debugger backend for LCSAJ coverage

=head1 SYNOPSIS

  PERL5OPT='-d:App::Test::Generator::LCSAJ::Runtime -Mblib' prove -l t

=head1 DESCRIPTION

This module is loaded as a Perl debugger backend using the C<-d:Module> flag.

When Perl sees C<-d:App::Test::Generator::LCSAJ::Runtime> it prepends C<Devel::>
and loads C<Devel/App/Test/Generator/LCSAJ/Runtime.pm> from C<@INC>. The file
must therefore live at that path — typically
C<lib/Devel/App/Test/Generator/LCSAJ/Runtime.pm>.

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
# %HITS   - { normalised_path => { line_number => hit_count } }
# %TARGET - set of normalised paths to record (empty means record everything)
#
# These must be package globals (our) rather than lexicals because DB::DB
# is called by the Perl debugger infrastructure and needs to access them
# without a closure. Lexical vars would not be visible in DB::DB.
# --------------------------------------------------
our %HITS;
our %TARGET;

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
# --------------------------------------------------
sub DB::DB {
	my (undef, $file, $line) = caller(0);

	return unless defined $file && defined $line;

	# Resolve symlinks and relative components to a stable absolute path
	my $abs  = abs_path($file) // $file;
	my $norm = _normalize($abs);

	# Never record hits inside this module itself — suffix match is used
	# so it works regardless of CWD or install prefix
	return if $norm =~ m{(?:^|/)Devel/App/Test/Generator/LCSAJ/Runtime\.pm$};

	# If a target list was provided skip files not in it
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

	open my $fh, '>', $out_file
		or croak "Cannot write $out_file: $!";

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

Nigel Horne

=cut
