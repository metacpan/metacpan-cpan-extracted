use strict;
use warnings;
use Getopt::Long qw(:config no_auto_version);

package App::Prolix;
# ABSTRACT: trim chatty command outputs

use Moose;
use String::ShellQuote ();

use v5.10;

{
package App::Prolix::ConfigFileRole;

use Moose::Role;
with "MooseX::ConfigFromFile";
use JSON 2.0;

sub get_config_from_file {
    my($file) = @_;
    open my $fh, "<", $file or confess "open: $file: $!";
    local $/;
    my $json = <$fh>;
    close $fh or die "close: $file: $!";
    return JSON->new->relaxed->utf8->decode($json);
}

}

use Data::Munge;
use IO::File;
use IPC::Run ();
use Term::ReadKey ();
use Term::ReadLine;
use Text::Balanced ();
use Try::Tiny;

use App::Prolix::MooseHelpers;

with "MooseX::Getopt";

# Flags affecting overall run style.
has_option "verbose" => (isa => "Bool", cmd_aliases => "v",
    documentation => "Prints extra information.");
has_option "pipe" => (isa => "Bool", cmd_aliases => "p",
    documentation => "Reads from stdin instead of interactively.");
has_option "log" => (isa => "Str", cmd_aliases => "l",
    documentation => q{Logs output to a filename (say "auto" } .
        q{to let prolix pick one for you)});

# Flags affecting filtering.
has_option "ignore_re" => (isa => "ArrayRef", cmd_aliases => "r",
    "default" => sub { [] },
    documentation => "Ignore lines matching this regexp.");
has_option "ignore_line" => (isa => "ArrayRef", cmd_aliases => "n",
    "default" => sub { [] },
    documentation => "Ignore lines exactly matching this.");
has_option "ignore_substring" => (isa => "ArrayRef", cmd_aliases => "b",
    "default" => sub { [] },
    documentation => "Ignore lines containing this substring.");
has_option "snippet" => (isa => "ArrayRef", cmd_aliases => "s",
    "default" => sub { [] },
    documentation => "Snip lines. Use s/search_re/replace/ syntax.");

# Internal attributes (leading _ means not GetOpt).
has_rw "_cmd" => (isa => "ArrayRef", "default" => sub { [] });

has_rw "_out" => (isa => "ScalarRef[Str]", default => \&_strref);
has_rw "_err" => (isa => "ScalarRef[Str]", default => \&_strref);

has_rw "_log" => (isa => "FileHandle");
has_rw "_term" => (
        isa => "Ref");
        # TODO(gaal): figure out how to fix this:
        # isa => "Term::ReadLine|Term::ReadLine::Perl|Term::ReadLine::Gnu");
has_rw "_snippet" => (isa => "ArrayRef", "default" => sub { [] });
has_rw "_ignore_re" => (isa => "ArrayRef", "default" => sub { [] });

has_counter "_suppressed";
has_counter "_output_lines";

sub run {
    my($self) = @_;
    
    if ($self->verbose) {
        $SIG{USR1} = \&_dump_stack;
    }

    $self->open_log;
    $self->import_re($_) for @{$self->ignore_re};
    $self->import_snippet($_) for @{$self->snippet};

    if ($self->need_pipe) {
        $self->run_pipe;
    } else {
        $self->run_spawn;
    }

    if ($self->verbose) {
        say "Done. " . $self->stats;
    }

    $self->close_log;
}

sub need_pipe {
    my($self) = @_;
    return $self->pipe || @{$self->_cmd} == 0;
}

sub open_log {
    my($self) = @_;

    return if not defined $self->log;

    my $now = $self->now_stamp;
    my $filename = $self->log;
    $filename = ($self->need_pipe ? "prolix.%d" : ($self->_cmd->[0] . ".%d")) if
        $filename eq "auto";
    $filename = File::Spec->catfile(File::Spec->tmpdir, $filename) if
        $filename !~ m{[/\\]};  # Put in /tmp/ or similar unless we got a path.
    $filename =~ s/%d/$now/;  # TODO(gaal): implement incrementing %n.

    say "Logging output to $filename" if $self->verbose;

    my $fh = IO::File->new($filename, "w") or die "open: $filename: $!";
    $self->_log($fh);
}

