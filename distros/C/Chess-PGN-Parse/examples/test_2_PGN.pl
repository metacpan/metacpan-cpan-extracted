#!/usr/bin/perl -w
use strict;
use Chess::PGN::Parse;
use Data::Dumper;

my $filename = shift || die "filename required\n";

my $pgn = new Chess::PGN::Parse $filename 
	or die "can't open $filename \n";

my @games = $pgn->read_all({
	save_comments => 'yes', 
	log_errors => 'yes'
	});
print Data::Dumper->Dump([\@games], ["games"]),"\n";
