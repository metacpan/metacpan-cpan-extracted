# ABSTRACT: Normalize MooX::Options option-parse errors to exit code 2 (ADR 0002)

package App::karr::Role::ExitCodes;
our $VERSION = '0.601';
use Moo::Role;
# Both loaded without importing, and every call below is qualified: a Moo::Role
# composes every sub in its package into its consumers, imported ones included
# (#38), and these two export names a command class wants for itself.
use App::karr::Encoding ();
use App::karr::Error ();


sub usage_error {
    my ($self, $message) = @_;
    chomp $message if defined $message;
    die "Usage error: " . ( defined $message ? $message : 'invalid invocation' ) . "\n";
}

#### The answer goes last (ticket k263)

# MooX::Options prints its diagnostic before the usage block, and neither writer
# is reachable from a method modifier -- they sit in two different places and
# neither hands the text on:
#
#   * Getopt::Long warns "Unknown option: bogus" / "Option claim requires an
#     argument" from inside describe_options, after which MooX::Options::Role
#     calls options_usage(1, $usage) (4.103, parse_options line 372).
#     Getopt::Long::Descriptive installs no $SIG{__WARN__} of its own -- it says
#     why at line 306, "too heavy a hammer" -- so the field is free, but a
#     handler would catch only this first writer.
#   * an option declared `required => 1` and not given fails in $class->new, and
#     new_with_options reports it with a bare `print STDERR "$1 is missing"`
#     (4.103, lines 293-315) before calling options_usage. That one no warn
#     handler ever sees, which is why STDERR itself is captured rather than
#     warnings.
#
# Both writers are inside new_with_options, so STDERR is buffered for exactly
# the length of that call: option parsing and the constructor, never a command
# body. Nothing is dropped. Whatever was buffered is printed on every path --
# reordered when the failure lands in options_usage or _print_help, verbatim
# when new_with_options returns or dies, and from the END block below when
# something else exits first (`--man` leaves through options_man).
#
# This can go when MooX::Options prints its diagnostic after the usage block, or
# passes it to options_usage as a message instead of writing it out itself: both
# writers are unconditional in 4.103, which is the current release.
my $CAPTURE;

sub _start_option_capture {
    return if $CAPTURE;
    my $octets = '';
    open my $handle, '>', \$octets or return;
    # The in-memory handle is an octet edge like every other one karr has, so it
    # is crossed the way App::karr::Encoding crosses them: :utf8 keeps a wide
    # character out of "Wide character in warn" and stores its UTF-8, and
    # _end_option_capture decodes it back before anything is printed. Only
    # STDERR's IO slot is swapped, so the encoding layer F<bin/karr> put on the
    # real handle is still there when it is swapped back.
    binmode $handle, ':utf8';
    $CAPTURE = { handle => $handle, octets => \$octets, stderr => *STDERR{IO} };
    *STDERR = *$handle{IO};
    return;
}

sub _end_option_capture {
    my $capture = $CAPTURE;
    return unless $capture;
    undef $CAPTURE;
    *STDERR = $capture->{stderr};
    close $capture->{handle};   # the :utf8 layer flushes into the buffer on close
    return App::karr::Encoding::from_octets( ${ $capture->{octets} } );
}

# Nothing is swallowed on a path that leaves without reaching either caller of
# _usage_error_last -- `--man` and `--help` exit from inside MooX::Options. END
# runs late enough to be the backstop and restores STDERR itself, so a buffer
# nobody claimed is still printed.
END {
    my $left = _end_option_capture();
    print STDERR $left if defined $left && length $left;
}