sub close_log {
    my($self) = @_;
    $self->_log->close if $self->_log;
}

# Like: (DateTime->new->iso8601 =~ s/[-:]//g), but I didn't want to add
# a big dependency.
sub now_stamp {
    my($self) = @_;

    my(@t) = localtime;  # Should this be gmtime?
    return sprintf "%4d%02d%02dT%02d%02d%02d",
        $t[5] + 1900, $t[4] + 1, $t[3], $t[2], $t[1], $t[0];  # Ahh, UNIX.
}

sub stats {
    my($self) = @_;
    return "Suppressed " . $self->_suppressed . "/" .
        $self->_output_lines . " lines.";
}

# returns a fresh reference to a string.
sub _strref {
    return \(my $throwaway = "");
}

sub run_pipe {
    my($self) = @_;

    say "Running in pipe mode" if $self->verbose;

    while (<STDIN>) {
        chomp;
        $self->on_out($_)
    }
}

sub run_spawn {
    my($self) = @_;
    say "Running: " .
        String::ShellQuote::shell_quote_best_effort(@{$self->_cmd})
        if $self->verbose;

    Term::ReadKey::ReadMode("noecho");
    END { Term::ReadKey::ReadMode("normal"); }

    $self->_term(Term::ReadLine->new("prolix"));
    my $attribs = $self->_term->Attribs;
    $attribs->{completion_entry_function} =
        $attribs->{list_completion_function};
    $attribs->{completion_word} = [qw(
        help
        ignore_line
        ignore_re
        ignore_substring
        pats
        quit
        snippet
        stats
    )];

    my $t = IPC::Run::timer(0.3);
    my $ipc = IPC::Run::start $self->_cmd,
        \undef,  # no stdin
        $self->_out,
        $self->_err,
        $t;
    $t->start;
    my $pumping = 1;
    while ($pumping && $ipc->pump) {
        $self->consume;
        try {
            $self->try_user_input;
        } catch {
            when (/prolix-quit/) {
                $ipc->kill_kill;
                $pumping = 0;
            }
            default { die $_ }
        };
        $t->start(0.3);
    }
    $t->reset;
    $ipc->finish;
    $self->consume_final;

    Term::ReadKey::ReadMode("normal");
}

sub _dump_stack {
    print Carp::longmess("************");
    $SIG{USR1} = \&_dump_stack;
}

sub try_user_input {
    my($self) = @_;
    return if not defined Term::ReadKey::ReadKey(-1);

    # Enter interactive prompt mode. We hope this will be brief, and
    # IPC::Run can buffer our watched command in the meanhwile.

	say q{Press ENTER to go back, or enter "help" for a list of commands.}
		if $self->verbose;

    Term::ReadKey::ReadMode("normal");
    while (my $cmd = $self->_term->readline("prolix>")) {
        $self->_term->addhistory($cmd);
        $self->handle_user_input($cmd);
    }
    Term::ReadKey::ReadMode("restore");  # into noecho, we hope!
}

sub handle_user_input {
    my($self, $cmd) = @_;
    (my $nullary = $cmd) =~ s/^\s*(\S+)\s*/$1/;
    if ($nullary) {
        given ($nullary) {
            when ("clear_all") { $self->clear_all }
            when ("stack")     { _dump_stack }
            when ("bufs")      { $self->dump_bufs }
            when (/q|quit/)    { die "prolix-quit\n" }
            when (/h|help/)    { $self->help_interactive }
            when ("pats")      { $self->dump_pats }
            when ("stats")     { say $self->stats }
            default            { say q{Unknown command. Try "help".} }
        }
    } else {
        given ($cmd) {
            when (/^\s*(ignore_(?:line|re|substring))\s+(.*)/) {
                my($ignore_type, $pat) = ($1, $2);
                push @{ $self->$ignore_type }, $pat;
                $self->import_re($pat) if $ignore_type eq 're';
            }
            when (/^\s*snippet\s(.*)/) {
                push @{ $self->snippet }, $1;
                $self->import_snippet($1);
            }
            default { say q{Unknown command. Try "help".} }
        }
    }
}

