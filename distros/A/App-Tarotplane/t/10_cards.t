#!/usr/bin/perl
use 5.016;
use strict;
use warnings;

use Test::More;

use File::Spec;

use App::Tarotplane::Cards;

plan tests => 53;

my $Sort_Test = File::Spec->catfile(qw(t data sort.cards));
my $Sort_Num = 5;
my @Sort = (
	{
		Term => 'stu',
		Def  => 'def',
	},
	{
		Term => 'abc',
		Def  => 'z',
	},
	{
		Term => 'y',
		Def  => 'vwx',
	},
	{
		Term => 'ghi',
		Def  => 'pqr',
	},
	{
		Term => 'mno',
		Def  => 'jkl',
	},
);

my $Whitespace_Test = File::Spec->catfile(qw(t data whitespace.cards));
my $Whitespace_Num = 4;
my @Whitespace = (
	{
		Term => '1',
		Def  => '2',
	},
	{
		Term => '3',
		Def  => '4',
	},
	{
		Term => '5',
		Def  => '6',
	},
	{
		Term => '7',
		Def  => '8',
	},
);

my $Escape_Test = File::Spec->catfile(qw(t data escape.cards));
my $Escape_Num = 4;
my @Escape = (
	{
		Term => ":)",
		Def  => "Happy :D",
	},
	{
		Term => ":-\\",
		Def  => "Concerned\\Confused",
	},
	{
		Term => "Line\nbreak",
		Def  => "Broken\nline",
	},
	{
		Term => "\\\n\\\\::",
		Def  => "All together!",
	},
);

# Will test general card reading and sorting.
my $d1 = App::Tarotplane::Cards->new($Sort_Test);
isa_ok($d1, 'App::Tarotplane::Cards', "new() return App::Tarotplane::Card object");

is($d1->get('CardNum'), $Sort_Num, "Correct number of cards read");

foreach my $i (0 .. $Sort_Num - 1) {
	is($d1->card_side($i, 'Term'), $Sort[$i]->{Term},
		"Card #$i term is okay");
	is($d1->card_side($i, 'Definition'), $Sort[$i]->{Def},
		"Card #$i definition is okay");
}

@Sort = sort { $a->{Term} cmp $b->{Term} } @Sort;
$d1->order_deck();

foreach my $i (0 .. $Sort_Num - 1) {
	is($d1->card_side($i, 'Term'), $Sort[$i]->{Term},
		"Term-sorted card #$i term is okay");
	is($d1->card_side($i, 'Definition'), $Sort[$i]->{Def},
		"Term-sorted card #$i definition is okay");
}

@Sort = sort { $a->{Def} cmp $b->{Def} } @Sort;
$d1->order_deck('Definition');

foreach my $i (0 .. $Sort_Num - 1) {
	is($d1->card_side($i, 'Term'), $Sort[$i]->{Term},
		"Definition-sorted card #$i term is okay");
	is($d1->card_side($i, 'Definition'), $Sort[$i]->{Def},
		"Definition-sorted card #$i definition is okay");
}

# Test reading cards with different kinds of whitespace
my $d2 = App::Tarotplane::Cards->new($Whitespace_Test);

is($d2->get('CardNum'), $Whitespace_Num, "Correct number of cards read");

foreach my $i (0 .. $Whitespace_Num) {
	is($d2->card_side($i, 'Term'), $Whitespace[$i]->{Term},
		"Card #$i term is okay (w/ weird whitespace)");
	is($d2->card_side($i, 'Definition'), $Whitespace[$i]->{Def},
		"Card #$i definition is okay (w/ weird whitespace)");
}

# Test reading escape sequences
my $d3 = App::Tarotplane::Cards->new($Escape_Test);

is($d3->get('CardNum'), $Escape_Num, "Correct number of cards read");

foreach my $i (0 .. $Escape_Num - 1) {
	is($d3->card_side($i, 'Term'), $Escape[$i]->{Term},
		"Card #$i term is okay (w/ escape sequences)");
	is($d3->card_side($i, 'Definition'), $Escape[$i]->{Def},
		"Card #$i definition is okay (w/ escape sequences)");
}

# $d4 will test reading multiple files at once
my $d4 = App::Tarotplane::Cards->new(
	$Sort_Test, $Whitespace_Test, $Escape_Test
);

is($d4->get('CardNum'), $Sort_Num + $Whitespace_Num + $Escape_Num,
	"new() correctly read multiple files at once");
