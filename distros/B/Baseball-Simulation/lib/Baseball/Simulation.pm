package Baseball::Simulation;

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = ( );

our @EXPORT = (	
);

our $VERSION = '0.10';

#The Global Parameters that are the arguments
my %arg;
my $TeamBattingFile = "";
my $TeamPitchingFile = "";
my $NumOfSeasons = 1;

#Global variables used by various arguments
my @Lineup;
my @PitchingLineup;

##################################################
# new
#
# Parameters: An argument list containing:
#             BattingFile - The batters file stats
#             PitchingFile - The batters file stats
#             Seasons - the number of seasons to simulate
#                       (default 1)
#
# Description: Creates an object and checks if the parameters are
#              correct..
#
# Returns: Return itself unless there is a parameter error, in which
#          it dies
#
##################################################
sub new {
    my $class = shift;
    %arg = @_;

    $TeamBattingFile = $arg{'BattingFile'};
    $TeamPitchingFile = $arg{'PitchingFile'};
    $NumOfSeasons = $arg{'Seasons'} || 1;

    unless (-e $TeamBattingFile) {
	die "Cannot open the batting file: $TeamBattingFile";
    }

    unless (-e $TeamPitchingFile) {
	die "Cannot open the pitching file: $TeamPitchingFile";
    }

    @Lineup = CreateBatterArray(CreateNewLineup($TeamBattingFile));
    
    @PitchingLineup= CreateBatterArray(CreateNewLineup($TeamPitchingFile));

    return bless{}, $class;
}

##################################################
# Round
#
# Parameters: un unrounded number
#
# Description: Rounds a number 
#
# Returns: The rounded number
#
##################################################
sub Round($) {
    my $Float = $_[0];
    $Float += 0.5;
    return int($Float);
}

##################################################
# StripLine
#
# Parameters: A line with white surrounding white space and comments
#
# Description: Removes surrounding white space and comments
#
# Returns: A cleaned up line
#
##################################################
sub StripLine($) {
    my $LineToBeParsed = $_[0];	# The text to be stripped
    chomp $LineToBeParsed;	# Get rid of line feed
    
    # Delete leading spaces;
    if ( $LineToBeParsed =~ /^\s+/ ) {
	$LineToBeParsed = $'; #'
    }
    
    # Check for comment characters
    if ( $LineToBeParsed =~ /#/ )  {
	$LineToBeParsed = $`;
    }
    # Delete the ending spaces
    if ( $LineToBeParsed =~ /\s+$/ )  {
	$LineToBeParsed = $`;
    }
    
    return $LineToBeParsed;
}

##################################################
# CreateBatter
#
# Paramenters: The array consisting the cumalitve totals for:
#             At-Bats
#             Walks
#             Singles
#             Doubles
#             Triples
#             Homers
#             StolenBases
#
# Description: Calculates the averages for the batting statistics
#
# Returns: The array consisting the cumalitve averages for:
#             WalkChance - The percentage for a walk
#             SingleChance - The percentage that a single can be hit
#             DoubleChance - The percentage that a single can be hit
#             TripleChance - The percentage that a single can be hit
#             HomerChance - The percentage that a single can be hit
#             SacChance - The percentage that a sacrifice occurs
#             StolenBaseChance - The percentage that a stolen base occurs
#
##################################################
sub CreateBatterArray(@) {
    my ($AtBats, $Hits, $Doubles, $Triples, $Homers, $Walks, $Steals) = @_;
    my $TotalAtBats = $AtBats + $Walks;
    my $Singles = $Hits - $Doubles - $Triples - $Homers;
    my $WalkChance = int (($Walks / $TotalAtBats) * 1000);
    my $SinglesChance = int (($Singles / $TotalAtBats) * 1000);
    my $DoublesChance = int (($Doubles / $TotalAtBats) * 1000);
    my $TriplesChance = int (($Triples / $TotalAtBats) * 1000);
    my $HomersChance = int (($Homers / $TotalAtBats) * 1000);
    my $StealsChance = int ($Steals / ($Walks + $Singles));
    my $SacrificeChance = 0;

    return ($WalkChance, $SinglesChance, $DoublesChance, $TriplesChance, $HomersChance, $SacrificeChance, $StealsChance); 
}

