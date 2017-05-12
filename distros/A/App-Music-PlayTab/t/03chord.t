#! perl

use strict;
use warnings;

# Collect the test cases from the data file.
my @tests;
BEGIN {
    my $td;
    open($td, "<", "03chord.ptb")
      or open($td, "<", "t/03chord.ptb")
	or die("03chord.ptb: $!\n");
    while ( <$td> ) {
	next unless /\S/;
	next if /^#/;
	chomp;
	push(@tests, $_);
    }
    close($td);
}

use Test::More tests => 2 + 2 * @tests;
BEGIN {
    use_ok qw(App::Music::PlayTab::Chord);
}

my $parser = App::Music::PlayTab::Chord->new;
ok($parser, "parser object");

# Run the tests.
# Input is
# chord <TAB> name <TAB> ps

foreach ( @tests ) {
    my ($chord, $name, $ps) = split(/\t/, $_);
    $name ||= $chord;
    my $c = $parser->parse($chord);
    my $res = $c->name;
    is($res, $name, "$chord: name");
    ok(1, "$chord: no ps"), next unless $ps;
    $res = $c->ps;
    is($res, $ps, "$chord: ps");
}
