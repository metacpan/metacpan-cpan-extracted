use strict;
use warnings;

package App::Games::Keno;
use List::Compare;

# ABSTRACT: Plays Keno

=head1 NAME 
 
App::Games::Keno
 
=head1 SYNOPSIS

This package plays a game of Keno.

Call "Playkeno" like this to play 1000 draws with five spots.
 
 App::Games::Keno::PlayKeno(5, 1000);
 
Example results:

 You are playing 1,000 draws with 5 spots: 22  35  37  72  76
 
 You played 1,000 draws with 5 spots: 22  35  37  72  76
 You won 112 of 1,000 draws.  (1 in 8.93)
 0:213  1:410  2:265  3:94  4:18  5:0  
 Total winnings: $512  Net Gain: -488  Loss ratio: 1.95

If you wish to see the results of each draw, turn on the verbose option:

 App::Games::Keno::PlayKeno(5, 10, 'true');

Sample abbreviated results with verbose option:

 You are playing 10 draws with 5 spots: 7  14  18  27  71
 
 Starting draw 1...
 Drawn Numbers:   1  12  16  22  23  25  27  30  31  32  33  34  38  40  47  52  57  60  64  69
 Matched Numbers: 27
 Draw 1 matches 1 of 5 spots, but there is no payout for that.  You LOSE!
 Gain:       -1  Total Winnings:     0
 
 Starting draw 2...
 Drawn Numbers:   3  10  15  22  23  27  32  33  36  38  40  41  42  48  53  56  59  66  75  77
 Matched Numbers: 27
 Draw 2 matches 1 of 5 spots, but there is no payout for that.  You LOSE!
 Gain:       -2  Total Winnings:     0
 
  (draws 3-9 not shown in this example)
 
 Starting draw 10...
 Drawn Numbers:   5  7  11  13  14  16  21  25  26  29  33  46  48  52  55  61  66  69  71  76
 Matched Numbers: 7  14  71
 Draw 10 matches 3 of 5 spots.  You win $2
 Gain:       -6  Total Winnings:     4
  
 
 You played 10 draws with 5 spots: 7  14  18  27  71
 You won 2 of 10 draws.  (1 in 5.00)
 0:2  1:2  2:4  3:2  4:0  5:0  
 Total winnings: $4  Net Gain: -6  Loss ratio: 2.50

=cut