##################################################
# CreateNewLineup
#
# Parameters: The file of user list
#
# Description: Reads the stats from a file, adding the additions
#              and subtracting the subtractions
#
# Returns: The array consisting the cumalitve totals for:
#             At-Bats
#             Walks
#             Singles
#             Doubles
#             Triples
#             Homers
#             StolenBases
#
##################################################
sub CreateNewLineup($) {
    my $File = $_[0];
    my @TotalStats = (0,0,0,0,0,0,0);;
    my @PlayerStats = (0,0,0,0,0,0,0);
    my $Line;

    open(INFILE, "$File") || die "Cannot open $File";
    my @FileLines = <INFILE>;
    close(INFILE);
    
    my $i = 0;
    my $MaxLine = @FileLines;
    while (($Line = $FileLines[$i++]) && ($i <= $MaxLine)){
	$Line = StripLine($Line);
	next unless ($Line);
	@TotalStats = split /\:/, $Line;
	if ($#TotalStats + 1 != 7) {
	    die "The following line does not contain 7 double colon seperated values: $Line";
	}
	last;
    }

    while (($Line = $FileLines[$i++]) && ($i <= $MaxLine)){
	$Line = StripLine($Line);
	last if ($Line =~ /additions/i);
    }

    my $l = 0;
    while (($Line = $FileLines[$i++]) && ($i <= $MaxLine)){
	$Line = StripLine($Line);
	last if ($Line =~ /sub/i);
	if ($Line) {
	    my $j = 0;
	    @PlayerStats = split /\:/, $Line;
	    if ($#PlayerStats + 1 != 7) {
		die "The following line does not contain 7 double colon seperated values: $Line";
	    }	 
	    for ($l = 0; $l < 7; $l++) {
		$TotalStats[$l] += $PlayerStats[$l];
	    }	
	}
    }

    while (($Line = $FileLines[$i++]) && ($i <= $MaxLine)){
	$Line = StripLine($Line);
	if ($Line) {
	    @PlayerStats = split /\:/, $Line;
	    if ($#PlayerStats + 1 != 7) {
		die "The following line does not contain 7 double colon seperated values: $Line";
	    }	 
	    for ($l = 0; $l < 7; $l++) {
		$TotalStats[$l] -= $PlayerStats[$l];
	    }	
	}
    }

    return @TotalStats;
}

##################################################
# AtBat
#
# Parameters: WalkChance - The percentage for a walk
#             SingleChance - The percentage that a single can be hit
#             DoubleChance - The percentage that a single can be hit
#             TripleChance - The percentage that a single can be hit
#             HomerChance - The percentage that a single can be hit
#             SacChance - The percentage that a single can be hit
#             StolenBaseChance - The percentage that a single can be hit
#
# Description: Simulates an at-bat
#
# Returns: The result - -1 = walk
#                       0 = out
#                       1 = single
#                       2 = double
#                       3 = triple
#                       4 = home run
#
##################################################
#ignore double plays and sacrifices for now
sub AtBat(@) {
    my $WalkChance = 0;
    my $SingleChance = 0;
    my $DoubleChance = 0;
    my $TripleChance = 0;
    my $HomerChance = 0;
    my $SacChance = 0;
    my $StolenBaseChance = 0;
    my $Random2 = 0;
    ($WalkChance, $SingleChance, $DoubleChance, $TripleChance, $HomerChance, $SacChance, $StolenBaseChance)  = @_;
    
    $Random2 = (((int (rand(10000))) + (int (rand(2000))))
		  % 1000);

    if ($Random2 < $WalkChance) {
	return -1;
    } elsif ($Random2 < ($SingleChance + $WalkChance)) {
	return 1;
    } elsif ($Random2 < ($SingleChance + $WalkChance + $DoubleChance)) {
	return 2;
    } elsif ($Random2 < ($SingleChance + $WalkChance + $DoubleChance + $TripleChance)) {
	return 3;
    } elsif ($Random2 < ($SingleChance + $WalkChance + $DoubleChance + $TripleChance + $HomerChance)) {
	return 4;
    }

    return 0;
}

