package Chess::Mbox;

use Chess::PGN::Parse;
use Mail::MboxParser;


require 5.005_62;
use strict;
use warnings;

our $VERSION = sprintf '%s', 'q$Revision: 1.3 $' =~ /\S+\s+(\S+)\s+/ ;


# Preloaded methods go here.

sub Parse {
    my $class = shift;
    my %C = @_;

    my $mailbox     = $C{mbox};
    my $game_dir    = $C{output_dir};
    my $postop      = $C{post_op};
    warn "POSTOP: $postop";
    my $temp_file   = "/tmp/chessfile$$";

    my $mb = Mail::MboxParser->new($mailbox, decode => 'NEVER');

while (my $msg = $mb->next_message) {
    print $msg->header->{subject}, "\n";

    my $pgnfile = $temp_file;
    open  T, ">$pgnfile" or die "couldnt open $pgnfile: $!";
    my $GAME = $msg->body($msg->find_body)->as_string;
    print T $GAME;
    close(T);

    my $pgn = Chess::PGN::Parse->new($pgnfile) or die "can't open $pgnfile\n";

    while ($pgn->read_game) {
	mkdir sprintf "%s/%s", $game_dir, $pgn->white;
	my $dir = sprintf "%s/%s/%s", $game_dir, $pgn->white, $pgn->black;
	mkdir $dir;
	my $file = sprintf "%s-%s", $pgn->date, $pgn->time;
	$file =~ s/:/-/g;
	my $F = "$dir/$file.pgn";
	print $F, $/;
	open F, ">$F" or die "couldnt open $F: $!";
	print F $GAME;
	close(F);
	if ($postop) {
	  chdir $dir;
	  &$postop;
	}
    }

}




}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Chess::Mbox - write mbox files with chess games into them onto disk

=head1 SYNOPSIS

 use Chess::Mbox;

 sub post_op {
    my @can = <*.can.pgn>;
    my @pgn = grep { $_ !~ /can.pgn/ } <*.pgn>;
    my $pgn = shift @pgn;
    warn "PGN: $pgn CAN: @can";
   system "/Users/metaperl/bin/annotate.pl $pgn" unless @can;
 }

 $M = '/Users/metaperl/Library/Mail/Mailboxes/Chess/Games.mbox/mbox';
 $O = '/Users/metaperl/Documents/Chess/games/tmp';
 Chess::Mbox->Parse (mbox => $M, output_dir => $O, post_op => \&post_op);


=head1 DESCRIPTION

This was a script lying on my disk that I thought would be useful to others. It simply
takes a Unix mbox file and assumes each message is a chess game and writes to a directory
with first directory == white and directory below that == black and the file name == date + time
of match... after all you will have many rematches with a certain person. :)

It also will run a C<post_op> subroutine to do something with each 

=head2 EXPORT

None by default.


=head1 AUTHOR

T. M. Brannon <tbone@cpan.org>


=cut
