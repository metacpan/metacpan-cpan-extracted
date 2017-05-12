package Caroline;
use 5.008005;
use strict;
use warnings;
use POSIX qw(termios_h);
use Storable;
use Text::VisualWidth::PP 0.03 qw(vwidth);
use Unicode::EastAsianWidth::Detect qw(is_cjk_lang);
use Term::ReadKey qw(GetTerminalSize ReadLine ReadKey ReadMode);
use IO::Handle;

our $VERSION = "0.22";

our @EXPORT = qw( caroline );

my $HISTORY_NEXT = 0;
my $HISTORY_PREV = 1;

my $IS_WIN32 = $^O eq 'MSWin32';
require Win32::Console::ANSI if $IS_WIN32;

use Class::Accessor::Lite 0.05 (
    rw => [qw(completion_callback history_max_len)],
);

use constant {
    CTRL_A => 1,
    CTRL_B => 2,
    CTRL_C => 3,
    CTRL_D => 4,
    CTRL_E => 5,
    CTRL_F => 6,
    CTRL_H => 8,
    CTRL_I => 9,
    CTRL_K => 11,
    CTRL_L => 12,
    CTRL_M => 13,
    CTRL_N => 14,
    CTRL_P => 16,
    CTRL_R => 18,
    CTRL_T => 20,
    CTRL_U => 21,
    CTRL_W => 23,
    CTRL_Z => 26,
    BACKSPACE => 127,
    ENTER => 13,
    TAB => 9,
    ESC => 27,
};

sub new {
    my $class = shift;
    my %args = @_==1? %{$_[0]} : @_;
    my $self = bless {
        history => [],
        debug => !!$ENV{CAROLINE_DEBUG},
        multi_line => 1,
        history_max_len => 100,
        %args
    }, $class;
    return $self;
}

sub debug {
    my ($self, $stuff) = @_;
    return unless $self->{debug};

#   require JSON::PP;
    open my $fh, '>>:utf8', 'caroline.debug.log';
    print $fh $stuff;
#   print $fh JSON::PP->new->allow_nonref(1)->encode($stuff) . "\n";
    close $fh;
}

sub history { shift->{history} }

sub history_len {
    my $self = shift;
    0+@{$self->{history}};
}

sub DESTROY {
    my $self = shift;
    $self->disable_raw_mode();
}

sub readline {
    my ($self, $prompt) = @_;
    $prompt = '> ' unless defined $prompt;
    STDOUT->autoflush(1);

    local $Text::VisualWidth::PP::EastAsian = is_cjk_lang;

    if ($self->is_supported && -t STDIN) {
        return $self->read_raw($prompt);
    } else {
        print STDOUT $prompt;
        STDOUT->flush;
        # I need to use ReadLine() to support Win32.
        my $line = ReadLine(0);
        $line =~ s/\n$// if defined $line;
        return $line;
    }
}

sub get_columns {
    my $self = shift;
    my ($wchar, $hchar, $wpixels, $hpixels) = GetTerminalSize();
    return $wchar;
}

sub readkey {
    my $self = shift;
    my $c = ReadKey(0);
    return undef unless defined $c;
    return $c unless $IS_WIN32;

    # Win32 API always return the bytes encoded with ACP. So it must be
    # decoded from double byte sequence. To detect double byte sequence, it
    # use Win32 API IsDBCSLeadByte.
    require Win32::API;
    require Encode;
    require Term::Encoding;
    $self->{isleadbyte} ||= Win32::API->new(
      'kernel32', 'int IsDBCSLeadByte(char a)',
    );
    $self->{encoding} ||= Term::Encoding::get_encoding();
    if ($self->{isleadbyte}->Call($c)) {
        $c .= ReadKey(0);
        $c = Encode::decode($self->{encoding}, $c);
    }
    $c;
}

