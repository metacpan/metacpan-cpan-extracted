package Apache::Toe;
#
# for reasons beyond my comprehension, the package breaks when
# named Apache::TicTacToe, probably a local config issue.
#

use strict;
use vars qw($VERSION);
$VERSION = '0.2';

use Apache::Constants qw(:common);
use Apache::Request;

use Aw;
require Aw::Client;
require Aw::Event;


my $eventTypeName;

my ($c,$te,$ter);
my $message = "ChildInit Error!";

my @board           = ();
my $tttEvent        = "PerlDevKit::TicTacToe";
my $tttEventRequest = "PerlDevKit::TicTacToeRequest";

my %Images 	=(
	'e'	=> "src=\"/images/TicTacToe/empty.gif\" alt=\"[ ]\"",
	'O'	=> "src=\"/images/TicTacToe/not.gif\" alt=\"[O]\"",
	'X'	=> "src=\"/images/TicTacToe/cross.gif\" alt=\"[X]\""
);



sub childinit
{

	$message="Hello";
	$c = new Aw::Client ( "PerlDemoClient", "Apache.$$" );
	
	unless ( $c->canPublish ( $tttEvent ) ) {
		$message="Can't publish:  $tttEvent";
		# printf STDERR "Cannot publish to %s: %s\n", $tttEvent, $c->errmsg;
		# exit ( 0 );
	}

	unless ( $c->canPublish ( $tttEventRequest ) ) {
		$message="Can't publish:  $tttEventRequest";
		# printf STDERR "Cannot publish to %s: %s\n", $tttEvent, $c->errmsg;
		# exit ( 0 );
	}

	$c->newSubscriptions ( $tttEvent, 0 );

	$ter = new Aw::Event ($c, $tttEventRequest);
	unless ( ref ($ter) ) {
		$message="TER HAS NO REF";
	}


	$te = new Aw::Event ( $c, $tttEvent );
	unless ( ref ($te) ) {
		$message="TER HA NO REF";
	}


1;
}


my $moves = 0;
my $WIN   = 1;
my $LOSE  = 2;
my $DRAW  = 3;
my $OK    = 0;

sub checkWin
{
my @check_win =(
	0, 1, 2,  # row 1
	3, 4, 5,  # row 2
	6, 7, 8,  # row 3

	0, 3, 6,  # col 1
	1, 4, 7,  # col 2
	2, 5, 8,  # col 3

	0, 4, 8,
	2, 4, 6
);


	while (@check_win) {

		my $tic = shift ( @check_win );
		return unless ( defined($tic) );

		my $tac = shift ( @check_win );
		my $toe = shift ( @check_win );

		next if ( ($board[$tic] eq 'e') || ($board[$tac] eq 'e') || ($board[$toe] eq 'e') );

		if ( ($board[$tic] eq $board[$tac]) && ($board[$tac] eq $board[$toe]) ) {
			return ( $board[$tic] eq 'X' ) ? $WIN : $LOSE;
		}

	}
	if ( $moves == 9 ) {
		return $DRAW;
	}

$OK;
}



sub printForm
{
my $r = shift;

#
#  Do a checkWin here and print winner
#

my $status = ( $moves > 4 ) ? checkWin : $OK;

my $title = "Your Move!";
if ( $status ) {
	if ( $status == $WIN ) {
		$title = "You Win!";
	}
	elsif ( $status == $LOSE ) {
		$title = "You Lose!";
	}
	else {
		$title = "Stalemate!  Noone Wins!";
	}
}

$r->print(<<TABLE);
<html>
<head>
  <title>TicTacToe</title>
</head>
<body bgcolor="#f0f0f0">
<h1 align="center">$title</h1>
<center><div align="center">
<table border>
TABLE

for (my $j=0; $j<3; $j++) {
	$r->print ( "  <tr align=\"center\">\n" );
	for (my $i=0; $i<3; $i++) {
		if ( $status == OK && $board[$j*3+$i] eq "e" ) {
  			$r->print ( "    <td><a href=\"/TicTacToe?board=(" );
			for (my $k=0; $k<9; $k++) {
				if ( $k == ($j*3+$i) ) {
					$r->print ("X,");
				}
				else {
					$r->print ("$board[$k],");
				}
			}
			$r->print ( ")\"><img border=0 $Images{'e'}></a></td>" );
		}
		else {
	  		$r->print ( "    <td><img border=0 $Images{$board[$j*3+$i]}></td>\n" );
		}
	}
	$r->print ( "  </tr>\n" );
}

$r->print(<<ENDTABLE);
</table>
</div></center>
ENDTABLE

$r->print ( "<hr><h4 align=\"center\"><i><a href=\"/TicTacToe\">Play Again?</a></i></h4>" ) if ( $status != $OK );

$r->print(<<END);
<hr>
<p align="center"><strong>According to Apache Server $$</strong></p>

</body>
</html>
END

}



