package Acme::Mahjong::Rule::CC;

use 5.008008;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Acme::Mahjong::Rule::CC ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 
'all' => [ qw(
	mahjong_table
	dealer
	nondealer
	draw
) ],
'tables' =>[qw(
	dealer
	nondealer
	draw
)] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.22';


sub mahjong_table{
   my $ans = 7;
   while($ans!=0 && $ans!=1 && $ans!=2){
      print("0.Nondealer , 1.Dealer, or 2.Draw : ");
      $ans=<STDIN>;
      }
   my @subs = (\&nondealer, \&dealer, \&draw);
   my @players = (qw/dealer player2 player3 player4/);
   $players[0]='winner' if ($ans != 2);
   $players[1]='dealer' if ($ans == 0);
   my @points;
   foreach $a(@players){
      print("$a : ");
      my $pts =<STDIN>;
      push @points,$pts;
   }
   print "===========================\n";
   foreach (&{$subs[$ans]}(@points)){
      my $p = shift @players;
      print "$p : $_\n";
   }
}
sub nondealer{
   croak "Wrong number of arguments, needs 4.\n" unless (@_==4);
   my @score;
   my($w, $deal, $l2 , $l3)=@_;
   $score[0]=$w*4;
   $score[1]=4*$deal-(2*$w+2*$l2+2*$l3);
   $score[2]=3*$l2-($w+2*$deal+$l3);
   $score[3]=3*$l3-($w+2*$deal+$l2);
   @score;
}
sub dealer{
   croak "Wrong number of arguments, needs 4.\n" unless (@_==4);
   my @score;
   my($w, $l2 ,$l3 ,$l4)=@_;
   $score[0]=$w*6;
   $score[1]=2*$l2-($w*2+$l3+$l4);
   $score[2]=2*$l3-($w*2+$l2+$l4);
   $score[3]=2*$l4-($w*2+$l3+$l2);
   @score;
}
sub draw{
   croak "Wrong number of arguments, needs 4.\n" unless (@_==4);
   my @score;
   my($l1, $l2 ,$l3 ,$l4)=@_;
   $score[0]=$l1*6-2*($l2+$l3+$l4);
   $score[1]=$l2*4-($l1*2+$l3+$l4);
   $score[2]=$l3*4-($l1*2+$l2+$l4);
   $score[3]=$l4*4-($l1*2+$l3+$l2);
   @score;
}

1;
__END__


=head1 NAME

Acme::Mahjong::Rule::CC - Exchange Tables for a Classic Chinese Version of Mahjong.

=head1 SYNOPSIS

this returns the exchanges of the given scores
when the winner is a non-dealer. 
The equivalent chart form of this exchange would be:

      |win 200  | deal 100 | pl3 50 | pl4 20 |
=============================================|
 win  |    X    |   -400   | -200   | -200   |
 deal |   400   |     X    | -100   | -160   |
 pl3  |   200   |    100   |   X    | -30    |
 pl4  |   200   |    160   |  30    |  X     |
=============================================|
 total|   800   |   -140   | -270   | -390   |

Now since the methods require that the winner comes
first(if there is one), and then the dealer you need to
rearrage the players in a way such as the following
example from mj_series:

=cut

my $type;
if ($winner eq $dealer){
   @players = sort {$b eq $winner}  @players;
   $type = 0;
} elsif ($winner ne ""){
   @players = sort {$b eq $dealer} @players;
   @players = sort {$b eq $winner} @players;
   $type = 1;
} else {
   @players = sort {$b eq $dealer} @players;
   $type = 2;
}

=head2 Note:

You can find the rest of the source code for mj_series with your distrobution.  
#!There must be exactly four arguments in dealer(), nondealer(),
and draw() otherwise, the function will throw an exception.

=head1 DESCRIPTION

This module provides functions that table the exchanges of a round of mahjong
based off of the given scores.  This module mainly applies to the Classic 
Chinese version of the game, where every hand is scored, not just the winners.
Players pay each other the value of the other's hand, dealer pays and recieves
double, and winner pays no one.

=over

=item mahjong_table()

mahjong_table() provides an example of how to use the 
other functions or gives you a very basic 1-hand mahjong
score calculator. It is not included with :tables, you must
use :all to be able to use it.

=item nondealer()

As with all game types, the dealer pays and recieves double, the winner
pays no one, but collects from everyone(double from the dealer), 
and the other players collect normally, while still paying/recieving 
double from the dealer and paying, but not collecting from the winner.

=cut

nondealer($winner_pts, $dealer_pts, $player3_pts, $player4_pts);
#nondealer(200,100,50,20) returns (800,-140,-270,-390)

=item dealer()

The dealer() function returns the exchanges of the given 
scores when the dealer is the winner. meaning that the 
winnner both collects double and pays no one.

=cut

dealer(winner, player2, player3, player4);
#dealer(200,100,50,20) returns (1200,-200,-500,-500)

=item draw()

returns the exchanges of the given scores when there
is no winner in the form of an array.

=cut        

draw(dealer, player2, player3, player4);
#draw(200,100,0,0) returns (1000,-200,-400,-400)

=back

=head2 EXPORT

None by default.



=head1 SEE ALSO

Acme::Mahjong::Rule::JP

=head1 AUTHOR

root, E<lt>cjveenst@mtu.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by TROTSKEY

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