# linenoiseRaw
sub read_raw {
    my ($self, $prompt) = @_;

    local $self->{sigint};
    local $self->{sigtstp};
    my $ret;
    {
        $self->enable_raw_mode();
        $ret = $self->edit($prompt);
        $self->disable_raw_mode();
    }
    print STDOUT "\n";
    STDOUT->flush;
    if ($self->{sigint}) {
        kill 'INT', $$;
    } elsif ($self->{sigtstp}) {
        kill $IS_WIN32 ? 'INT' : 'TSTP', $$;
    }
    return $ret;
}

sub enable_raw_mode {
    my $self = shift;

    if ($IS_WIN32) {
        ReadMode(5);
        return undef;
    }
    my $termios = POSIX::Termios->new;
    $termios->getattr(0);
    $self->{rawmode} = [$termios->getiflag, $termios->getoflag, $termios->getcflag, $termios->getlflag, $termios->getcc(VMIN), $termios->getcc(VTIME)];
    $termios->setiflag($termios->getiflag & ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON));
    $termios->setoflag($termios->getoflag & ~(OPOST));
    $termios->setcflag($termios->getcflag | ~(CS8));
    $termios->setlflag($termios->getlflag & ~(ECHO|ICANON|IEXTEN | ISIG));
    $termios->setcc(VMIN, 1);
    $termios->setcc(VTIME, 0);
    $termios->setattr(0, TCSAFLUSH);
    return undef;
}

sub disable_raw_mode {
    my $self = shift;

    if ($IS_WIN32) {
        ReadMode(0);
        return undef;
    }
    if (my $r = delete $self->{rawmode}) {
        my $termios = POSIX::Termios->new;
        $termios->getattr(0);
        $termios->setiflag($r->[0]);
        $termios->setoflag($r->[1]);
        $termios->setcflag($r->[2]);
        $termios->setlflag($r->[3]);
        $termios->setcc(VMIN, $r->[4]);
        $termios->setcc(VTIME, $r->[5]);
        $termios->setattr(0, TCSAFLUSH);
    }
    return undef;
}

sub history_add {
    my ($self, $line) = @_;
    if (@{$self->{history}}+1 > $self->history_max_len) {
        shift @{$self->{history}};
    }
    push @{$self->{history}}, $line;
}

