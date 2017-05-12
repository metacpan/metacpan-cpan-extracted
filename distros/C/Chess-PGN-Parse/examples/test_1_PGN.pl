#!/usr/bin/perl -w
use strict;
use Chess::PGN::Parse;

my $filename = shift || die "filename required\n";

my $pgn = new Chess::PGN::Parse $filename 
	or die "can't open $filename \n";

while ($pgn->read_game()) {
	print $pgn->event, " /  ", $pgn->white, " - ", $pgn->black, 
		" : ", $pgn->result, "\n";
	if ($pgn->parse_game() ) { #&& $pgn->moves) {
		print join(" ", @{$pgn->moves}), "\n"; 
	}
	print "-" x 60, "\n\n";
}