# The suggestion line for an option-parse diagnostic, or nothing. Three shapes
# reach here, and they are the three MooX::Options 4.103 produces:
#
#   Unknown option: bogus_opt            Getopt::Long, via describe_options
#   Option claim requires an argument    Getopt::Long, same place
#   claim is missing                     MooX::Options::Role, for `required => 1`
#
# Only the last two get a suggestion. Anything else -- an unrecognised shape,
# no recorded argv -- keeps the reordering and loses the suggestion, which is
# the right way round: the diagnostic is MooX::Options' to word, the suggestion
# is karr's to offer, and karr offers one only where it has one.
sub _option_hint {
    my ( $self, $diagnostic ) = @_;

    my $argv = App::karr::Error::original_argv();
    return unless defined $argv;

    # [ token, is it the caller's own word? ] -- the second half is k263's rule
    # that a line carrying nothing anybody typed is not printed at all.
    my @tokens = map { [ $_, 1 ] } @$argv;
    my $edited = 0;

    for my $line ( split /\n/, $diagnostic ) {
        # An unknown option is the one shape with no honest suggestion behind
        # it, so it gets none -- and therefore no colon either. The other two
        # are missing a VALUE and the value is what gets filled in, so the
        # caller's intent survives whole. Here the only line that would run is
        # the caller's own word thrown away: `karr move 1 todo --bogus` would
        # be answered with `karr move 1 todo`, a card being moved that nobody
        # asked to move, handed to an agent reading `tail -1`. What the caller
        # needs is the list of names that do exist, and the usage block
        # directly above is that list. It suppresses the whole suggestion and
        # not just its own edit: a line built around an option karr could not
        # read is not one karr can stand behind either.
        return if $line =~ /\AUnknown option: /;

        if ( $line =~ /\AOption (\S+) requires an argument\z/ ) {
            my $name = $1;
            my $at   = _flag_position( \@tokens, $name );
            my $slot = [ $self->_usage_placeholder($name), 0 ];
            if ( defined $at ) { splice @tokens, $at + 1, 0, $slot }
            else { push @tokens, [ '--' . $name, 0 ], $slot }
            $edited = 1;
        }
        elsif ( $line =~ /\A(\w+) is missing\z/ ) {
            # The option is not in argv at all, so it is appended to what is:
            # `karr handoff 1` -> `karr handoff 1 --claim NAME`.
            push @tokens, [ '--' . $1, 0 ], [ $self->_usage_placeholder($1), 0 ];
            $edited = 1;
        }
    }

    return unless $edited;
    return unless grep { $_->[1] } @tokens;
    return App::karr::Error::command_hint( map { $_->[0] } @tokens );
}

# The word a command uses for an option's value in its own usage_string, and
# the option name upper-cased only where it names none.
#
# The commands write their placeholder down already -- Move's usage_string is
# `karr move ID[,ID,...] STATUS [--claim NAME] [--next|--prev]`, Handoff's names
# NAME and TEXT -- and karr's other k263 messages quote those same words back
# (`Status 'in-progress' requires a claim:` offers `--claim NAME`). Reading the
# string rather than inventing a second vocabulary is what keeps the two
# messages about one option saying one word, and it means a command that
# renames its placeholder drags this line along with it.
sub _usage_placeholder {
    my ( $self, $name ) = @_;

    my %config = $self->can('_options_config') ? $self->_options_config : ();
    if ( defined $config{usage_string} ) {
        # The usage_string spells an option the way a user types it, so the
        # dashed spelling is tried as well as the underscored name Getopt::Long
        # reports (#256). `=` is part of the placeholder, not a separator after
        # it: `--board NAME=PATH` is one word.
        ( my $dashed = $name ) =~ tr/_/-/;
        for my $spelling ( $name, $dashed ) {
            return $1
                if $config{usage_string} =~ /--\Q$spelling\E[= ]([A-Z][A-Z0-9_=-]*)/;
        }
    }
    return uc $name;
}

# Where the caller's own spelling of an option stands, last occurrence first.
# The name in the diagnostic is the one in the generated specification --
# underscores, because MooX::Options folded the dashes away before Getopt::Long
# saw it (#256) -- so the typed token is folded the same way before comparing.
# An abbreviation is answered too: `--cla` is reported as `claim`, and appending
# a second, full --claim would put a word in the caller's mouth twice.
sub _flag_position {
    my ( $tokens, $name ) = @_;
    my $abbreviated;
    for my $at ( reverse 0 .. $#$tokens ) {
        next unless $tokens->[$at][0] =~ /\A--?([^=]+)/;
        ( my $typed = $1 ) =~ tr/-/_/;
        return $at if $typed eq $name;
        $abbreviated = $at if !defined $abbreviated && $name =~ /\A\Q$typed\E/;
    }
    return $abbreviated;
}