sub edit {
    my ($self, $prompt) = @_;
    print STDOUT $prompt;
    STDOUT->flush;

    $self->history_add('');

    my $state = Caroline::State->new;
    $state->{prompt} = $prompt;
    $state->cols($self->get_columns);
    $self->debug("Columns: $state->{cols}\n");

    while (1) {
        my $c = $self->readkey;
        unless (defined $c) {
            return $state->buf;
        }
        my $cc = ord($c) or next;

        if ($cc == TAB && defined $self->{completion_callback}) {
            $c = $self->complete_line($state);
            return undef unless defined $c;
            $cc = ord($c);
            next if $cc == 0;
        }

        if ($cc == ENTER) { # enter
            pop @{$self->{history}};
            return $state->buf;
        } elsif ($cc==CTRL_C) { # ctrl-c
            $self->{sigint}++;
            return undef;
        } elsif ($cc==CTRL_Z) { # ctrl-z
            $self->{sigtstp}++;
            return $state->buf;
        } elsif ($cc == BACKSPACE || $cc == CTRL_H) { # backspace or ctrl-h
            $self->edit_backspace($state);
        } elsif ($cc == CTRL_D) { # ctrl-d
            if (length($state->buf) > 0) {
                $self->edit_delete($state);
            } else {
                return undef;
            }
        } elsif ($cc == CTRL_T) { # ctrl-t
            # swaps current character with prvious
            if ($state->pos > 0 && $state->pos < $state->len) {
                my $aux = substr($state->buf, $state->pos-1, 1);
                substr($state->{buf}, $state->pos-1, 1) = substr($state->{buf}, $state->pos, 1);
                substr($state->{buf}, $state->pos, 1) = $aux;
                if ($state->pos != $state->len -1) {
                    $state->{pos}++;
                }
            }
            $self->refresh_line($state);
        } elsif ($cc == CTRL_B) { # ctrl-b
            $self->edit_move_left($state);
        } elsif ($cc == CTRL_F) { # ctrl-f
            $self->edit_move_right($state);
        } elsif ($cc == CTRL_P) { # ctrl-p
            $self->edit_history_next($state, $HISTORY_PREV);
        } elsif ($cc == CTRL_N) { # ctrl-n
            $self->edit_history_next($state, $HISTORY_NEXT);
        } elsif ($cc == 27) { # escape sequence
            # Read the next two bytes representing the escape sequence
            my $buf = $self->readkey or return undef;
            $buf .= $self->readkey or return undef;

            if ($buf eq "[D") { # left arrow
                $self->edit_move_left($state);
            } elsif ($buf eq "[C") { # right arrow
                $self->edit_move_right($state);
            } elsif ($buf eq "[A") { # up arrow
                $self->edit_history_next($state, $HISTORY_PREV);
            } elsif ($buf eq "[B") { # down arrow
                $self->edit_history_next($state, $HISTORY_NEXT);
            } elsif ($buf eq "[1") { # home
                $buf = $self->readkey or return undef;
                if ($buf eq '~') {
                    $state->{pos} = 0;
                    $self->refresh_line($state);
                }
            } elsif ($buf eq "[4") { # end
                $buf = $self->readkey or return undef;
                if ($buf eq '~') {
                    $state->{pos} = length($state->buf);
                    $self->refresh_line($state);
                }
            }
            # TODO:
#           else if (seq[0] == 91 && seq[1] > 48 && seq[1] < 55) {
#               /* extended escape, read additional two bytes. */
#               if (read(fd,seq2,2) == -1) break;
#               if (seq[1] == 51 && seq2[0] == 126) {
#                   /* Delete key. */
#                   linenoiseEditDelete(&l);
#               }
#           }
        } elsif ($cc == CTRL_U) { # ctrl-u
            # delete the whole line.
            $state->{buf} = '';
            $state->{pos} = 0;
            $self->refresh_line($state);
        } elsif ($cc == CTRL_K) { # ctrl-k
            substr($state->{buf}, $state->{pos}) = '';
            $self->refresh_line($state);
        } elsif ($cc == CTRL_A) { # ctrl-a
            $state->{pos} = 0;
            $self->refresh_line($state);
        } elsif ($cc == CTRL_E) { # ctrl-e
            $state->{pos} = length($state->buf);
            $self->refresh_line($state);
        } elsif ($cc == CTRL_L) { # ctrl-l
            $self->clear_screen();
            $self->refresh_line($state);
        } elsif ($cc == CTRL_R) { # ctrl-r
            $self->search($state);
        } elsif ($cc == CTRL_W) { # ctrl-w
            $self->edit_delete_prev_word($state);
        } else {
            $self->debug("inserting $cc\n");
            $self->edit_insert($state, $c);
        }
    }
    return $state->buf;
}

sub read_history_file {
    my ($self, $filename) = @_;
    open my $fh, '<:encoding(utf-8)', $filename
        or return undef;
    while (my $hist = <$fh>) {
        chomp($hist);
        $self->history_add($hist);
    }
    close $fh;
    return 1;
}

sub write_history_file {
    my ($self, $filename) = @_;

    return undef if $self->history_max_len == 0;

    open my $fh, '>:encoding(utf-8)', $filename
        or return undef;
    for my $hist (@{$self->history}) {
        next unless $hist =~ /\S/;
        print $fh $hist . "\n";
    }
    close $fh;
    return 1;
}

sub edit_delete {
    my ($self, $status) = @_;
    if ($status->len > 0 && $status->pos < $status->len) {
        substr($status->{buf}, $status->pos, 1) = '';
        $self->refresh_line($status);
    }
}

