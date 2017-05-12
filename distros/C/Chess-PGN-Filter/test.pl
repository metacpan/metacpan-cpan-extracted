# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 14 };
use Chess::PGN::Filter;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my %substitutions = (
    hsmyers => 'Myers, Hugh S (ID)'
);
my @exclude = qw(
    WhiteElo
    BlackElo
    EventDate
);
my $gametext;
my @output;

{
    local $/ = undef;
    $gametext = <DATA>;
}
open(FILE,">test.pgn") or die "Couldn't open file:test.pgn: $!\n";
print FILE $gametext or die "Couldn't write file:test.pgn: $!\n";
close(FILE) or die "Couldn't close file:test.pgn: $!\n";

open(FILE,">test.out") or die "Couldn't open file:test.out: $!\n";
my $stdout = select FILE;
filter(
    source => 'test.pgn',
    filtertype => 'TEXT',
    substitutions => \%substitutions,
    nags => 'yes',
    NIC => 'yes',
    exclude => \@exclude,
);
close(FILE);

select $stdout;
open(FILE,'<test.out') or die "Couldn't open file:test.out $!\n";
while(<FILE>) {
    push(@output,$_);
}
close(FILE);
ok($output[4],"[White \"Myers, Hugh S (ID)\"]\n");
ok($output[7],"[ECO \"C00\"]\n");
ok($output[8],"[NIC \"FR 1\"]\n");
ok($output[9],"[Opening \"French: Labourdonnais variation\"]\n");

open(FILE,">test.out") or die "Couldn't open file:test.out: $!\n";
my $stdout = select FILE;
filter(
    source => 'test.pgn',
    filtertype => 'XML',
);
close(FILE);

select $stdout;
open(FILE,'<test.out') or die "Couldn't open file:test.out $!\n";
@output = ();
while(<FILE>) {
    push(@output,$_);
}
close(FILE);
ok($output[30],"\t\t\t\t<GAMETERMINATION GAMERESULT=\"UNKNOWN\"/>\n");
ok($output[32],"\t\t\t<COMMENT>this is a comment</COMMENT>\n");
ok($output[127],"\t\t\t<MOVE>Bb5</MOVE>\n");
ok($output[130],"\t\t<POSITION FONT=\"Chess Kingdom\" SIZE=\"3\">\n");

open(FILE,">test.out") or die "Couldn't open file:test.out: $!\n";
my $stdout = select FILE;
filter(
    source => 'test.pgn',
    filtertype => 'DOM',
);
close(FILE);

select $stdout;
open(FILE,'<test.out') or die "Couldn't open file:test.out $!\n";
@output = ();
while(<FILE>) {
    push(@output,$_);
}
close(FILE);
ok($output[10],"                      'Result' => '0-1'\n");
ok($output[30],"                            'Epd' => 'rnbqkbnr/ppp2ppp/4p3/3p4/4PP2/8/PPPP2PP/RNBQKBNR w KQkq d6',\n");
ok($output[39],"                            'Rav' => [\n");
ok($output[280],"                            'Movetext' => 'Bb5'\n");

open(FILE,">test.out") or die "Couldn't open file:test.out: $!\n";
my $stdout = select FILE;
my $data = filter (
    source => 'test.pgn',
    filtertype => 'DOM',
    verbose => 0,
);
close(FILE);
ok(ref($data), 'ARRAY');

unlink('test.pgn') or die "Unable to unlink file:test.pgn $!\n";
unlink('test.out') or die "Unable to unlink file:test.out $!\n";

__DATA__
[Event "Boise Chess Club Championship Reserve Section"]
[Site "Boise (ID)"]
[Date "1995.02.28"]
[Round "01"]
[White "hsmyers"]
[Black "Roland Jeffrey T (ID)"]
[Result "0-1"]
[ECO "?"]
[Opening "?"]

1.e4 e6 2.f4 d5$0 3.e5{this is a comment}$3(3.c3) c5 4.Nf3 Nc6 5.d3 Be7 6.Be2 Nh6 7.c3 0-0 8.0-0 f6 9.exf6 Bxf6 10.d4 cxd4 11.cxd4 Qb6 12.Nc3 Bxd4+ 13.Kh1 Bxc3 14.bxc3 Ng4 15.Nd4 Nxd4 16.cxd4 Nf6 17.Ba3 Rf7 18.Rb1 Qd8 19.Bd3 Bd7 20.Qf3 Bc6 21.f5 Ne4 22.Bxe4 dxe4 23.Qd1 exf5 24.Rb2 Qd5 25.Rbf2 e3 26.Re2 Bb5 0-1