sub import_re {
    my($self, $pat) = @_;

    push @{ $self->_ignore_re }, qr/$pat/;
}

sub import_snippet {
    my($self, $snippet) = @_;

    my $help = <<".";
*** Usage: snippet s/find_re/replace/

    You may use Perl-like quoting on the substitution operation, so if your
    pattern contains slashes use a different delimiter.

    Modifiers that are honored: /igx   (m and s aren't meaningful here)
.

    my @extract = Text::Balanced::extract_quotelike($snippet);
    my($op, $search, $replace, $modifiers) = @extract[3, 5, 8, 10];
    die $help unless $op eq "s";
    die $help unless defined $search;
    die $help unless defined $replace;
    my $mods = "";
    for (qw/i x/) {
        $mods .= $_ if $modifiers =~ /$_/;
    }
    my $global = $modifiers =~ /g/ ? "g" : "";
    my $search_re = qr/(?$mods:$search)/;

    push @{ $self->_snippet }, sub {
        my($line) = @_;
        return Data::Munge::replace($line, $search_re, $replace, $global);
    };
}

sub dump_pats {
    my($self) = @_;

    say "* ignored lines";
    say for @{ $self->ignore_line };
    say "* ignored patterns";
    say for @{ $self->ignore_re };
    say "* ignored substrings";
    say for @{ $self->ignore_substring };
    say "* snippets";
    say for @{ $self->snippet };
}

sub help_interactive {
    my($self) = @_;

    say <<"EOF";
clear_all        - clear all patterns
ignore_line      - add a full match to ignore
ignore_re        - add an ignore pattern, e.g. ^(FINE|DEBUG)
ignore_substring - add a partial match to ignore
pats             - list ignore patterns
quit             - terminate running program
stats            - print stats
snippet          - add a snippet expression, e.g. s/^(INFO|WARNING|ERROR) //

To keep going, just enter an empty line.
EOF
}

sub clear_all {
    my($self) = @_;

    @{ $self->ignore_line } = ();
    @{ $self->ignore_re } = ();
    @{ $self->_ignore_re } = ();
    @{ $self->ignore_substring } = ();
    @{ $self->snippet } = ();
    @{ $self->_snippet } = ();
}

sub dump_bufs {
    my($self) = @_;
    warn "Out: [" . ${$self->_out} . "]\n" .
        "Err: [" . ${$self->_err} . "]\n";
}

sub consume {
    my($self) = @_;

    while (${$self->_out} =~ s/^(.*?)\n//) {
        $self->on_out($1);
    }
    while (${$self->_err} =~ s/^(.*?)\n//) {
        $self->on_err($1);
    }
}

# like consume, but does not require a trailing newline.
sub consume_final {
    my($self) = @_;

    if (length ${$self->_out} > 0) {
        $self->on_out($_) for split /\n/, ${$self->_out};
    }
    if (length ${$self->_err} > 0) {
        $self->on_err($_) for split /\n/, ${$self->_err};
    }
}

sub snip_line {
    my($self, $line) = @_;

    $line = $_->($line) for @{$self->_snippet};

    return $line;
}

sub process_line {
    my($self, $line) = @_;

    for my $exact (@{$self->ignore_line}) {
        if ($line eq $exact) {
            return;
        }
    }
    for my $sub (@{$self->ignore_substring}) {
        if (index($line, $sub) >= 0) {
            return;
        }
    }
    for my $pat (@{$self->_ignore_re}) {
        if ($line =~ $pat) {
            return;
        }
    }
    return $self->snip_line($line);
}

# One day, we might paint this in a different color or something.
sub on_err { goto &on_out }

sub on_out {
    my($self, $line) = @_;
    
    $self->inc__output_lines;
    if (defined($line = $self->process_line($line))) {
        say $line;
        if ($self->_log) {
            $self->_log->print("$line\n");
        }
    } else {
        $self->inc__suppressed;
    }
}

6;

__END__
=pod

=head1 NAME

App::Prolix - trim chatty command outputs

=head1 VERSION

version 0.03

=head1 AUTHOR

Gaal Yahas <gaal@forum2.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Google, Inc.

This is free software, licensed under:

  The MIT (X11) License

=cut