sub PlayKeno {
	our ( $spotsCount, $drawsCount, $verbose ) = @_;
	our @spots       = getRandomSet($spotsCount);
	our $winnings    = 0;
	our $netGain     = 0;
	our $numWonDraws = 0;
	our %prizes;
	our %matchCount;

	buildPayoutTable();
	print "You are playing "
	  . commify($drawsCount)
	  . " draws with $spotsCount spots: "
	  . join( '  ', sort { $a <=> $b } @spots ) . "\n\n";
	for ( 1 .. $drawsCount ) {
		$winnings += playOneDraw($_);
		$netGain = $winnings - $_;
		print "Gain: "
		  . sprintf( '%8s', $netGain )
		  . "  Total Winnings:"
		  . sprintf( '%6s', $winnings ) . "\n"
		  if $verbose;
		print "\n" if $verbose;
	}

	my $ratio = "NAN";
	$ratio = sprintf( '%.2f', 1 / ( $numWonDraws / $drawsCount ) )
	  unless $numWonDraws == 0;
	my $lossRatio = "NAN";
	$lossRatio = sprintf( '%.2f', ( $drawsCount / $winnings ) )
	  unless $winnings == 0;
	print "\nYou played "
	  . commify($drawsCount)
	  . " draws with $spotsCount spots: "
	  . join( '  ', sort { $a <=> $b } @spots );
	print "\nYou won "
	  . commify($numWonDraws) . " of "
	  . commify($drawsCount)
	  . " draws.  (1 in $ratio)\n";
	for ( my $i = 0 ; $i <= $spotsCount ; $i++ ) {
		print "$i:";
		if ( exists( $matchCount{$i} ) ) {
			print $matchCount{$i};
		}
		else {
			print "0";
		}
		print "  ";
	}
	print "\nTotal winnings: \$"
	  . commify($winnings)
	  . "  Net Gain: "
	  . commify($netGain)
	  . "  Loss ratio: $lossRatio\n";

	sub playOneDraw {
		my $drawNumber   = shift;
		my @drawnNumbers = getRandomSet(20);

		my $lc             = List::Compare->new( \@spots, \@drawnNumbers );
		my @matchedNumbers = $lc->get_intersection;
		my $matches        = scalar @matchedNumbers;
		my $payout         = getPayout( $matches, $spotsCount );
		$matchCount{$matches}++;

		print "Starting draw $drawNumber...\n" if $verbose;
		print "Drawn Numbers:   "
		  . join( '  ', sort { $a <=> $b } @drawnNumbers ) . "\n"
		  if $verbose;
		print "Matched Numbers: "
		  . join( '  ', sort { $a <=> $b } @matchedNumbers ) . "\n"
		  if $verbose;
		if ( $matches > 0 || $payout > 0 ) {
			print "Draw $drawNumber matches $matches of $spotsCount spots"
			  if $verbose;
			print
"You matched all $matches spots on draw $drawNumber!  You win \$$payout!\n"
			  if ( $matches == $spotsCount && $matches > 7 );
			if ( $payout > 0 ) {
				print ".  You win \$$payout\n" if $verbose;
				$numWonDraws++;
			}
			else {
				print ", but there is no payout for that.  You LOSE!\n"
				  if $verbose;
			}
		}
		else {
			print
			  "Draw $drawNumber matches no spots.  You LOSE!  GOOD DAY SIR!\n"
			  if $verbose;
		}

		#	#print "\n";
		return $payout;
	}

	sub getRandomSet {
		my $count = shift;
		my @random_set;
		my %seen;

		for ( 1 .. $count ) {
			my $candidate = 1 + int rand(80);
			redo if $seen{$candidate}++;
			push @random_set, $candidate;
		}

		return @random_set;
	}

	sub getPayout {
		my ( $match, $spot ) = @_;

		if ( exists( $prizes{$spot}{$match} ) ) {
			return $prizes{$spot}{$match};
		}
		else {
			return 0;
		}
	}

	sub buildPayoutTable {
		$prizes{10}{10} = 100000;
		$prizes{10}{9}  = 4250;
		$prizes{10}{8}  = 450;
		$prizes{10}{7}  = 40;
		$prizes{10}{6}  = 15;
		$prizes{10}{5}  = 2;
		$prizes{10}{0}  = 5;
		$prizes{9}{9}   = 30000;
		$prizes{9}{8}   = 3000;
		$prizes{9}{7}   = 150;
		$prizes{9}{6}   = 25;
		$prizes{9}{5}   = 6;
		$prizes{9}{4}   = 1;
		$prizes{8}{8}   = 10000;
		$prizes{8}{7}   = 750;
		$prizes{8}{6}   = 50;
		$prizes{8}{5}   = 12;
		$prizes{8}{4}   = 2;
		$prizes{7}{7}   = 4500;
		$prizes{7}{6}   = 100;
		$prizes{7}{5}   = 17;
		$prizes{7}{4}   = 3;
		$prizes{7}{3}   = 1;
		$prizes{6}{6}   = 1100;
		$prizes{6}{5}   = 50;
		$prizes{6}{4}   = 8;
		$prizes{6}{3}   = 1;
		$prizes{5}{5}   = 420;
		$prizes{5}{4}   = 18;
		$prizes{5}{3}   = 2;
		$prizes{4}{4}   = 75;
		$prizes{4}{3}   = 5;
		$prizes{4}{2}   = 1;
		$prizes{3}{3}   = 27;
		$prizes{3}{2}   = 2;
		$prizes{2}{2}   = 11;
		$prizes{1}{1}   = 2;
	}

	# from Andrew Johnson <ajohnson@gpu.srv.ualberta.ca>
	sub commify {
		my $input = shift;
		$input = reverse $input;
		$input =~ s<(\d\d\d)(?=\d)(?!\d*\.)><$1,>g;
		return reverse $input;
	}

}

##

1;

