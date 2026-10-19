#!perl
use v5.38;
use utf8;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Time::HiRes qw(sleep);
use Antsy 0.908 qw( cursor_hide cursor_show );

package Subtask {
	use Antsy 0.908 qw(
		bold faint text_green text_yellow text_red reset_all
		cursor_previous_line cursor_line_start
		erase_line erase_to_end_of_screen
		);

	my %STYLE = (
		running => [ '▸', \&bold        ],
		ok      => [ '✔', \&text_green  ],
		warn    => [ '!', \&text_yellow ],
		fail    => [ '✘', \&text_red    ],
	);

	sub new ( $class, %args ) {
		my $self = bless {
			name   => $args{name},
			keep   => $args{keep} // 5,
			tty    => $args{tty},
			width  => $args{width} // 80,
			window => [],
		}, $class;
		$self->_header('running');
		return $self;
	}

	# Add an output line. On a terminal, redraw the window of the last
	# "keep" lines in place; otherwise just print the line.
	sub line ( $self, $text ) {
		unless( $self->{tty} ) {
			say "    $text";
			return;
		}

		my $window = $self->{window};
		my $shown  = @$window;
		push @$window, $text;
		shift @$window while @$window > $self->{keep};

		# Go back up to the first row of the window. When nothing is shown
		# yet, cursor_previous_line(0) just goes to the start of this row.
		print cursor_previous_line( $shown );
		print erase_line, faint, $self->_fit("    $_"), reset_all, "\n"
			for @$window;
	}

	# Collapse the window and redraw the header with its final status.
	sub finish ( $self, $status, $message = undef ) {
		if( $self->{tty} ) {
			my $up = @{ $self->{window} } + 1;
			print cursor_previous_line( $up ), erase_to_end_of_screen;
		}
		$self->{window} = [];
		$self->_header( $status, $message );
	}

	sub _header ( $self, $status, $message = undef ) {
		my( $symbol, $color ) = $STYLE{$status}->@*;
		my $text = "$symbol $self->{name}";
		$text .= " — $message" if defined $message;

		if( $self->{tty} ) {
			print cursor_line_start, erase_line,
				$color->(), $self->_fit($text), reset_all, "\n";
		}
		else {
			say $text;
		}
	}

	# Truncate to one screen row. Stop one column short of the edge so the
	# terminal never wraps.
	sub _fit ( $self, $text ) {
		my $max = $self->{width} - 1;
		return $text if length $text <= $max;
		return substr( $text, 0, $max - 1 ) . '…';
	}
}

binmode STDOUT, ':encoding(UTF-8)';
$| = 1;

my $IS_TTY = -t STDOUT;
my $WIDTH  = terminal_width();
my $DELAY  = $IS_TTY ? 0.15 : 0;

if( $IS_TTY ) {
	print cursor_hide;    # hide the cursor while we redraw
	$SIG{INT} = sub { print cursor_show, "\n"; exit 130 };
}
END { print cursor_show if $IS_TTY }

my @subtasks = (
	{ name => 'Parse web server log', keep => 5, code => \&parse_log },
	{ name => 'Validate ISBNs',       keep => 4, code => \&validate_isbns },
	{ name => 'Count word frequency', keep => 3, code => \&count_words },
);

