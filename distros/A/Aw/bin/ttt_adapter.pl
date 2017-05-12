#!/usr/bin/perl -w

$| =1;

package TicTacToeAdapter;
use base qw(Aw::Adapter);

use Aw;
use Aw::Event;

my $move;
my ($false, $true)  = (0,1);
my $tttEvent        = "PerlDevKit::TicTacToe";
my $tttEventRequest = "PerlDevKit::TicTacToeRequest";

# This adapter was originally created to play against
# an Apache server child.
#
# this is a hack to allow the adapter to play against
# the "tictactoe" client script in addition to Apache.
# The "tictactoe" scripts were originally intended to
# play against one another.  They maintain their own
# boards and just send one another their latest move.
#
# This hack is easier than updating the clients to
# transmit their entire game board.  Which is required
# with apache since the apache child process can not
# guarantee persistance.
#
# We assume that the adapter interacts with only one
# client script at a time, so we just maintain a single
# board.
#
@staticBoard = ();


##
#  White's current position. The computer is white.
#
my $white = 0;


##
#  Black's current position. The user is black.
#
my $black = 0;


##
#  The squares in order of importance...
#
my @moves = (4, 0, 2, 6, 8, 1, 3, 5, 7);


##
#  The winning positions.
#
my @won = ();
$#won = (1 << 9);

my $DONE      = (1 << 9) - 1;
my $OK        = 0;
my $WIN       = 1;
my $LOSE      = 2;
my $STALEMATE = 3;


