# ABSTRACT: The one dispatch path shared by bin/karr and the in-process test runner

package App::karr::Dispatch;
our $VERSION = '0.601';
use strict;
use warnings;
use Exporter qw( import );
use Scalar::Util qw( blessed );
use Module::Runtime qw( use_module );
use App::karr;
use App::karr::SyncGuard;
use App::karr::Encoding qw( decode_argv enable_std_utf8 );
use App::karr::Error qw( is_usage_error set_original_argv );
use App::karr::Role::CliArgs;

our @EXPORT_OK = qw( dispatch );


# An empty argument never reaches a command, so it is refused here while it is
# still visible (ticket #243).
#
# MooX::Cmd copies argv with `shellwords(join ' ', map { quotemeta } @ARGV)`
# (MooX::Cmd::Role 1.000, line 132) before it even looks for the command name.
# That round trip is the identity on every non-empty argument -- quotemeta
# escapes, shellwords unescapes -- but the empty string contributes nothing to
# the joined line and shellwords never returns an empty field, so the transform
# is exactly `grep { length }`. No spelling of an empty argument survives it,
# which is why this could not be fixed by letting the token through to the
# `defined && length` guards of #239: by the time any karr code runs there is
# nothing left to hand them.
#
# What the deletion leaves is a shorter argv, so every argument after the empty
# one moves one place to the left. `karr move "$IDS" todo` with an unset $IDS
# arrives as `karr move todo`, reads `todo` as the id, and reports "Task todo
# not found" -- an error about a card, for a mistake in the caller's variable.
# Elsewhere the loss was worse than misleading rather than merely wrong:
# `karr show ""` printed whichever card was touched last and exited 0, and
# `karr skill ""` fell through to its default action and installed skill files.
#
# Refusing takes nothing away that ever worked. An empty argument is dropped in
# every position of every command, so no invocation that produced the result
# its caller wanted changes meaning -- empty option values (`--claim ""`,
# `--body ""`) included, which are dropped by the same rule and today either
# eat the following token as the value or fail with "Option claim requires an
# argument". Clearing a value by passing an empty one is a feature karr does
# not have; if it ever gets one, this guard is where the exception belongs.
sub _refuse_empty_argument {
    my @at = grep { !length $ARGV[$_] } 0 .. $#ARGV;
    return unless @at;

    # Echo the command line back with the empty slots visible: that is the
    # whole diagnosis, because the caller is looking for a variable and not for
    # a card. Whitespace is folded and long values are cut so that a --body
    # cannot bury the message underneath itself.
    my $line = join ' ', 'karr', map {
        my $arg = $_;
        $arg =~ s/\s+/ /g;
        $arg = substr( $arg, 0, 37 ) . '...' if length $arg > 40;
        length $arg && $arg !~ /\s/ ? $arg : "'" . $arg . "'";
    } @ARGV;

    my $where = join ', ', map { $_ + 1 } @at;
    die 'Usage error: '
      . ( @at == 1 ? "argument $where is empty" : "arguments $where are empty" )
      . ": $line\n"
      . "An empty argument is dropped before any command sees it, and every\n"
      . "argument after it moves one place to the left. Check the shell\n"
      . "variable expanded there -- it is unset or empty.\n";
}