foreach my $spec ( @subtasks ) {
	my $task = Subtask->new(
		name  => $spec->{name},
		keep  => $spec->{keep},
		tty   => $IS_TTY,
		width => $WIDTH,
	);
	my( $status, $message ) = eval { $spec->{code}->($task) };
	( $status, $message ) = ( 'fail', $@ =~ s/\s+\z//r ) unless defined $status;
	$task->finish( $status, $message );
}

sub pause () { sleep $DELAY if $DELAY }

sub terminal_width () {
	return $ENV{COLUMNS} if ( $ENV{COLUMNS} // '' ) =~ /\A\d+\z/;
	return 80 unless $IS_TTY;
	my $size = `stty size 2>/dev/null < /dev/tty`;
	return $size =~ /\A\d+\s+(\d+)/ ? $1 : 80;
}

# Subtask 1: parse an Apache-style access log and report each request.
sub parse_log ( $task ) {
	my( $requests, $errors, $bytes ) = ( 0, 0, 0 );

	foreach my $entry ( split /\n/, sample_log() ) {
		my( $ip, $method, $path, $code, $size ) = $entry =~ m{
			\A (\S+) \s \S+ \s \S+ \s \[[^\]]+\] \s
			"(\S+) \s (\S+) \s [^"]+" \s (\d{3}) \s (\d+|-)
			}x or next;
		$size = 0 if $size eq '-';
		$requests++;
		$bytes += $size;
		$errors++ if $code >= 400;
		$task->line( sprintf '%-15s %-4s %-28s %s %7.1f KB',
			$ip, $method, $path, $code, $size / 1024 );
		pause();
	}

	my $summary = sprintf '%d requests, %d errors, %.1f KB',
		$requests, $errors, $bytes / 1024;
	return ( $errors ? 'warn' : 'ok', $summary );
}

# Subtask 2: check the ISBN-13 check digit for each book.
sub validate_isbns ( $task ) {
	my( $valid, $invalid ) = ( 0, 0 );

	foreach my $book ( sample_books() ) {
		my( $isbn, $title ) = @$book;
		my $ok = isbn13_is_valid($isbn);
		$ok ? $valid++ : $invalid++;
		$task->line( sprintf '%s  %-7s %s', $isbn, $ok ? 'valid' : 'INVALID', $title );
		pause();
	}

	my $summary = "$valid valid, $invalid invalid";
	return ( $invalid ? 'warn' : 'ok', $summary );
}

sub isbn13_is_valid ( $isbn ) {
	my @digits = split //, $isbn;
	return 0 unless @digits == 13 && $isbn =~ /\A\d+\z/;
	my $sum = 0;
	$sum += $digits[$_] * ( $_ % 2 ? 3 : 1 ) for 0 .. 12;
	return $sum % 10 == 0;
}

