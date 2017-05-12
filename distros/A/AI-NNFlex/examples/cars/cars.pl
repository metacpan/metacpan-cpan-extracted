#########################################################
# Benchmark using the car acceptability data from
# ftp://ftp.ics.uci.edu/pub/machine-learning-databases/car/
#
#########################################################

use strict;

#unacc, acc, good, vgood
#
#| attributes
#
#buying:   vhigh, high, med, low.
#maint:    vhigh, high, med, low.
#doors:    2, 3, 4, 5more.
#persons:  2, 4, more.
#lug_boot: small, med, big.
#safety:   low, med, high.
my @dataArray;

my %translate = (
	'accept'=>{'0 0'=>'unacc',
		'0 1'=>'acc',
		'1 0'=>'good',
		'1 1'=>'vgood',
		'unacc'=>'0 0',
		'acc'=>'0 1',
		'good'=>'1 0',
		'vgood'=>'1 1'},
	'buying'=>{'1 1'=>'vhigh',
		'1 0'=>'high',
		'0 1'=>'med',
		'0 0'=>'low',
		'vhigh'=>'1 1',
		'high'=>'1 0',
		'med'=>'0 1',
		'low'=>'0 0'},

	'maint'=>{'1 1'=>'vhigh',
		'1 0'=>'high',
		'0 1'=>'med',
		'0 0'=>'low',
		'vhigh'=>'1 1',
		'high'=>'1 0',
		'med'=>'0 1',
		'low'=>'0 0'},
	
	'doors'=>{'1 1'=>'2',
		'1 0'=>'3',
		'0 1'=>'4',
		'0 0'=>'5more',
		'2'=>'1 1',
		'3'=>'1 0',
		'4'=>'0 1',
		'5more'=>'0 0'},

	'persons'=>{'0 0'=>'2',
		'1 0'=>'4',
		'1 1'=>'more',
		'2'=>'0 0',
		'4'=>'1 0',
		'more'=>'1 1'},

	'lug_boot'=>{'0 0'=>'small',
		'1 0'=>'med',
		'1 1'=>'big',
		'small'=>'0 0',
		'med'=>'1 0',
		'big'=>'1 1'},

	'safety'=>{'0 0'=>'low',
		'1 0'=>'med',
		'1 1'=>'high',
		'low'=>'0 0',
		'med'=>'1 0',
		'high'=>'1 1'});


open (CARS,"car_data.txt") or die "Can't open file";

while (<CARS>)
{
	chomp $_;

	if ($_ !~ /\w+/){next} # skip blank lines

	my ($buying,$maint,$doors,$persons,$lug_boot,$safety,$accept) = split /,/,$_;

	my $inputString = $translate{'buying'}->{$buying}. " "
	.$translate{'maint'}->{$maint}. " "
	.$translate{'doors'}->{$doors}. " "
	.$translate{'persons'}->{$persons}. " "
	.$translate{'lug_boot'}->{$lug_boot}. " "
	.$translate{'safety'}->{$safety};

	my $outputString = $translate{'accept'}->{$accept};


	my @inputArray = split / /,$inputString;
	my @outputArray = split / /,$outputString;
if (scalar @inputArray != 12 || scalar @outputArray != 2)
{
	print "--$inputString $outputString\n";
}

	push @dataArray,\@inputArray,\@outputArray;
	
}

close CARS;


######################################################################
# data now constructed, we can do the NN thing
######################################################################

use AI::NNFlex::Backprop;
use AI::NNFlex::Dataset;

my $dataset = AI::NNFlex::Dataset->new(\@dataArray);


my $network = AI::NNFlex::Backprop->new( learningrate=>.1,
				fahlmanconstant=>0.1,
				bias=>1,
				momentum=>0.6);



$network->add_layer(	nodes=>12,
			activationfunction=>"tanh");


$network->add_layer(	nodes=>12,
			activationfunction=>"tanh");

$network->add_layer(	nodes=>2,
			activationfunction=>"linear");


$network->init();

$network->connect(fromlayer=>2,tolayer=>2);

my $counter=0;
my $err = 10;
while ($err >.001)
{
	$err = $dataset->learn($network);

	print "Epoch $counter: Error = $err\n";
	$counter++;
}


foreach (@{$dataset->run($network)})
{
	foreach (@$_){print $_}
	print "\n";	
}