sub search {
    my ($self, $state) = @_;

    my $query = '';
    local $state->{query} = '';
    LOOP:
    while (1) {
        my $c = $self->readkey;
        unless (defined $c) {
            return $state->buf;
        }
        my $cc = ord($c) or next;

        if (
            $cc == CTRL_B
            || $cc == CTRL_C
            || $cc == CTRL_F
            || $cc == ENTER
        ) {
            return;
        }
        if ($cc == BACKSPACE || $cc == CTRL_H) {
            $self->debug("ctrl-h in searching\n");
            $query =~ s/.\z//;
        } else {
            $query .= $c;
        }
        $self->debug("C: $cc\n");

        $state->query($query);
        $self->debug("Searching '$query'\n");
        SEARCH:
        for my $hist (@{$self->history}) {
            if ((my $idx = index($hist, $query)) >= 0) {
                $state->buf($hist);
                $state->pos($idx);
                $self->refresh_line($state);
                next LOOP;
            }
        }
        $self->beep();
        $self->refresh_line($state);
    }
}

sub complete_line {
    my ($self, $state) = @_;

    my @ret = grep { defined $_ } $self->{completion_callback}->($state->buf, $state->pos);
    unless (@ret) {
        $self->beep;
        return "\0";
    }

    my $i = 0;
    while (1) {
        # Show completion or original buffer
        if ($i < @ret) {
            my $cloned = Storable::dclone($state);
            $cloned->{buf} = $ret[$i];
            $cloned->{pos} = $state->pos + length($cloned->{buf}) - length($state->buf);
            $self->refresh_line($cloned);
        } else {
            $self->refresh_line($state);
        }

        my $c = $self->readkey;
        unless (defined $c) {
            return undef;
        }
        my $cc = ord($c) or next;

        if ($cc == TAB) { # tab
            $i = ($i+1) % (1+@ret);
            if ($i==@ret) {
                $self->beep();
            }
        } elsif ($cc == ESC) { # escape
            # Re-show original buffer
            if ($i<@ret) {
                $self->refresh_line($state);
            }
            return $c;
        } else {
            # Update buffer and return
            if ($i<@ret) {
                $state->{pos} = $state->{pos} + length($ret[$i]) - length($state->{buf});
                $state->{buf} = $ret[$i];
            }
            return $c;
        }
    }
}

sub beep {
    my $self = shift;
    $self->debug("Beep!\n");
    print STDERR "\x7";
    STDERR->flush;
}

sub edit_delete_prev_word {
    my ($self, $state) = @_;

    my $old_pos = $state->pos;
    while ($state->pos > 0 && substr($state->buf, $state->pos-1, 1) eq ' ') {
        $state->{pos}--;
    }
    while ($state->pos > 0 && substr($state->buf, $state->pos-1, 1) ne ' ') {
        $state->{pos}--;
    }
    my $diff = $old_pos - $state->pos;
    substr($state->{buf}, $state->pos, $diff) = '';
    $self->refresh_line($state);
}

sub edit_history_next {
    my ($self, $state, $dir) = @_;
    if ($self->history_len > 1) {
        $self->history->[$self->history_len-1-$state->{history_index}] = $state->buf;
        $state->{history_index} += ( ($dir == $HISTORY_PREV) ? 1 : -1 );
        if ($state->{history_index} < 0) {
            $state->{history_index} = 0;
            return;
        } elsif ($state->{history_index} >= $self->history_len) {
            $state->{history_index} = $self->history_len-1;
            return;
        }
        $state->{buf} = $self->history->[$self->history_len - 1 - $state->{history_index}];
        $state->{pos} = $state->len;
        $self->refresh_line($state);
    }
}

sub edit_backspace {
    my ($self, $state) = @_;
    if ($state->pos > 0 && length($state->buf) > 0) {
        substr($state->{buf}, $state->pos-1, 1) = '';
        $state->{pos}--;
        $self->refresh_line($state);
    }
}

sub clear_screen {
    my ($self) = @_;
    print STDOUT "\x1b[H\x1b[2J";
}

