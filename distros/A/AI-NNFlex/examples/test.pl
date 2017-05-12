# Example demonstrating XOR with momentum backprop learning

use strict;
use AI::NNFlex::Backprop;
use AI::NNFlex::Dataset;


# create the numbers
my %numbers;
for (0..255)
{	
	my @array = split //,sprintf("%08b",$_);
	$numbers{$_} = \@array;
}

my @data;
for (my $counter=0;$counter < 14;$counter+=2)
{
	push @data,$numbers{$counter};

	push @data,$numbers{$counter*$counter};

}


# Create the network 

my $network = AI::NNFlex::Backprop->new(
				learningrate=>.05,
				bias=>1,
				fahlmanconstant=>0.1,
				momentum=>0.6,
				round=>1);



$network->add_layer(	nodes=>8,
			activationfunction=>"tanh");


$network->add_layer(	nodes=>8,
			errorfunction=>'atanh',
			activationfunction=>"tanh");

$network->add_layer(	nodes=>8,
			activationfunction=>"linear");


$network->init();

my $dataset = AI::NNFlex::Dataset->new(\@data);



my $counter=0;
my $err = 10;
while ($err >.01)
{
	$err = $dataset->learn($network);
	print "Epoch = $counter error = $err\n";
	$counter++;
}

$network->run([0,0,0,0,0,1,0,1]);
my $output = $network->output();
print $output."\n";

foreach (@$output){print $_}
print "\n";