sub resetStaticBoard
{
	@staticBoard = ( 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e' );
}


##
#  Mark all positions with these bits set as winning.
#
sub isWon
{
my $pos = shift;

	for ( my $i = 0; $i < $DONE; $i++ ) {
		if ( ($i & $pos) == $pos ) {
			$won[$i] = $true;
		}
	}
}


##
#  Initialize all winning positions.
#
sub init
{

	isWon ( (1 << 0) | (1 << 1) | (1 << 2) );
	isWon ( (1 << 3) | (1 << 4) | (1 << 5) );
	isWon ( (1 << 6) | (1 << 7) | (1 << 8) );
	isWon ( (1 << 0) | (1 << 3) | (1 << 6) );
	isWon ( (1 << 1) | (1 << 4) | (1 << 7) );
	isWon ( (1 << 2) | (1 << 5) | (1 << 8) );
	isWon ( (1 << 0) | (1 << 4) | (1 << 8) );
	isWon ( (1 << 2) | (1 << 4) | (1 << 6) );
}


##
#  Compute the best move for white.
#  @return the square to take

sub bestMove
{
my $bestmove = -1;


	for ( my $i = 0; $i < 9; $i++ ) {
		my $mw = $moves[$i];
		if ( (($white & (1 << $mw)) == 0) && (($black & (1 << $mw)) == 0) ) {
			my $pw = $white | (1 << $mw);

			#	
			#  white wins, take it!
			return $mw if ( $won[$pw] );

			for ( my $mb = 0; $mb < 9; $mb++ ) {
				if ( (($pw & (1 << $mb)) == 0) && (($black & (1 << $mb)) == 0) ) {
					my $pb = $black | (1 << $mb);
					#	
					#  black wins, take another
					goto outerLoop if ( $won[$pb] );
				}
			}

			#  Neither white nor black can win in one move, this will do.
			$bestmove = $mw if ($bestmove == -1);
		}
	outerLoop:
	}

	return $bestmove if ( $bestmove != -1 );

	#  No move is totally satisfactory, try the first one that is open
	for ( my $i = 0; $i < 9; $i++ ) {
		my $mw = $moves[$i];
		return $mw if ( (($white & (1 << $mw)) == 0) && (($black & (1 << $mw)) == 0) );
	}

	#  No more moves
	-1;
}


##
#  User move.
#  @return true if legal
#

sub yourMove
{
	my $m = $_[0]->getIntegerField ( 'Coordinate' );
	# print "  O's move is $m\n";

	return $false if ( ($m < 0) || ($m > 8) );
	return $false if ( (($black | $white) & (1 << $m)) != 0 );

	$black |= 1 << $m;

	$true;
}


##
#  Computer move.
#  @return true if legal
#
sub myMove
{
	return $false if ( ($black | $white) == $DONE );

	my $best = bestMove ( $white, $black );
	$white |= 1 << $best;

	# print "  X's move is $best\n";
	$staticBoard [ $best ] = 'O';  # client script hack

	$best;
}


sub setBoard
{
my $e = shift;
my $i = 0;

	my %hash = $e->toHash;
	my @board;
	if ( exists($hash{Board}) ) {
		#
		# we are playing against Apache
		#
		@board = @{ $hash{Board} };
	}
	else {
		#
		# we are playing against a client script
		#
		$staticBoard [ $hash{Coordinate} ] = 'X';
		@board = @staticBoard;
	}

	foreach my $m (@board) {
		if ( $m eq "X" ) {
			$black |= 1 << $i;
		} elsif ( $m eq "O" ) {
			$white |= 1 << $i;
		}
		$i++;
	}
}


##
#  Figure what the status of the game is.
#
sub status
{
	return $WIN       if ( $won[$white] );
	return $LOSE      if ( $won[$black] );
	return $STALEMATE if ( ($black | $white) == $DONE );
	
	$OK;
}


sub startup
{
my $self = shift;

	#  subscribe to TicTacToe events:
	return $false if ( $self->newSubscription ( $tttEvent, 0        ) );
	return $false if ( $self->newSubscription ( $tttEventRequest, 0 ) );

	#  register the event
	$self->addEvent( new Aw::EventType ( $tttEvent        ) );
	$self->addEvent( new Aw::EventType ( $tttEventRequest ) );

	
	( $self->initStatusSubscriptions ) ? $false : $true ;  # init also does publishStatus
}



sub processRequest
{
my ($self, $requestEvent, $eventDef) = @_;

	# print $requestEvent->toString;

	my $eventTypeName = $requestEvent->getTypeName;
	$move ||= $self->createEvent ( $tttEvent );

	$black = $white = 0;

	if ( $eventTypeName eq $tttEventRequest ) {
		$self->deliverAckReplyEvent;
		resetStaticBoard;
	}
	elsif ( $eventTypeName eq $tttEvent ) {
		setBoard ( $requestEvent );
		$move->setIntegerField ( 'Coordinate', myMove );
		$self->deliverReplyEvent ( $move );
	}
 	print "Waiting for O's move...\n";
	
	$true;
}


package main;

main: {

	my %properties = (
	        clientId	=> "TicTacToe Adapter",
	        # broker	=> 'test_broker@localhost:6449',
	        broker		=> $ARGV[0],
	        adapterId	=> 0,
	        debug		=> 0,
	        clientGroup	=> "PerlDemoAdapter",
	        adapterType	=> "ttt_adapter",
	);


	#  Start with one step...
	#
	my $adapter = new TicTacToeAdapter ( \%properties );

	$adapter->init;

	my $retVal = 0;

	#  process connection testing mode 
	#
	die ( "\n$retVal = ", $adapter->connectTest, "\n" )
		if ( $adapter->isConnectTest );

	if ( $adapter->createClient ) {
  		# we don't want to go here.
		$retVal = 1;
	} else {
		# we want to go here

		$retVal = $adapter->startup;

		my $test = $adapter->getEvents;

		$retVal = 1 if ($retVal && $adapter->getEvents);
	}


	print "\nRetval = $retVal\n";
}


__END__

/*
 * @(#)TicTacToe.java	1.4 98/06/29
 *
 * Copyright (c) 1997, 1998 Sun Microsystems, Inc. All Rights Reserved.
 *
 * Sun grants you ("Licensee") a non-exclusive, royalty free, license to use,
 * modify and redistribute this software in source and binary code form,
 * provided that i) this copyright notice and license appear on all copies of
 * the software; and ii) Licensee does not utilize the software in a manner
 * which is disparaging to Sun.
 *
 * This software is provided "AS IS," without a warranty of any kind. ALL
 * EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, INCLUDING ANY
 * IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR
 * NON-INFRINGEMENT, ARE HEREBY EXCLUDED. SUN AND ITS LICENSORS SHALL NOT BE
 * LIABLE FOR ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING, MODIFYING
 * OR DISTRIBUTING THE SOFTWARE OR ITS DERIVATIVES. IN NO EVENT WILL SUN OR ITS
 * LICENSORS BE LIABLE FOR ANY LOST REVENUE, PROFIT OR DATA, OR FOR DIRECT,
 * INDIRECT, SPECIAL, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE DAMAGES, HOWEVER
 * CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY, ARISING OUT OF THE USE OF
 * OR INABILITY TO USE SOFTWARE, EVEN IF SUN HAS BEEN ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGES.
 *
 * This software is not designed or intended for use in on-line control of
 * aircraft, air traffic, aircraft navigation or aircraft communications; or in
 * the design, construction, operation or maintenance of any nuclear
 * facility. Licensee represents and warrants that it will not use or
 * redistribute the Software for such purposes.
 */


/**
 * A TicTacToe applet. A very simple, and mostly brain-dead
 * implementation of your favorite game! <p>
 *
 * In this game a position is represented by a white and black
 * bitmask. A bit is set if a position is ocupied. There are
 * 9 squares so there are 1<<9 possible positions for each
 * side. An array of 1<<9 booleans is created, it marks
 * all the winning positions.
 *
 * @version 	1.2, 13 Oct 1995
 * @author Arthur van Hoff
 * @modified 04/23/96 Jim Hagen : winning sounds
 * @modified 02/10/98 Mike McCloskey : added destroy()
 */


=head1 NAME

ttt_adapter.pl - A TicTacToe Adapter for ActiveWorks Brokers.

=head1 SYNOPSIS

./ttt_adapter.pl MyBroker@MyHost:1234

=head1 DESCRIPTION

The TicTacToe adapter is based loosely on the Java applet by
Arthur van Hoff.  The adapter will play against the mod_perl
client found in bin/apache/site_perl/Apache/Toe.pm.  The adapter
can also play against the ttt_client.pl client script. 

=head1 AUTHOR

Daniel Yacob Mekonnen,  L<Yacob@wMUsers.Com|mailto:Yacob@wMUsers.Com>

=head1 SEE ALSO

S<perl(1). ActiveWorks Supplied Documentation>

=cut