sub refresh_line {
    my ($self, $state) = @_;
    if ($self->{multi_line}) {
        $self->refresh_multi_line($state);
    } else {
        $self->refresh_single_line($state);
    }
}

sub refresh_multi_line {
    my ($self, $state) = @_;

    my $plen = vwidth($state->prompt);
    $self->debug($state->buf.  "\n");

    # rows used by current buf
    my $rows = int(($plen + vwidth($state->buf) + $state->cols -1) / $state->cols);
    if (defined $state->query) {
        $rows++;
    }

    # cursor relative row
    my $rpos = int(($plen + $state->oldpos + $state->cols) / $state->cols);

    my $old_rows = $state->maxrows;

    # update maxrows if needed.
    if ($rows > $state->maxrows) {
        $state->maxrows($rows);
    }

    $self->debug(sprintf "[%d %d %d] p: %d, rows: %d, rpos: %d, max: %d, oldmax: %d",
                $state->len, $state->pos, $state->oldpos, $plen, $rows, $rpos, $state->maxrows, $old_rows);

    # First step: clear all the lines used before. To do start by going to the last row.
    if ($old_rows - $rpos > 0) {
        $self->debug(sprintf ", go down %d", $old_rows-$rpos);
        printf STDOUT "\x1b[%dB", $old_rows-$rpos;
    }

    # Now for every row clear it, go up.
    my $j;
    for ($j=0; $j < ($old_rows-1); ++$j) {
        $self->debug(sprintf ", clear+up %d %d", $old_rows-1, $j);
        print("\x1b[0G\x1b[0K\x1b[1A");
    }

    # Clean the top line
    $self->debug(", clear");
    print("\x1b[0G\x1b[0K");

    # Write the prompt and the current buffer content
    print $state->prompt;
    print $state->buf;
    if (defined $state->query) {
        print "\015\nSearch: " . $state->query;
    }

    # If we are at the very end of the screen with our prompt, we need to
    # emit a newline and move the prompt to the first column
    if ($state->pos && $state->pos == $state->len && ($state->pos + $plen) % $state->cols == 0) {
        $self->debug("<newline>");
        print "\n";
        print "\x1b[0G";
        $rows++;
        if ($rows > $state->maxrows) {
            $state->maxrows(int $rows);
        }
    }

    # Move cursor to right position
    my $rpos2 = int(($plen + $state->vpos + $state->cols) / $state->cols); # current cursor relative row
    $self->debug(sprintf ", rpos2 %d", $rpos2);
    # Go up till we reach the expected position
    if ($rows - $rpos2 > 0) {
        # cursor up
        printf "\x1b[%dA", $rows-$rpos2;
    }

    # Set column
    my $col;
    {
        $col = 1;
        my $buf = $state->prompt . substr($state->buf, 0, $state->pos);
        for (split //, $buf) {
            $col += vwidth($_);
            if ($col > $state->cols) {
                $col -= $state->cols;
            }
        }
    }
    $self->debug(sprintf ", set col %d", $col);
    printf "\x1b[%dG", $col;

    $state->oldpos($state->pos);

    $self->debug("\n");
}

sub refresh_single_line {
    my ($self, $state) = @_;

    my $buf = $state->buf;
    my $len = $state->len;
    my $pos = $state->pos;
    while ((vwidth($state->prompt)+$pos) >= $state->cols) {
        substr($buf, 0, 1) = '';
        $len--;
        $pos--;
    }
    while (vwidth($state->prompt) + vwidth($buf) > $state->cols) {
        $len--;
    }

    print STDOUT "\x1b[0G"; # cursor to left edge
    print STDOUT $state->{prompt};
    print STDOUT $buf;
    print STDOUT "\x1b[0K"; # erase to right

    # Move cursor to original position
    printf "\x1b[0G\x1b[%dC", (
        length($state->{prompt})
        + vwidth(substr($buf, 0, $pos))
    );
}

sub edit_move_right {
    my ($self, $state) = @_;
    if ($state->pos != length($state->buf)) {
        $state->{pos}++;
        $self->refresh_line($state);
    }
}

