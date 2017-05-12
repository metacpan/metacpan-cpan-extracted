#!/usr/bin/perl -w
use strict;
use Chess::PGN::Parse;

my $out ='';

{
    local $/ =undef;
    $out = <DATA>;
}

my $pgn = new Chess::PGN::Parse(undef, $out) or die "can't \n";

use Data::Dumper;

while ($pgn->read_game()) {
    if ($pgn->parse_game(
        {   
            save_comments => 1 , 
            comments_struct => 'hol' , 
            log_errors => 1
            })) 
        {
        print $pgn->standard_PGN({all_tags=>1}),"\n";
        if ($pgn->{GameComments}) {
            
        print Data::Dumper->Dump([$pgn->{GameComments}],['comments']),"\n";
            # create a nested PGN objects to read variations
            for (keys %{$pgn->{GameComments}}) {
                next unless exists $pgn->{GameComments}{$_}->{RAV};
                for my $variation (@{$pgn->{GameComments}{$_}->{RAV}}) {
                    my $move = $_ || q{};
                    $variation =~ s/^\(//;
                    $variation =~ s/\)$//;
                    $variation = 
                    qq([Variation "$move"]\n[Result "*"]\n) 
                        . $variation; 
                    my $newpgn = new Chess::PGN::Parse( undef, 
                        $variation) or die "can't $_\n";
                    die "can't read\n" unless $newpgn->read_game();
                    die "can't parse\n" unless $newpgn->parse_game();
                    print "\n<NESTED> $move @{[$newpgn->standard_PGN({all_tags=>1})]}";
                    print "moves(@{$newpgn->moves})</NESTED>\n"
                }
            }
        }
        #print Data::Dumper->Dump([$pgn->{GameErrors}],['err']),"\n";
    }
}


__DATA__

[Event "Botvinnik Memorial"]
[Site "Moscow"]
[Date "2001.12.05"]
[Round "4"]
[White "Kasparov, Garry"]
[Black "Kramnik, Vladimir"]
[Result "1/2-1/2"]
[ECO "C80"]
[WhiteElo "2839"]
[BlackElo "2808"]
[PlyCount "37"]
[EventDate "2001.12.01"]

1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 $1 {first comment} 4. Ba4 Nf6 5. O-O 
Nxe4 {second comment} 6. d4 ; comment starting with ";" up to EOL 
b5 7. Bb3 d5 8. dxe5 Be6 9. Be3 {third comment} 9... Bc5 10. Qd3 O-O 
11. Nc3 Nb4 (11... Be3 12. Qe3 Nc3) (11... Bxe3 12. Qxe3 Nxc3 13. 
Qxc3 Qd7 14. Rad1 Nd8 $1 15. Nd4 c6 $14 (15... Nb7 16. Qc6 $1 $16)) 
12. Qe2 Nxc3 13. bxc3 Bxe3 
% escaped line - it will be discarded up to the EOL
14. Qxe3 Nc6 {wrong } comment} 15. a4 Na5 oh? 16. axb5 {yet another 
comment} (16. Nd4 {nested comment}) 16... axb5 17. Nd4 (17. Qc5 c6 18. 
Nd4 Ra6 19. f4 g6 20. Ra3 Qd7 21. Rfa1 Rfa8) 17... Qe8 18. f4 c5 19. 
Nxe6 the end 1/2-1/2
