#!perl
use v5.26;
use utf8;
use open qw(:std :utf8);

use FindBin qw($Bin);
use lib "$FindBin::Bin/../lib";

use Tie::Cycle;
use Time::HiRes qw(sleep);
use Antsy qw(:all);

$|++;

LINES_TASK: {
	my @lines = map { "Line $_" } 0 .. 2;
	print bg_cyan, "🐪", bold,  text_white, " Starting some task", reset_all, cursor_next_line(1);
	foreach my $line ( @lines ) {
		print '  ' . $line, cursor_next_line(1);
		sleep(0.5);
		}

	# you need to go up one more than you think
	print
		cursor_previous_line(4),
		clear_to_screen_end(),
		"✅ Done with some task!",
		cursor_next_line(1)
		;
	}

SPINNER_TASK: {
	my @lines = map { "Task $_" } 0 .. 2;
	tie my $cycle, 'Tie::Cycle', [ qw( / - \ | ) ];

	print bg_cyan, "🐪", bold, text_white, " Starting spinner task", reset_all, cursor_next_line(1);
	foreach my $line ( @lines ) {
		print '  ' . $line, '  ';
		my $end = time + 2;
		while(1) {
			print cursor_back(1), $cycle;
			last if time > $end;
			sleep(0.15);
			}
		print cursor_back(1), "- ", bold, text_green, "Done!", reset_all, cursor_next_line(1);
		sleep 1;
		}

	print
		cursor_previous_line(4),
		clear_to_screen_end(),
		"✅ Done with spinner task!",
		cursor_next_line(1)
		;
	}

print clear_to_screen_end() for 0 .. 2;
