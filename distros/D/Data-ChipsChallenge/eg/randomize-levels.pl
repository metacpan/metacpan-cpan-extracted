#!/usr/bin/perl -w

use Data::ChipsChallenge;

print "Loading CHIPS.DAT and creating new quest\n";
my $cc = new Data::ChipsChallenge ("CHIPS.DAT");
my $new = new Data::ChipsChallenge;
$new->create ($cc->levels);

# map the level number to a hash
my $allmaps = $cc->levels;
my %maps_left;
for (my $i = 1; $i <= $allmaps; $i++) {
	$maps_left{$i} = 1;
}
my @maps = keys %maps_left;
my $i = 1;

print "Randomizing the levels\n";
while (scalar(keys(%maps_left)) > 0) {
	my $pick = $maps[ int(rand(scalar(@maps))) ];
	delete $maps_left{$pick};
	@maps = keys %maps_left;
	print "Placing level $pick as level $i\n";

	my $meta = $cc->getLevelInfo($pick);
	print "\t$meta->{level} - $meta->{title}\n";

	# Send this data to our new level
	$new->setLevelInfo ($i,
		title    => $meta->{title},
		password => $meta->{password},
		time     => $meta->{time},
		chips    => $meta->{chips},
		hint     => $meta->{hint},
	);

	# get the stages
	my $upper = $cc->getUpperLayer($pick) or die $Data::ChipsChallenge::Error;
	my $lower = $cc->getLowerLayer($pick) or die $Data::ChipsChallenge::Error;
	$new->setUpperLayer($i,$upper) or die $Data::ChipsChallenge::Error;
	$new->setLowerLayer($i,$lower) or die $Data::ChipsChallenge::Error;

	# get the bear traps and clone machines
	my $traps = $cc->getBearTraps($pick) or die $Data::ChipsChallenge::Error;
	my $clone = $cc->getCloneMachines($pick) or die $Data::ChipsChallenge::Error;
	$new->setBearTraps($i,$traps) or die $Data::ChipsChallenge::Error;
	$new->setCloneMachines($i,$clone) or die $Data::ChipsChallenge::Error;

	# copy the movement layer
	my $move = $cc->getMovement($pick) or die $Data::ChipsChallenge::Error;
	$new->setMovement($i,$move) or die $Data::ChipsChallenge::Error;
	$i++;
}

print "Writing the file\n";
$new->write("./out/CHIPS.DAT");