##################################################
# AdvanceRunner
#
# Parameters: Result - the result of the at bat
#             PlayerStealChance - the player's chance of stealing
#             FirstBase - whether someone is on first
#             FirstBaseStealChance - the guys on first's chance of stealing
#             SecondBase - whether someone is on second
#             SecondBaseStealChance - the guys on third's chance of stealing
#             ThirdBase - whether someone is on third
#             Score - The score so far
#
# Description: Advances runners after an at-bat
#
# Returns:  Updated values for: $FirstBase, $FirstBaseStealChance, $
#           SecondBase, $SecondBaseStealChance, $ThirdBase, $Score
#
##################################################
sub AdvanceRunner($$$$$$$$) {
    my ($Result, $PlayerStealChance, $FirstBase, $FirstBaseStealChance, $SecondBase, $SecondBaseStealChance, $ThirdBase, $Score) = @_;

    if ($Result == -1) { 
	if ($FirstBase && $SecondBase && $ThirdBase) {
	    #Advance all one
	    $Score++;
	    $SecondBaseStealChance = $FirstBaseStealChance;
	} elsif ($FirstBase && $SecondBase) {
	    #Advance the first two one
	    $SecondBaseStealChance = $FirstBaseStealChance;
	    $ThirdBase = 1;
	} elsif ($FirstBase) {
	    #Advance the first base
	    $SecondBaseStealChance = $FirstBaseStealChance;
	    $SecondBase = 1;
	}
	$FirstBase = 1;
	$FirstBaseStealChance = $PlayerStealChance;
    } elsif ($Result == 1) {
	#ThirdBase always scores
	if ($ThirdBase) {
	    $Score++;
	    $ThirdBase = 0;
	}
	if ($SecondBase) {
	    $SecondBase = 0;
	    #There is a 70% chance the guy from second score
	    if (rand (10) < 7) {
		$Score++;
	    } else {
		$ThirdBase = 0;
	    }

	} elsif ($FirstBase) {
	    #There is a 70% chance the guy from second score
	    if (rand (10) < 7) {
		$ThirdBase = 1;
	    } else {
		$SecondBase = 1;
		$SecondBaseStealChance = $FirstBaseStealChance;
	    }
	}	
	$FirstBaseStealChance = $PlayerStealChance;
	$FirstBase = 1;
    } elsif ($Result == 2) {
	$Score = $Score + $SecondBase + $ThirdBase;
	$ThirdBase = 0;
	$SecondBase = 1;
	#There is a 70% chance the guy from first scores
	if ($FirstBase) {
	    if (rand (10) < 7) {
		$Score += $FirstBase;
		$ThirdBase = 0;
	    } else {
		$ThirdBase = 1;
	    }
	}
	$FirstBase = 0;
	$SecondBaseStealChance = $PlayerStealChance;
    } elsif ($Result == 3) {
	$Score = $Score + $FirstBase + $SecondBase + $ThirdBase;
	$FirstBase = 0;
	$SecondBase = 0;
	$ThirdBase = 1;
    } elsif ($Result == 4) {
	$Score = $Score + $FirstBase + $SecondBase + $ThirdBase + 1;
	$FirstBase = 0;
	$SecondBase = 0;
	$ThirdBase = 0;
    } elsif ($Result == 0) {
	if ($ThirdBase) {
	    #Sacrifice for third
	    if (rand (10) < 4) {
		$Score++;
		$ThirdBase = 0;
	    } 
	} elsif($SecondBase && !$ThirdBase) {
	    if (rand (10) < 3) {
		$ThirdBase = 1;
		$SecondBase = 0;
	    }	    
	}  elsif($FirstBase && !$SecondBase) {
	    if (rand (10) < 3) {
		$SecondBase = 1;
		$FirstBase = 0;
		$SecondBaseStealChance = $FirstBaseStealChance;
	    }	    
	}
    }

    return ($FirstBase, $FirstBaseStealChance, $SecondBase, $SecondBaseStealChance, $ThirdBase, $Score);
}

##################################################
# Inning
#
# Parameters: Who is batting - 1 if the team is batting
#                            - 0 if the other team is batting
#
# Description: Simulates an inning
#
# Returns: Returns the score from that inning
#
##################################################
sub Inning($) {
    my $Who = $_[0];
    my $Outs = 0;
    my $FirstBase = 0;
    my $FirstBaseStealChance = 0;
    my $SecondBase = 0;
    my $SecondBaseStealChance = 0;
    my $ThirdBase = 0;
    my $Score = 0;
    my $Result = 0;
    my @Player = "";

    if ($Who) {
	@Player = @Lineup;
    } else {
	@Player = @PitchingLineup;
    }

    while ($Outs < 3) {
	$Result = AtBat(@Player);
	if (!$Result) {
	    $Outs++;
	} if ($Outs < 3) {
	    ($FirstBase, $FirstBaseStealChance, $SecondBase, $SecondBaseStealChance, $ThirdBase, $Score) =  AdvanceRunner($Result, $Player[6], $FirstBase, $FirstBaseStealChance, $SecondBase, $SecondBaseStealChance, $ThirdBase, $Score);
	}
    }

    return $Score;
}

