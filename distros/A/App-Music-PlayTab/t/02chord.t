#! perl

use strict;
use warnings;

use Test::More tests => 3 + 4 * 12 + 3 * 13 * 2;

BEGIN {
    use_ok qw(App::Music::PlayTab::NoteMap);
    use_ok qw(App::Music::PlayTab::Note);
    use_ok qw(App::Music::PlayTab::Chord);
}

use App::Music::PlayTab::NoteMap qw(@FNotes @SNotes);

# Foreach chord, check the name and ps function.
foreach my $k ( @FNotes ) {
    my $n = App::Music::PlayTab::Chord::->new->parse($k);
    my $res = $n->name;
    is($k, $res, "name: $k");
    $res =~ s/^(.)b$/\($1\) root flat/;
    $res =~ s/^(.)#$/\($1\) root sharp/;
    $res =~ s/^(.)$/\($1\) root/;
    is($n->ps, $res, "ps: $k");
}

# Foreach chord, check the transpose +/- function.
foreach my $i ( 0 .. 11 ) {
    my $chord = $FNotes[$i];
    my $j = App::Music::PlayTab::Chord::->new->parse($chord);

    my $n = App::Music::PlayTab::Chord::->new->parse($chord);
    my $m = App::Music::PlayTab::Chord::->new->parse($SNotes[($i+1) % 12]);
    $n->transpose(1);
    is($n->name, $m->name, "xp +1: $chord");

    $n = App::Music::PlayTab::Chord::->new->parse($chord);
    $n->transpose(-1);
    $m = App::Music::PlayTab::Chord::->new->parse($FNotes[($i-1) % 12]);
    is($n->name, $m->name, "xp -1: $chord");
}

# For the first, last and some other note, check the transpose +/-
# function extensively.
foreach my $i ( 0, 11, 5 ) {
    my $chord = $FNotes[$i];
    my $j = App::Music::PlayTab::Chord::->new->parse($chord);

    foreach my $xp ( 0 .. 12 ) {
	my $n = App::Music::PlayTab::Chord::->new->parse($chord);
	my $m = App::Music::PlayTab::Chord::->new->parse($SNotes[($i+$xp) % 12]);
	$n->transpose($xp);
	is($n->name, $m->name, "xp +$xp: $chord");

	$n = App::Music::PlayTab::Chord::->new->parse($chord);
	$n->transpose(-$xp);
	$m = App::Music::PlayTab::Chord::->new->parse($FNotes[($i-$xp) % 12]);
	is($n->name, $m->name, "xp -$xp: $chord");
    }
}
