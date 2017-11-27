#! perl

use strict;
use warnings;

use Test::More tests => 4 * 12 + 1 + 3 * 13 * 2;

BEGIN { use_ok qw(App::Music::PlayTab::Note) }

use App::Music::PlayTab::NoteMap qw(@FNotes @SNotes);
use App::Music::PlayTab::Output::PostScript;

# Foreach note, check the name and ps function.
foreach my $k ( @FNotes ) {
    my $n = App::Music::PlayTab::Note::->parse($k);
    my $res = $n->name;
    is($k, $res, "name: $k");
    $res =~ s/^(.)b$/\($1\) root flat/;
    $res =~ s/^(.)#$/\($1\) root sharp/;
    $res =~ s/^(.)$/\($1\) root/;
    is($n->ps, $res, "ps: $k");
}

# Foreach note, check the transpose +/- function.
foreach my $i ( 0 .. 11 ) {
    my $note = $FNotes[$i];
    my $j = App::Music::PlayTab::Note::->parse($note);

    my $n = App::Music::PlayTab::Note::->parse($note);
    my $m = App::Music::PlayTab::Note::->parse($SNotes[($i+1) % 12]);
    $n->transpose(1);
    is($n->name, $m->name, "xp +1: $note");

    $n = App::Music::PlayTab::Note::->parse($note);
    $n->transpose(-1);
    $m = App::Music::PlayTab::Note::->parse($FNotes[($i-1) % 12]);
    is($n->name, $m->name, "xp -1: $note");
}

# For the first, last and some other note, check the transpose +/-
# function extensively.
foreach my $i ( 0, 11, 5 ) {
    my $note = $FNotes[$i];
    my $j = App::Music::PlayTab::Note::->parse($note);

    foreach my $xp ( 0 .. 12 ) {
	my $n = App::Music::PlayTab::Note::->parse($note);
	my $m = App::Music::PlayTab::Note::->parse($SNotes[($i+$xp) % 12]);
	$n->transpose($xp);
	is($n->name, $m->name, "xp +$xp: $note");

	$n = App::Music::PlayTab::Note::->parse($note);
	$n->transpose(-$xp);
	$m = App::Music::PlayTab::Note::->parse($FNotes[($i-$xp) % 12]);
	is($n->name, $m->name, "xp -$xp: $note");
    }
}
