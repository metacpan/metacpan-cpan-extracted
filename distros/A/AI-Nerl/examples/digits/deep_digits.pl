#!/usr/bin/perl

use Modern::Perl;
use PDL;
use PDL::NiceSlice;
use PDL::IO::FITS;
use PDL::Constants 'E';
use lib 'lib';
use lib '../../lib';
use AI::Nerl;

use FindBin qw($Bin); 
chdir $Bin;

unless (-e "t10k-labels-idx1-ubyte.fits"){ die <<"NODATA";}
pull this data by running get_digits.sh
convert it to FITS by running idx_to_fits.pl
NODATA


my $images = rfits('t10k-images-idx3-ubyte.fits');
my $labels = rfits('t10k-labels-idx1-ubyte.fits');
my $y = identity(10)->range($labels->transpose)->sever;
say 't10k data loaded';

my $nerl = AI::Nerl->new(
   # type => image,dims=>[28,28],...
   scale_input => 1/256,
);

$nerl->init_network(l1 => 784, l3=>10, l2=>7);#method=batch,hidden=>12345,etc

my $prev_nerl = $nerl;
my $prev_cost = 10000;
my $passes=0;

for(1..3000){
   my @test = ($images(9000:9999)->sever,$y(9000:9999)->sever);
   my $n = int rand(8000);
   my $m = $n+499;
   my @train = ($images->slice("$n:$m")->copy, $y->slice("$n:$m")->copy);
   $nerl->train(@train,passes=>10);
   my ($cost, $nc) = $nerl->cost( @test );
   print "cost:$cost\n,num correct: $nc / 1000\n";
#   $nerl->network->show_neuron(1);
   $passes++;
   if ($cost < $prev_cost or $passes<10){
      $prev_cost = $cost;
      $prev_nerl = $nerl;
   } else { # use $nerl as basis for $nerl
      $passes=0;

      print "New layer!";
      $prev_cost = 1000;
      $nerl = AI::Nerl->new(
         basis => $prev_nerl,
         l2 => int(rand(12))+5,
      );
      $nerl->init_network();
      $prev_nerl = $nerl;
      #die $nerl->network->theta1->slice("1:2") . $nerl->network->theta2->slice("1:2");
   }


   #print "example output, images 0 to 4\n";
   #print "Labels: " . $y(0:4) . "\n";
   #print $nerl->run($images(0:4));
#   $nerl->network->show_neuron($_) for (0..4);

}

