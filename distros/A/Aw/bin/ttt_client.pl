#!/usr/bin/perl -w


package TicTacToeClient;
use base qw(Aw::Client);

use strict;

use Aw 'test_broker@localhost:6449';
require Aw::Event;


my %board           = ();
my $tttEvent        = "PerlDevKit::TicTacToe";
my $tttEventRequest = "PerlDevKit::TicTacToeRequest";


sub printBoard
{
my %pBoard = %board;


	$pBoard{'1,1'} = " " unless ( $board{'1,1'} );
	$pBoard{'1,2'} = " " unless ( $board{'1,2'} );
	$pBoard{'1,3'} = " " unless ( $board{'1,3'} );
	$pBoard{'2,1'} = " " unless ( $board{'2,1'} );
	$pBoard{'2,2'} = " " unless ( $board{'2,2'} );
	$pBoard{'2,3'} = " " unless ( $board{'2,3'} );
	$pBoard{'3,1'} = " " unless ( $board{'3,1'} );
	$pBoard{'3,2'} = " " unless ( $board{'3,2'} );
	$pBoard{'3,3'} = " " unless ( $board{'3,3'} );
	print <<TABLE;

 $pBoard{'1,1'} | $pBoard{'1,2'} | $pBoard{'1,3'}
-----------
 $pBoard{'2,1'} | $pBoard{'2,2'} | $pBoard{'2,3'}
-----------
 $pBoard{'3,1'} | $pBoard{'3,2'} | $pBoard{'3,3'}

TABLE

}


my $moves = 0;


sub checkWin
{
my @check_win =(
	"1,1", "1,2", "1,3",
	"2,1", "2,2", "2,3",
	"3,1", "3,2", "3,3",

	"1,1", "2,1", "3,1",
	"1,2", "2,2", "3,2",
	"1,3", "2,3", "3,3",

	"1,1", "2,2", "3,3",
	"1,3", "2,2", "3,1",
);


	while (@check_win) {
		my(%spot);

		$spot{1} = shift(@check_win);
		return if (!$spot{1});

		$spot{2} = shift(@check_win);
		$spot{3} = shift(@check_win);

		next if (!$board{$spot{1}} || !$board{$spot{2}} || !$board{$spot{3}});

		if ($board{$spot{1}} eq $board{$spot{2}} && $board{$spot{2}} eq $board{$spot{3}}) {
			print "\nWE HAVE A WINNER!  $board{$spot{1}} WINS!  :-)\n";
			printBoard;
			exit;
		}

	}
	if ( $moves == 9 ) {
		print "\nNo Winner This Time!\n";
		exit;
	}


}



sub updateBoard
{
shift;
	if ( ref($_[0]) eq "ARRAY" ) {
		#
		#  Local Move
		#
		$board { "$_[0]->[0],$_[0]->[1]" } = 'X';
	} else {
		#
		#  Remote Move
		#
		my %hash   = $_[0]->toHash;
		my $x      = ($hash{Coordinate}/3 + 1)%4;
		my $y      = $hash{Coordinate}%3 + 1;
		print "x,y = $x,$y\n";
		$board { "$x,$y" } = 'O';
	}

	checkWin if ( ++$moves > 4 );

}



sub nextCoord
{
my ($self, $e) = @_;

	RESTART:
    	print "Enter coordinates (r,c): ";
	my $input = <STDIN>;
	$input =~ s/\s//g;
	exit if ( $input eq "q" );
	if ($input =~ /^(\d)\,(\d)$/ && ($1 > 3 || $1 == 0 || $2 > 3 || $2 == 0)) {
		print "\nNumbers out of range.\n";
		goto RESTART;
	} elsif ( $input !~ /^\d\,\d$/ ) {
		print "\nBogus Data Dude!\n";
		goto RESTART;
	} elsif ( $board{$input} ) {
		print "\nThere's ALREADY a letter there!\n";
		goto RESTART;
	}
	my @coord = split ( /,/, $input, 2);

	$e->setField ( 'Coordinate', (($coord[0]-1)*3 + ($coord[1]-1)) );

	print "  publish Error!\n" if ( $self->publish ( $e ) );
	$self->updateBoard ( \@coord  );
	printBoard;
}



main:
{

	my $c = new TicTacToeClient ( "PerlDemoClient", "TicTacToe" );
	
	unless ( $c->canPublish ( $tttEvent ) ) {
		printf STDERR "Cannot publish to %s: %s\n", $tttEvent, $c->errmsg;
		exit ( 0 );
	}
	
	unless ( $c->canPublish ( $tttEventRequest ) ) {
		printf STDERR "Cannot publish to %s: %s\n", $tttEvent, $c->errmsg;
		exit ( 0 );
	}

	$c->newSubscriptions ( $tttEvent, $tttEventRequest, "_env.tag != $$" );

	my $t = new Aw::Event ($c, $tttEventRequest);
	$t->setTag ( $$ );
	print "  publish Error!\n" if ( $c->publish ( $t ) );


	my $e = new Aw::Event ( $c, $tttEvent );
	$e->setTag ( $$ );

	print "Waiting for O...\n";

	while ( my $r = $c->getEvent( AW_INFINITE ) ) {

		my $eventTypeName = $r->getTypeName;
		if ( ($eventTypeName eq $tttEventRequest)
		     || ($eventTypeName eq "Adapter::ack")
		   ) {
			print "You Go First!\n";
			$c->nextCoord ( $e );
  			print "Waiting for O's move...\n";
		}
		elsif ( $eventTypeName eq $tttEvent ) {
			$c->updateBoard ( $r );
			printBoard;
			$c->nextCoord ( $e );
  			print "Waiting for O's move...\n";
		}
		else {
		    	printf "Received \"%s\"\n", $eventTypeName;
		}

	}

}

__END__

=head1 NAME

ttt_client.pl - A TicTacToe Client for ActiveWorks Brokers.

=head1 SYNOPSIS

./ttt_client.pl

=head1 DESCRIPTION

The script will connect to the broker configured on line 5 of the script.
The client can play against other clients (the intended use).  If the
ttt_adapter.pl is connected to the same broker, the client will play against
the adapter.

=head1 AUTHOR

Daniel Yacob Mekonnen,  L<Yacob@wMUsers.Com|mailto:Yacob@wMUsers.Com>

=head1 SEE ALSO

S<perl(1). ActiveWorks Supplied Documentation>

=cut