# Take the buffered diagnostic and put it back after $usage_text, with the
# suggestion under it, then exit. Returns 0 without exiting when there is
# nothing to reorder -- no diagnostic, no usage text, or a code that is not an
# error -- having printed whatever was buffered unchanged, so that every caller
# can put this in front of the printing it already did.
sub _usage_error_last {
    my ( $self, $usage_text, $code ) = @_;

    my $diagnostic = _end_option_capture();
    $diagnostic = '' unless defined $diagnostic;

    unless ( length $diagnostic && defined $usage_text && defined $code && $code > 0 ) {
        print STDERR $diagnostic if length $diagnostic;
        return 0;
    }

    # One newline between the block and the answer. MooX::Options warns the
    # usage object plus a newline of its own, which leaves a blank line -- and a
    # blank line is one of the three an agent reading `tail -3` has.
    $usage_text =~ s/\n*\z/\n/;
    $diagnostic =~ s/\n+\z//;

    my $hint = $self->_option_hint($diagnostic);
    $diagnostic .= ':' if defined $hint;

    print STDERR $usage_text, $diagnostic, "\n";
    print STDERR $hint, "\n" if defined $hint;
    exit $code;
}

around new_with_options => sub {
    my ( $orig, $class, @args ) = @_;

    _start_option_capture();
    my @created;
    my $ok = eval { @created = $orig->( $class, @args ); 1 };
    my $err = $@;

    # Only reached when MooX::Options neither exited nor took over: the command
    # object was built, or the constructor died of something that is not an
    # option-parse failure. Either way the buffer goes out as it was written.
    my $left = _end_option_capture();
    print STDERR $left if defined $left && length $left;

    die $err unless $ok;
    return wantarray ? @created : $created[0];
};

