#! perl

use strict;
use warnings;

# Collect the test cases from the data file.
my @tests;
BEGIN {
    my $td;
    open($td, "<", "04lychord.ptb")
      or open($td, "<", "t/04lychord.ptb")
	or die("04lychord.ptb: $!\n");
    while ( <$td> ) {
	next unless /\S/;
	next if /^#/;
	chomp;
	push(@tests, $_);
    }
    close($td);
}

use Test::More tests => 3 + 3 * @tests;
BEGIN {
    use_ok qw(App::Music::PlayTab::LyChord);
    use_ok qw(App::Music::PlayTab::Output::PostScript);
}

my $parser = App::Music::PlayTab::LyChord->new;
ok($parser, "parser object");

# Run the tests.
# Input is
# chord <TAB> name <TAB> ps

# Note: duration is sticky.
my $dur;
foreach ( @tests ) {
    my ($chord, $name, $d, $ps) = split(/\t/, $_);
    $name ||= $chord;
    $dur = $d if $d;
    my $c = $parser->parse($chord);
    my $res = $c->name;
    is($res, $name, "$chord: name");
    is($c->duration, $dur, "$chord: duration");
    ok(1, "$chord: no ps"), next unless $ps;
    $res = $c->ps;
    is($res, $ps, "$chord: ps");
}