# An option name with a dash in it does not survive standing behind a boolean
# flag, so the flags are respelled with underscores here, before MooX::Cmd and
# MooX::Options ever look at argv (ticket #256).
#
# App::karr::Role::CliArgs/normalize_option_argv carries the whole diagnosis and
# the condition under which this call may go again. What belongs here is only
# why the CALL is here: the rewrite has to know which token is a flag and which
# is the value of the flag in front of it, that answer comes out of the option
# table of the command being run, and this is the last point at which the whole
# argv is still in one piece.
#
# Which command that is, is decided exactly the way MooX::Cmd decides it half a
# millisecond later: the first argv token that names a command
# (MooX::Cmd::Role::_initialize_from_cmd, `first_index` across the WHOLE argv --
# see the %COMMAND_ALIASES comment in App::karr for why the table is asked and
# argv is not rewritten). Everything before that token is the root's own argv
# and is normalized against App::karr, everything after it against the command
# class. The command name itself is passed through untouched, which is what
# keeps the dashed command spellings (`get-refs`) findable in the table.
sub _normalize_option_argv {
    my $commands = App::karr->_build_command_commands( {} );

    my ( $at, $class );
    for my $i ( 0 .. $#ARGV ) {
        next unless defined $commands->{ $ARGV[$i] };
        ( $at, $class ) = ( $i, $commands->{ $ARGV[$i] } );
        last;
    }

    my @root = defined $at ? @ARGV[ 0 .. $at - 1 ]      : @ARGV;
    my @name = defined $at ? ( $ARGV[$at] )             : ();
    my @rest = defined $at ? @ARGV[ $at + 1 .. $#ARGV ] : ();

    # Both calls are class-method calls: normalize_option_argv reads the option
    # table and nothing else, so it needs no instance -- and no instance exists
    # yet, which is the point of doing this here. Every App::karr::Cmd::* class
    # composes App::karr::Role::CliArgs (t/256 pins that, because a command that
    # forgot to would silently keep the defect for its own dashed options), but
    # the guard stays: MooX::Cmd's plugin scan decides what a command class is,
    # not this file.
    @root = App::karr->normalize_option_argv( \@root );
    if ( defined $class ) {
        use_module($class);
        @rest = $class->normalize_option_argv( \@rest )
            if $class->can('normalize_option_argv');
    }

    @ARGV = ( @root, @name, @rest );
    return;
}

sub dispatch {
    my (@argv) = @_;

    # dispatch operates on the global @ARGV, exactly as bin/karr did inline:
    # the two rewrites above and MooX::Cmd::new_with_cmd all read and write it.
    # Localising it lets an embedding host call dispatch repeatedly, and lets
    # bin/karr pass its own @ARGV in unchanged.
    local @ARGV = @argv;

    # The character/octet boundary (ticket #53). Everything the OS hands in is
    # bytes; everything a command body sees is Perl characters. @ARGV comes in
    # decoded, STDOUT and STDERR encode on the way out, and no command body
    # encodes anything itself. STDIN stays raw on purpose -- every reader of it
    # decodes its own payload (#246).
    enable_std_utf8();
    decode_argv();

    # The caller's own words, kept for the suggestion line an option-parse error
    # ends on (ticket k263). Recorded HERE because both rewrites below change
    # argv and neither leaves what anyone typed: _refuse_empty_argument's
    # diagnosis reads the raw line, and _normalize_option_argv respells
    # --claimed-by as --claimed_by and folds a flag-shaped value onto its option
    # with an `=`. App::karr::Role::ExitCodes reads it back through
    # App::karr::Error, and prints no suggestion at all where nothing was
    # recorded.
    set_original_argv(@ARGV);

    # Inside the eval on purpose: the "Usage error:" marker is what
    # App::karr::Error::is_usage_error keys on, so the handler below turns this
    # into exit 2 through the same path as every other usage error.
    my $ran = eval { _refuse_empty_argument(); _normalize_option_argv(); App::karr->new_with_cmd; 1 };
    if ( !$ran ) {
        my $err = $@;

        # An embedding host's exit-signal (see EMBEDDING) is not a command that
        # died: hand it back rather than classifying it. Nothing in karr's own
        # code answers this, so under bin/karr -- where exit() really exits and
        # never reaches this eval -- it never fires.
        die $err if blessed($err) && $err->can('__karr_dispatch_exit');

        # Exit-code contract (ADR 0002): 0 success / 1 runtime failure / 2 usage
        # error. This is the central handler the ADR calls for: it catches every
        # uncaught die from a command body and turns it into a deterministic 1
        # or 2, replacing the accidental 255 an uncaught die used to leak.
        #
        # Usage-error dies carry one of these stable leading markers:
        #   "Unknown command:"          the dispatch guard in App::karr
        #   "unexpected extra argument"  surplus positionals (Role::CliArgs)
        #   "Usage:"                     a missing required positional
        #   "Usage error:"               anything a command rejects as misuse
        #                                that is not one of the shapes above --
        #                                raised via App::karr::Role::ExitCodes'
        #                                usage_error(), the generic entry point
        #                                for e.g. an out-of-range option value
        # Any new usage-error die must start with one of these; prefer
        # usage_error() over inventing a fifth marker. Everything else -- task
        # not found, board missing, a Git/sync failure, a refused destructive
        # operation -- is a runtime failure (1).
        #
        # The markers themselves live in App::karr::Error::is_usage_error,
        # because this handler is no longer their only reader: the batch runner
        # in App::karr::Role::TaskMutation asks the same question to decide
        # whether a failure belongs to one id or to the whole invocation (#61).
        #
        # Option-parse errors (unknown option, unparseable option value) never
        # reach here: MooX::Options exits 2 directly via
        # App::karr::Role::ExitCodes (and the root's _print_help), so those
        # exits bypass this eval.
        my $is_usage = is_usage_error($err);

        print STDERR $err if defined $err && length $err;
        exit( $is_usage ? 2 : 1 );
    }

    return;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Dispatch - The one dispatch path shared by bin/karr and the in-process test runner

=head1 VERSION

version 0.601

=head1 SYNOPSIS

    use App::karr::Dispatch qw( dispatch );
    dispatch(@ARGV);

=head1 DESCRIPTION

Everything that sits between a program's start and C<< App::karr->new_with_cmd >>
lived inline in F<bin/karr>: the character/octet boundary setup, the record of
the caller's own argv, the two argv rewrites (empty-argument refusal and
dashed-option normalisation), and the central handler that turns an uncaught
C<die> into the exit-code contract (ADR 0002). This module is that code, moved
out whole so the F<karr> executable and the in-process test runner
(F<t/lib/TestKarr.pm>) share B<one> dispatch path rather than two copies that
drift.

L</dispatch> does exactly what F<bin/karr> used to do inline. F<bin/karr> is now
a thin wrapper that calls it (and keeps the END block that flushes
L<App::karr::SyncGuard>, which is a process-lifecycle concern -- see there).

=head1 EMBEDDING

An embedding host may run L</dispatch> many times in one interpreter -- the
in-process test runner does, to skip ~0.3s of Perl startup per C<karr> call.
Such a host installs, in a C<BEGIN> block before L<App::karr> is compiled, an
override of C<CORE::GLOBAL::exit> that raises an exception instead of tearing
the whole interpreter down. karr reaches C<exit> from three places -- this
module's handler, L<App::karr::Role::ExitCodes>, and L<App::karr/_print_help> --
and the override catches all three.

So that L</dispatch>'s own handler does not mistake such an exit-signal for a
command that died, it re-raises any caught exception that answers true to a
C<__karr_dispatch_exit> method, leaving it for whoever installed the override.
Nothing in karr's own code blesses such an object, so under F<bin/karr> -- which
installs no override and lets C<exit> exit -- this never fires and the handler
behaves exactly as it always did.

=head2 dispatch

    dispatch(@ARGV);

Runs one C<karr> invocation: sets up the character/octet boundary, records the
caller's argv, applies the empty-argument (#243) and dashed-option (#256)
rewrites, and calls C<< App::karr->new_with_cmd >> inside the central
exit-code handler (ADR 0002). Operates on a localised C<@ARGV>. Returns nothing
on success; on failure it prints the message to C<STDERR> and C<exit>s C<1> or
C<2> -- which, under an embedding host that overrides C<exit> (see
L</EMBEDDING>), becomes the host's exit-signal instead.

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Error>, L<App::karr::Encoding>,
L<App::karr::SyncGuard>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/karr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