sub updateBoard
{

	if ( ref($_[0]) eq "Aw::Event" ) {
	#
	#  Remote Move
	#
		$board [ $_[0]->getIntegerField('Coordinate') ] = 'O';
	} else {
	#
	#  Local Move
	#
		$board [ $_[0] ] = 'X';
	}

	$moves++;

}


sub handler
{
	my $r = new Apache::Request (shift);
	$r->content_type('text/html');
	$r->send_http_header;
	# my $host = $r->get_remote_host;

	# $r->print ("<h1>Client[$$]</h1>\n");
	unless ( ref($c) ) {
		$r->print ("<h1>Client Died: $message</h1>\n");
		return OK;
	}

	$eventTypeName = undef;
	#
	#  Make sure an adapter is present:
	#
	unless ( ref ( $ter) ) {
		$r->print ("Ter has no REF!" );
		return OK;
	}
	unless ( ref ( $te) ) {
		$r->print ("Te has no REF!" );
		return OK;
	}
	$r->print ( "<h1>Publish Error!</h1>\n" )  if ( $c->publish ( $ter ) );

	my $reply = $c->getEvent( AW_INFINITE );

	if ( ($eventTypeName = $reply->getTypeName) eq "Adapter::ack" ) {
		#
		#  Adapter is alive, proceed:
		#
		
		if ( my $cgiBoard = $r->param( 'board' ) ) {
			
			$cgiBoard =~ s/([eXO])/'$1'/g;
			$cgiBoard =~ s/,\)/)/;
			@board = eval ( $cgiBoard );
			$moves = 0;
			for (my $i=0; $i<9; $i++) {
				$moves++ if ( $board[$i] =~ /[XO]/ );
			}
			if ( $moves < 9 ) {
				$te->setCharSeqField ( 'Board', 0, 0, \@board );
				# my $pubId = $reply->getPubId;
				# $c->deliver ( $pubId, $te );
				$c->deliver ( "TicTacToe Adapter", $te );
				my $move = $c->getEvent( AW_INFINITE );
				if ( $move->getTypeName eq $tttEvent ) {
					updateBoard ( $move );
				}
				else {
					$r->printf ("<h3>Got Some Debugging to do: %s</h3>", $move->getTypename);
				}
			}
			printForm ( $r );
		}
		else {
			#
			#  If we have no CGI data then this is our first round
			#
			@board = ( 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e');
			printForm ( $r );
		}

	}

OK;
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__

=head1 NAME

Apache::Toe - A mod_perl Web Client for Playing TicTacToe Against An ActiveWorks Adapter.

=head1 SYNOPSIS

See the apache/conf/perl.conf and apache/conf/startup.pl files.


=head1 DESCRIPTION

The Apache::Toe module will play the game of Tic-Tac-Toe thru
an Apache server and ActiveWorks broker.  The module demonstrates
an Aw::Client used under mod_perl.  The bin/ttt_adapter.pl must
be running and attached to the same broker used by this module.
The Apache::Toe module assumes the default broker configured
in the local Aw:: module (and may be reset on either lines 14 or 40).

This modules is a bit crufty, but still works as advertised.

=head1 AUTHOR

Daniel Yacob Mekonnen,  L<Yacob@wMUsers.Com|mailto:Yacob@wMUsers.Com>

=head1 SEE ALSO

S<perl(1).  Aw(3).>

=cut
