#!/Users/metaperl/install/bin/perl


use Chess::Mbox;

sub post_op {
    my @can = <*.can.pgn*>;
    my @pgn = grep { $_ !~ /can.pgn/ } <*.pgn>;
    my $pgn = shift @pgn;
    warn "PGN: $pgn CAN: @can";
    use Cwd;
    if (@can) {
	warn "skipping ", getcwd, "because a .can.pgn file is here";
    } else {
	system "/Users/metaperl/bin/annotate.pl $pgn" ;
    }
}

$M = '/Users/metaperl/Library/Mail/Mailboxes/Chess/Games.mbox/mbox';
$O = '/Users/metaperl/Documents/Chess/games/tmp';
Chess::Mbox->Parse (mbox => $M, output_dir => $O, post_op => \&post_op);
