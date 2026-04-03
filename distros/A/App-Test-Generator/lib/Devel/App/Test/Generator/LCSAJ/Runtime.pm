package Devel::App::Test::Generator::LCSAJ::Runtime;

use strict;
use warnings;

=head1 NAME

Devel::App::Test::Generator::LCSAJ::Runtime - Debugger backend for LCSAJ coverage

=head1 SYNOPSIS

  PERL5OPT='-d:App::Test::Generator::LCSAJ::Runtime -Mblib' prove -l t

=head1 DESCRIPTION

This module is loaded as a Perl debugger backend using the C<-d:Module> flag.

When Perl sees C<-d:App::Test::Generator::LCSAJ::Runtime> it prepends C<Devel::>
and loads C<Devel/App/Test/Generator/LCSAJ/Runtime.pm> from C<@INC>.  The file
must therefore live at that path — typically
C<lib/Devel/App/Test/Generator/LCSAJ/Runtime.pm>.

Perl automatically calls C<DB::DB> before executing each statement while the
debugger is active.  We record (file, line) pairs to build runtime hit data for
later LCSAJ analysis.

The results are written to C<cover_html/lcsaj_hits.json> at process exit.

=head1 ENVIRONMENT

=over 4

=item LCSAJ_TARGETS

Optional colon-separated list of B<absolute> paths (as produced by C<realpath>)
to restrict recording to specific source files.  When empty or unset every
non-internal file is recorded.

=back

=cut

use Cwd        qw(abs_path);
use JSON::MaybeXS;
use File::Path qw(make_path);

# ---------------------------------------------------------------------------
# %HITS  - { normalised_path => { line_number => hit_count } }
# %TARGET - set of normalised paths we care about (empty == record everything)
# ---------------------------------------------------------------------------

our %HITS;
our %TARGET;

# ---------------------------------------------------------------------------
# _normalize($path)
#
# Convert an absolute or build-tree path to a canonical lib-relative form so
# that paths recorded at runtime match the targets derived from LCSAJ_TARGETS.
#
# Examples:
#   /home/user/proj/blib/lib/Foo/Bar.pm  ->  lib/Foo/Bar.pm
#   /home/user/proj/lib/Foo/Bar.pm       ->  lib/Foo/Bar.pm
# ---------------------------------------------------------------------------

sub _normalize {
    my ($f) = @_;
    # Strip everything up to and including the first blib/lib/ or lib/ segment.
    $f =~ s{^.*/blib/lib/}{lib/};
    $f =~ s{^.*/lib/}{lib/};
    return $f;
}

# ---------------------------------------------------------------------------
# Populate %TARGET from LCSAJ_TARGETS at compile time.
# The env var contains absolute realpath() output separated by colons; any
# embedded newlines (from a broken shell pipeline) are stripped defensively.
# ---------------------------------------------------------------------------

BEGIN {
    my $targets_env = $ENV{LCSAJ_TARGETS} // '';
    $targets_env =~ s/\n//g;    # defensive: strip stray newlines

    for my $t (split /:/, $targets_env) {
        next unless length $t;
        $TARGET{ _normalize($t) } = 1;
    }
}

# ---------------------------------------------------------------------------
# DB::DB - called by the Perl debugger before every statement.
#
# caller(0) returns (package, filename, line) for the statement about to run.
# We use that rather than trying to pass arguments (the debugger passes none).
# ---------------------------------------------------------------------------

sub DB::DB {
    my (undef, $file, $line) = caller(0);

    return unless defined $file && defined $line;

    # Resolve symlinks / relative components to a stable absolute path.
    my $abs  = abs_path($file) // $file;
    my $norm = _normalize($abs);

    # Never record hits inside this module itself (suffix match, not exact,
    # so it works regardless of CWD or install prefix).
    return if $norm =~ m{(?:^|/)Devel/App/Test/Generator/LCSAJ/Runtime\.pm$};

    # If a target list was provided, skip files not in it.
    if (%TARGET) {
        return unless $TARGET{$norm};
    }

    $HITS{$norm}{$line}++;
}

# ---------------------------------------------------------------------------
# _write_results - serialise %HITS to JSON.
#
# Called from END so it runs even when prove exits non-zero (mutation tests
# are expected to fail, hence set -e is disabled around the prove invocation).
# ---------------------------------------------------------------------------

sub _write_results {
	return unless %HITS;

	my $out_dir  = 'cover_html/lcsaj_hits';
	my $out_file = "$out_dir/hits_$$.json";	# Include the PID in the output file

	make_path($out_dir) unless -d $out_dir;

	open my $fh, '>', $out_file
		or die "Devel::App::Test::Generator::LCSAJ::Runtime: ",
		     "cannot write $out_file: $!";

	print $fh encode_json(\%HITS);
	close $fh;
}

END {
    _write_results();
}

1;

__END__

=head1 OUTPUT FORMAT

C<cover_html/lcsaj_hits.json> is a JSON object of the form:

  {
    "lib/Foo/Bar.pm": { "12": 3, "15": 1, ... },
    ...
  }

Keys are lib-relative paths (C<lib/...>); values are objects mapping line
numbers (as strings) to hit counts.

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