##################################################
# Simulate
#
# Parameters: None 
#
# Description: Simulates the season
#
# Returns: Average victories per season
#          Average defeats per season
#          Average runs scored per season
#          Average runs allowed per season
#
##################################################
sub Simulate() {
    my $TotalVictories = 0;
    my $TotalDefeats = 0;
    my $SingleOtherScore = 0;
    my $TotalScore = 0;
    my $TotalOtherScore = 0;
    
    my $i = 0;
    my $k = 0;

    for ($k = 0; $k < $NumOfSeasons; $k++) {
	my $Victories = 0;
	my $Defeats = 0;
	my $SingleScore = 0;
	my $j = 0;

	for ($j = 0; $j < 162; $j++) {
	    $SingleScore = 0;
	    for ($i = 1; $i <= 9; $i++) {
		$SingleScore += Inning(1);
	    }

	    #The opposing team
	    $SingleOtherScore = 0;
	    for ($i = 1; $i <= 9; $i++) {
		$SingleOtherScore += Inning(0);
	    }


	    while ($SingleScore == $SingleOtherScore) {
		$SingleScore +=Inning(1);
		$SingleOtherScore +=Inning(0);
	    }

	    if ($SingleScore > $SingleOtherScore) {
		$Victories++;
	    } elsif ($SingleScore < $SingleOtherScore) {
		$Defeats++;
	    }
	    
	    
	    $TotalScore +=$SingleScore;
	    
	    $TotalOtherScore +=$SingleOtherScore;
	}

	$TotalVictories += $Victories;
	$TotalDefeats += $Defeats;

    }

    return ($TotalVictories/$NumOfSeasons, $TotalDefeats/$NumOfSeasons, $TotalScore/$NumOfSeasons, $TotalOtherScore/$NumOfSeasons);
}

1;
__END__

=head1 NAME

Baseball::Simulation - Perl module to simulate the number of wins, losses, runs scored, and runs allowed given a team's statistics.

=head1 SYNOPSIS

  use Baseball::Simulation;

  my $obj = new Baseball::Simulation(BattingFile => "tmp_bat",
      PitchingFile => "tmp_pitch",
      Seasons => 10);

  my ($Won, $Lost, $RunsScored, $RunsAgainst) =  $obj->Simulate();

=head1 DESCRIPTION

This is a simple module that will simulate seasons for baseball and returns the average number of wins, losses, runs scored, and runs scored against.  It takes in three argments.

The "Seasons" argument is the number of seasons to simulate.  Obviously, the more seasons simulated, the more accurate the prediction.  If not entered, it defaults to 1.

The next two are "BattingFile" and "PitchingFile."  These are files that contain the statistics for the team :  The BattingFile contains the offensive statistics of the team.  The PitchingFile contains the offensive statistics allowed by the team's pitching staff.

Both files are in the following format:

    <At-Bats>:<Hits>:<Doubles>:<Triples>:<Home Runs>:<Walks>:<Steals>

    Additions:

    <At-Bats>:<Hits>:<Doubles>:<Triples>:<Home Runs>:<Walks>:<Steals>

    Subractions:

    <At-Bats>:<Hits>:<Doubles>:<Triples>:<Home Runs>:<Walks>:<Steals>

The first line is the total team statistics.  Following "Additions", there can be multiple players statistics representing players that have been added.  Following "Subtractions", there can be multiple players that were left off the team.  Note, these are optional, but "Subtractions" must follow "Additions", even if "Additions" is blank.  Also, commented lines can be inserted, provided those lines start with '#'.

=head2 EXPORT

None by default.

=head1 EXAMPLE

The following example shows the impact of Baltimore's 2004 batting changes.  Though pitching changes can be made, it will be ignored for the sake of simplicity.and to isolate the offensive changes only.  First, create a baltimore_batting file, including the total 2003 stats, the stats for the added players, and the stats for the players removed.

The file contents of baltimore_batting_2003:

  5665:1516:277:24:152:431:89

The file contents of baltimore_batting_2004:

  5665:1516:277:24:152:431:89

  Additions:

  #Javy Lopez

  465:150:29:3:43:33:0

  #Miguel Tejada

  636:98:42:27:53:10:0

  Subtractions:

  #Brook Fordyce

  348:95:12:2:6:19:2

  #Devi Cruz

  548:137:24:3:14:13:1

  #Jeff Conine

  493:143:33:3:15:37:0

  #BJ Surhoff

  319:94:20:5:29:2:0

The pitching stats will be the just the 2003 stats.

The file contents of baltimore_pitching:

  5683:1579:309:27:198:526:121

The code to test will be:
  my $obj2004 = new Baseball::Simulation(BattingFile => "baltimore_batting2004",
      PitchingFile => "baltimore_pitching",
      Seasons => 100);

  my ($Won2004, $Lost2004, $Runs2004, $RunsAgainst2004) = $obj2004->Simulate();

  my $obj2003 = new Baseball::Simulation(BattingFile => "baltimore_batting2003",
	  PitchingFile => "baltimore_pitching",
	  Seasons => 100);

  my ($Won2003, $Lost2003, $Runs2003, $RunsAgainst2003) = $obj2003->Simulate();
  my $Difference = $Win2004 - $Win2003;

  print "test: The offensive difference between 2004 and 2003 wins is $Difference wins\n";

=head1 AUTHOR

Nirave Kadakia, E<lt>kadakia@hotmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Nirave Kadakia

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