# The per-command help block (k276).
#
# MooX::Options' own text() rendered underscored names, listed the four
# built-ins (--usage/-h/--help/--man), and tacked on a blank-line divider the
# USAGE line on the previous page contradicted. Building it ourselves off
# _options_data (which carries none of the built-ins) lets us name options the
# way the command line spells them, drop the four built-ins for the same
# reason, and drop any option a command marks `hidden => 1` -- --dir lives on
# every board command and --quiet on every syncing one, so hiding them on
# per-command pages is what lets a page list only what differs between
# commands.
sub _render_help_long {
    my ($self) = @_;

    my %data   = $self->_options_data;
    my %config = $self->_options_config;

    # Width budget. The terminal reports columns through a layer of env vars
    # and tty detection, all of which are unreliable in the test runner and
    # under the agent harness; default to 76 columns and let a TEST_FORCE_*
    # override pin it (the help-column-alignment test uses one).
    my $cols = $ENV{TEST_FORCE_COLUMN_SIZE}
        || ( eval {
            require Term::Size::Any;
            Term::Size::Any::chars() || 0;
        } ) || 76;
    $cols = 76 if !defined $cols || $cols < 40;

    # The USAGE line is the command's own usage_string, which already starts
    # with `USAGE: karr <cmd> ...` and may itself spell options out. Two cases:
    # one where it does, where the renderer keeps the command's wording
    # verbatim and just adds the option list underneath; one where it does not
    # and we are the first place the option list appears at all. Both are
    # correct.
    my $text = ( defined $config{usage_string} ? $config{usage_string} : '' );
    $text .= "\n" if length $text && substr( $text, -1 ) ne "\n";

    my @rows;
    for my $name ( sort keys %data ) {
        my $opt = $data{$name};
        next if $opt->{hidden};
        push @rows, [
            $self->_option_spec_for_help( $name, $opt ),
            $opt->{doc} // '',
        ];
    }

    # Column width: longest option spec in the table, with at least four
    # spaces between the spec and the description. The 4 leading spaces are a
    # deliberate indent -- matching the one --help already used -- so the help
    # block and the USAGE line share their left margin.
    my $max_spec = 0;
    $max_spec = length $_->[0] > $max_spec ? length $_->[0] : $max_spec
      for @rows;
    $max_spec = 0 if !defined $max_spec;

    my $pad_indent = ' ' x 4;
    my $gutter     = $max_spec + 4;
    my $doc_width  = $cols - length($pad_indent) - $gutter;
    $doc_width = 20 if $doc_width < 20;

    for my $row (@rows) {
        my ( $spec, $doc ) = @$row;
        my $between = ' ' x ( $gutter - length $spec );
        my @wrapped = $self->_wrap_help_doc( $doc, $doc_width );
        $text .= $pad_indent . $spec . $between . $wrapped[0] . "\n";
        if ( @wrapped > 1 ) {
            my $cont = $pad_indent . ' ' x $gutter;
            $text .= $cont . $_ . "\n" for @wrapped[ 1 .. $#wrapped ];
        }
    }
    return $text;
}

# The one-line spelling of an option for the help table.
#
# MooX::Options' Usage object builds this same string from the Getopt::Long
# spec it hands describe_options; the difference here is that we have the
# raw option declaration in hand (the underscored name, the short alias, the
# type), so we can hyphenate without losing the case and we can keep the
# `=String`/`=Int` suffix that matches what Getopt::Long prints on the
# option-parse error line -- a `--claimed_by=String` in the help and a
# `--claimed_by requires an argument` in the error are two forms of the same
# word, and the help's spelling is the one the user has to fix.
sub _option_spec_for_help {
    my ( undef, $name, $opt ) = @_;

    my $display = $name;
    $display =~ tr/_/-/;

    my $spec = '--' . $display;
    if ( defined $opt->{short} && length $opt->{short} ) {
        $spec = '-' . $opt->{short} . ' ' . $spec;
    }
    if ( defined $opt->{format} && length $opt->{format} ) {
        my $fmt  = $opt->{format};
        $fmt =~ s/@\z//;
        my %type = (
            s => 'String',
            i => 'Int',
            o => 'Ext. Int',
            f => 'Real',
        );
        $spec .= '=' . $type{$fmt} if defined $type{$fmt};
    }
    return $spec;
}

# Wrap $text to fit $width columns, splitting on whitespace. The input is one
# paragraph; the output is one or more lines of equal-or-less width, the
# caller is in charge of indenting. A word longer than the width is kept whole
# rather than split mid-word -- the help block is short, the descriptions
# short, and a word like `--claude-skill` would only ever break the layout
# for a few columns.
sub _wrap_help_doc {
    my ( undef, $text, $width ) = @_;

    return ('') unless defined $text && length $text;
    return ($text) if length $text <= $width;

    my @lines;
    my $current = '';
    for my $word ( split /\s+/, $text ) {
        next unless length $word;
        if ( length $current == 0 ) {
            $current = $word;
        }
        elsif ( length($current) + 1 + length($word) <= $width ) {
            $current .= ' ' . $word;
        }
        else {
            push @lines, $current;
            $current = $word;
        }
    }
    push @lines, $current if length $current;
    return @lines;
}

around options_usage => sub {
    my ( $orig, $self, $code, @rest ) = @_;
    $code = 2 if defined $code && $code > 0;
    $code //= 0;

    # Anything else -- extra messages to print in front, no usage object at all
    # -- is none of this role's business and goes to the original untouched
    # (4.103, options_usage line 456 stringifies the Usage object as the whole
    # message).
    unless ( @rest == 1 && ref $rest[0] eq 'MooX::Options::Descriptive::Usage' ) {
        return $orig->( $self, $code, @rest );
    }

    # Build karr's own help block: hyphenated names, one option per line, the
    # built-in --usage/-h/--help/--man and any `hidden => 1` option (--dir,
    # --quiet) suppressed. MooX::Options' own long format spelled every option
    # with underscores, listed the four built-ins, and inserted two blank lines
    # before them, all of which contradicted the README and the USAGE line a
    # screen apart (ticket k276).
    my $text = $self->_render_help_long;

    # k263's reorder goes first: on the error path the buffered diagnostic is
    # moved after $text and the process exits; on the success path the capture
    # is ended and whatever was buffered is printed verbatim, and we then print
    # $text below. STDERR is the real handle at this point either way.
    my $done = $self->_usage_error_last( $text, $code );
    return if $done;

    if ( $code > 0 ) {
        CORE::warn $text;
    }
    else {
        print $text;
    }
    exit $code if $code >= 0;
    return;
};

# options_help is the method MooX::Options calls for --help (options_usage is
# what -h reaches). The two were two different renderings of the same options
# table -- long form for --help, compact for -h -- and the ticket asked for one
# rendering, the compact one, on both (#k276). options_short_usage (--usage)
# stays untouched: that one prints a one-line summary that has never been the
# "help" page.
around options_help => sub {
    my ( $orig, $self, $code, @rest ) = @_;
    $code = 2 if defined $code && $code > 0;
    $code //= 0;

    unless ( @rest == 1 && ref $rest[0] eq 'MooX::Options::Descriptive::Usage' ) {
        return $orig->( $self, $code, @rest );
    }

    my $text = $self->_render_help_long;
    my $done = $self->_usage_error_last( $text, $code );
    return if $done;

    if ( $code > 0 ) {
        CORE::warn $text;
    }
    else {
        print $text;
    }
    exit $code if $code >= 0;
    return;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Role::ExitCodes - Normalize MooX::Options option-parse errors to exit code 2 (ADR 0002)

=head1 VERSION

version 0.601

=head1 DESCRIPTION

Part of karr's exit-code contract (ADR 0002): C<0> success, C<1> runtime
failure, C<2> usage error.

MooX::Options handles an option-parse failure -- an unknown option, an invalid
option value, or a missing required option -- by printing a diagnostic and then
calling C<< $class->options_usage($code) >> with a positive C<$code>, which
C<exit>s that code. Historically that code was C<1>, which collided with genuine
runtime failures. Those are B<usage> errors, so this role wraps C<options_usage>
to force any positive (error) code to C<2>.

Help requests (C<-h>, C<--help>, C<--usage>) reach C<options_usage> with a code
of C<0> (or undef), so they are left untouched: they still print to STDOUT and
exit C<0>.

The role also decides B<where> that diagnostic is printed. MooX::Options puts it
in front of a fifteen-line usage block; karr puts it behind it, together with
the invocation that would have worked -- see L</THE ANSWER GOES LAST> below.

The complementary half of the contract -- catching the uncaught C<die>s raised
by command bodies and classifying them into runtime (C<1>) versus usage (C<2>)
-- lives in the central handler in F<bin/karr>. That handler classifies by a
stable leading marker on the message, so a command that wants to reject an
invalid invocation itself calls C<usage_error>, which emits the generic marker.
The root command's own option-parse errors go through its C<_print_help>
override instead of this role, and that override applies the same
positive-to-C<2> remap and calls the same reordering method.

=head1 THE ANSWER GOES LAST

An option-parse error used to read like this, and the first line was the answer:

    Option claim requires an argument
    USAGE: karr move ID[,ID,...] STATUS [--claim NAME] [--next|--prev]
        ... thirteen more lines ...
        --man           show the manual

karr's primary callers are agents, which read it through C<tail -n> because the
output is long -- so the line that says what went wrong is exactly the line that
gets cut, and the four-call reproduction in ticket k263 is what that costs. The
same error now ends where it is read:

    USAGE: karr move ID[,ID,...] STATUS [--claim NAME] [--next|--prev]
        ... the same thirteen lines ...
        --man           show the manual
    Option claim requires an argument:
      karr move 1 in-progress --claim NAME

The diagnostic is MooX::Options' own, word for word; only its position changes,
and the colon and the line under it are added. That line is
L<App::karr::Error/command_hint> over the argv the caller really typed
(L<App::karr::Error/original_argv>), so it shows C<--claimed-by> where that is
what was typed rather than the C<--claimed_by> Getopt::Long is handed, and the
placeholder is the word the command's own C<usage_string> uses for that value.

A suggestion is offered only where karr has an honest one. C<Unknown option:>
has none -- the line that would run is the caller's own word deleted -- so it
gets the reordering, no suggestion, and therefore no colon either. So does a
diagnostic whose shape is not recognised, and so does any of them where no argv
was recorded: a library caller, a test, F<bin/karr-foundation>.

=head2 usage_error

    $self->usage_error("--last must be 1 or greater (got 0)");

Dies with a message carrying the C<Usage error:> marker that F<bin/karr>
classifies as a usage error, so the process exits C<2>.

This is for misuse that MooX::Options cannot catch on its own: an option value
that parses but is out of range, a mutually exclusive combination of flags, an
argument list that is syntactically fine but semantically empty. Anything
MooX::Options B<can> catch -- an unknown option, a value that does not fit the
declared C<format> -- already exits C<2> through the C<options_usage> wrapper
above and must not be re-checked here.

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