sub edit_move_left {
    my ($self, $state) = @_;
    if ($state->pos > 0) {
        $state->{pos}--;
        $self->refresh_line($state);
    }
}


sub edit_insert {
    my ($self, $state, $c) = @_;
    if (length($state->buf) == $state->pos) {
        $state->{buf} .= $c;
    } else {
        substr($state->{buf}, $state->{pos}, 0) = $c;
    }
    $state->{pos}++;
    $self->refresh_line($state);
}

sub is_supported {
    my ($self) = @_;
    return 1 if $IS_WIN32;
    my $term = $ENV{'TERM'};
    return 0 unless defined $term;
    return 0 if $term eq 'dumb';
    return 0 if $term eq 'cons25';
    return 1;
}

package Caroline::State;

use Class::Accessor::Lite 0.05 (
    rw => [qw(buf pos cols prompt oldpos maxrows query)],
);

sub new {
    my $class = shift;
    bless {
        buf => '',
        pos => 0,
        history_index => 0,
        oldpos => 0,
        maxrows => 0,
    }, $class;
}
use Text::VisualWidth::PP 0.03 qw(vwidth);

sub len { length(shift->buf) }
sub plen { length(shift->prompt) }

sub vpos {
    my $self = shift;
    vwidth(substr($self->buf, 0, $self->pos));
}

sub width {
    my $self = shift;
    vwidth($self->prompt . $self->buf);
}

1;
__END__

=for stopwords binmode

=encoding utf-8

=head1 NAME

Caroline - Yet another line editing library 

=head1 SYNOPSIS

    use Caroline;
    use Term::Encoding qw(term_encoding);

    my $encoding = term_encoding();
    binmode *STDIN, ":encoding(${encoding})";
    binmode *STDOUT, ":encoding(${encoding})";

    my $c = Caroline->new;
    while (defined(my $line = $c->readline('> '))) {
        if ($line =~ /\S/) {
            print eval $line;
        }
    }

=head1 DESCRIPTION

Caroline is yet another line editing library like L<Term::ReadLine::Gnu>.

This module supports

=over 4

=item History handling

=item Complition

=item Portable

=item No C library dependency

=back

=head1 PROJECT GOALS

Provides portable line editing library for Perl5 community.

=head1 METHODS

=over 4

=item my $caroline = Caroline->new();

Create new Caroline instance.

Options are:

=over 4

=item history_max_len : Str

Set the limitation for max history size.

=item completion_callback : CodeRef

You can write completion callback function like this:

    use Caroline;
    my $c = Caroline->new(
        completion_callback => sub {
            my ($line) = @_;
            if ($line eq 'h') {
                return (
                    'hello',
                    'hello there'
                );
            } elsif ($line eq 'm') {
                return (
                    '突然のmattn'
                );
            }
            return;
        },
    );

=back

=item C<< my $line = $caroline->read($prompt); >>

Read line with C<$prompt>.

Trailing newline is removed. Returns undef on EOF.

=item C<< $caroline->history_add($line) >> 

Add $line to the history.

=item C<< $caroline->history() >>

Get the current history data in C< ArrayRef[Str] >.

=item C<< $caroline->write_history_file($filename) >>

Write history data to the file.

=item C<< $caroline->read_history_file($filename) >>

Read history data from history file.

=back

=head1 Multi byte character support

If you want to support multi byte characters, you need to set binmode to STDIN.
You can add the following code before call Caroline.

    use Term::Encoding qw(term_encoding);
    my $encoding = term_encoding();
    binmode *STDIN, ":encoding(${encoding})";

=head1 About east Asian ambiguous width characters

Caroline detects east Asian ambiguous character width from environment variable using L<Unicode::EastAsianWidth::Detect>.

User need to set locale correctly. For more details, please read L<Unicode::EastAsianWidth::Detect>.

=head1 LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<https://github.com/antirez/linenoise/blob/master/linenoise.c>

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

mattn

=cut