# Subtask 3: tally word frequencies sentence by sentence.
sub count_words ( $task ) {
	my %count;
	my $total    = 0;
	my @sentences = grep { /\S/ } split /(?<=[.?!])\s+/, sample_text();

	foreach my $i ( keys @sentences ) {
		my @words = map { lc } $sentences[$i] =~ /([A-Za-z']+)/g;
		$count{$_}++ for @words;
		$total += @words;
		my( $top ) = sort { $count{$b} <=> $count{$a} || $a cmp $b } keys %count;
		$task->line( sprintf 'sentence %2d: %2d words; leader so far "%s" (%d)',
			$i + 1, scalar @words, $top, $count{$top} );
		pause() for 1 .. 3;
	}

	my( $top ) = sort { $count{$b} <=> $count{$a} || $a cmp $b } keys %count;
	return ( 'ok', sprintf '%d words, %d distinct, most common "%s"',
		$total, scalar keys %count, $top );
}

sub sample_log () {
	<<~'LOG';
	203.0.113.7 - - [18/Oct/2026:09:14:02 -0400] "GET / HTTP/1.1" 200 5120
	203.0.113.7 - - [18/Oct/2026:09:14:02 -0400] "GET /css/site.css HTTP/1.1" 200 18342
	198.51.100.23 - - [18/Oct/2026:09:14:05 -0400] "GET /books/learning-perl HTTP/1.1" 200 22410
	198.51.100.23 - - [18/Oct/2026:09:14:06 -0400] "GET /img/cover-lp8.jpg HTTP/1.1" 200 148220
	192.0.2.44 - - [18/Oct/2026:09:14:09 -0400] "POST /api/search HTTP/1.1" 200 3311
	192.0.2.44 - - [18/Oct/2026:09:14:10 -0400] "GET /books/missing-title HTTP/1.1" 404 512
	203.0.113.90 - - [18/Oct/2026:09:14:12 -0400] "GET /feed.xml HTTP/1.1" 304 -
	198.51.100.8 - - [18/Oct/2026:09:14:15 -0400] "GET /about HTTP/1.1" 200 7634
	198.51.100.8 - - [18/Oct/2026:09:14:15 -0400] "GET /js/app.js HTTP/1.1" 200 40211
	192.0.2.101 - - [18/Oct/2026:09:14:18 -0400] "POST /api/cart HTTP/1.1" 500 128
	203.0.113.7 - - [18/Oct/2026:09:14:20 -0400] "GET /books/intermediate-perl HTTP/1.1" 200 21877
	203.0.113.7 - - [18/Oct/2026:09:14:21 -0400] "GET /img/cover-ip2.jpg HTTP/1.1" 200 131005
	198.51.100.23 - - [18/Oct/2026:09:14:24 -0400] "GET /checkout HTTP/1.1" 302 0
	198.51.100.23 - - [18/Oct/2026:09:14:25 -0400] "GET /login HTTP/1.1" 200 4410
	192.0.2.44 - - [18/Oct/2026:09:14:29 -0400] "GET /admin HTTP/1.1" 403 256
	203.0.113.90 - - [18/Oct/2026:09:14:31 -0400] "GET /robots.txt HTTP/1.1" 200 68
	198.51.100.8 - - [18/Oct/2026:09:14:33 -0400] "GET /books/mastering-perl HTTP/1.1" 200 20993
	192.0.2.101 - - [18/Oct/2026:09:14:36 -0400] "POST /api/cart HTTP/1.1" 200 932
	203.0.113.7 - - [18/Oct/2026:09:14:40 -0400] "GET /sitemap.xml HTTP/1.1" 200 2544
	198.51.100.23 - - [18/Oct/2026:09:14:42 -0400] "POST /login HTTP/1.1" 200 610
	LOG
}

sub sample_books () {
	(
		[ '9780596000271', 'The Lighthouse Keeper\'s Ledger' ],
		[ '9781492032137', 'Patterns in Quiet Water' ],
		[ '9781934356172', 'A Field Guide to Small Machines' ],
		[ '9781118119372', 'Twelve Bridges North' ],
		[ '9780321784148', 'The Cartographer\'s Apprentice' ],
		[ '9780981653907', 'Notes from the Night Ferry' ],
		[ '9780307610025', 'An Almanac of Tides' ],
		[ '9781558607231', 'Practical Clockwork' ],
		[ '9780865471269', 'The Orchard at Wexley' ],
		[ '9780201616224', 'Letters to a Young Engineer' ],
		[ '9781843560012', 'Salt and Signal' ],
		[ '9780596520687', 'The Long Way Round the Lake' ],
	);
}

# The Gettysburg Address (public domain).
sub sample_text () {
	<<~'TEXT';
	Four score and seven years ago our fathers brought forth on this
	continent, a new nation, conceived in Liberty, and dedicated to the
	proposition that all men are created equal. Now we are engaged in a
	great civil war, testing whether that nation, or any nation so conceived
	and so dedicated, can long endure. We are met on a great battle-field of
	that war. We have come to dedicate a portion of that field, as a final
	resting place for those who here gave their lives that that nation
	might live. It is altogether fitting and proper that we should do this.
	But, in a larger sense, we can not dedicate, we can not consecrate, we
	can not hallow, this ground. The brave men, living and dead, who
	struggled here, have consecrated it, far above our poor power to add or
	detract. The world will little note, nor long remember what we say
	here, but it can never forget what they did here. It is for us the
	living, rather, to be dedicated here to the unfinished work which they
	who fought here have thus far so nobly advanced. It is rather for us to
	be here dedicated to the great task remaining before us, that from
	these honored dead we take increased devotion to that cause for which
	they gave the last full measure of devotion, that we here highly
	resolve that these dead shall not have died in vain, that this nation,
	under God, shall have a new birth of freedom, and that government of the
	people, by the people, for the people, shall not perish from the earth.
	TEXT
}

__END__

=encoding utf8

=head1 NAME

subtasks.pl - show subtasks with persistent headers and scrolling output

=head1 SYNOPSIS

	$ perl examples/subtasks.pl

=head1 DESCRIPTION

Runs three sample subtasks one after the other, using sample data built
into the program, and draws all of its terminal output with L<Antsy>:

=over 4

=item * Parse web server log - parse an Apache-style access log

=item * Validate ISBNs - check ISBN-13 check digits for a list of books

=item * Count word frequency - tally words in the Gettysburg Address

=back

Each subtask prints a header line. While it runs, only its last few
output lines show under the header, and older lines scroll off. When it
finishes, those lines are erased and the header updates with a status
symbol, color, and summary: green for success, yellow for warnings, red
for failure. The next subtask's header appears directly below.

When output isn't a terminal, the program prints every header and line
as plain text with no cursor movement or color.

This started as a demonstration program in a separate project, which
also has versions that use L<Term::ANSIColor> and hand-written escape
sequences.

=head1 REQUIREMENTS

This needs Antsy 0.908 or later, which has the functions this program
uses, such as C<erase_to_end_of_screen> and C<cursor_line_start>, and
fixes C<cursor_previous_line(0)>. It loads the Antsy in this
distribution's F<lib> directory, so run it from a checkout of Antsy.
With an older Antsy, the program stops right away with Perl's
"version 0.908 required" error.

=head1 HOW THE OUTPUT WORKS

The program never uses a full-screen library such as curses. It prints
ordinary lines and uses a few Antsy functions to move back up over lines
it has already printed and redraw them in place:

=over 4

=item C<cursor_previous_line(N)>

Move the cursor up N rows, to the start of the row. C<cursor_previous_line(0)>
only moves to the start of the current row, which is what the program
needs before anything is shown under a header.

=item C<cursor_line_start>

Move the cursor to the start of the current row.

=item C<erase_line>

Erase the current row.

=item C<erase_to_end_of_screen>

Erase from the cursor to the end of the screen.

=item C<cursor_hide> and C<cursor_show>

Hide and show the cursor.

=back

Colors come from Antsy too: C<bold> for a running header, C<text_green>,
C<text_yellow>, and C<text_red> for finished ones, and C<faint> for the
output lines, each followed by C<reset_all>.

Each C<Subtask> remembers its window: the last I<N> lines it has shown.
The cursor always sits on the row just below the window.

=over 4

=item * Starting a subtask

Prints the header and a newline. The window is empty.

=item * Adding a line

Appends the line to the window and drops the oldest line once there are
more than I<N>. The program then moves the cursor up by the number of
rows it showed before and reprints every line in the window, erasing
each row first. The window never shrinks while the subtask runs, so the
reprinted lines always cover the old ones. Dropping the oldest line makes
the window appear to scroll.

=item * Finishing a subtask

Moves the cursor up over the window and the header, erases everything
from there to the end of the screen, and prints the updated header. The
cursor ends up on the row below that header, so the next subtask's header
appears directly beneath it.

=back

Every row is truncated to one column less than the terminal width. A
line that wrapped would take up two rows, which would throw off the
count of rows to move back up over. Stopping short of the last column
also avoids terminals that wrap when a character lands in it.

The terminal width comes from C<COLUMNS> if it's set, and otherwise from
C<stty size>, falling back to 80. When standard output isn't a terminal,
none of this happens: the program prints every line as it comes.

=head1 SOURCE AVAILABILITY

This source is in GitHub:

	https://github.com/briandfoy/antsy

=head1 AUTHOR

Claude Opus 5.5 (Anthropic), author

brian d foy, C<< <briandfoy@pobox.com> >>, supervisor

=head1 COPYRIGHT AND LICENSE

Copyright © 2026, brian d foy C<< <briandfoy@pobox.com> >>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut
