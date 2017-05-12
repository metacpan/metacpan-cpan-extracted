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
$y *= 2;
$y -= 1;
say 't10k data loaded';

my $nerl = AI::Nerl->new(
   # type => image,dims=>[28,28],...
   scale_input => 1/256,
#   train_x => $images(0:99),
#   train_y => $y(0:99),
#   test_x => $images(8000:8999),
#   test_y => $y(8000:8999),
#   cv_x => $images(9000:9999),
#   cv_y => $y(9000:9999),
);

$nerl->init_network(l1 => 784, l3=>10, l2=>80,alpha=>.45);#method=batch,hidden=>12345,etc

for(1..300){
   my $n = int rand(8000);
   my $m = $n+999;
   my $ix = $images->slice("$n:$m");
   my $iy = $y->slice("$n:$m");
   $nerl->network->train($ix,$iy,passes=>5);
   my ($cost,$nc) =  $nerl->network->cost($images(9000:9999),$y(9000:9999));
   print "cost:$cost\n,num correct: $nc / 1000\n";
   print "example output, images 0 to 4\n";
   print "Labels: " . $y(0:4) . "\n";
   print $nerl->network->run($images(0:4));
   $nerl->network->show_neuron($_) for (0..4);
}

__END__
#my $label_targets = identity(10)->($labels);
my $id = identity(10);
$images = $images(10:11);
show784($images(0));
show784($images(1));
$labels = $labels(10:11);

my $out_neurons = grandom(28*28,10) * .01;
# http://ufldl.stanford.edu/wiki/index.php/Backpropagation_Algorithm
# http://www.stanford.edu/class/cs294a/sparseAutoencoder_2011new.pdf
for my $pass(1..3){
   my $delta = $out_neurons * 0;
   for my $i(0..$images->dim(0)-1){
      my $img = $images(($i));
      my $a =  sigmoid($out_neurons x $img->transpose); #(t,10)
      #arn $out_neurons x $img->transpose if $pass > 1;; #(t,10)
      $a = $a((0));
      my $label = $labels(($i));
      my $d= $id(($label)) - $a;
      $d = -$d * $a * (1-$a); #(t,10)
      $delta += $d->transpose x $img;
      if (rand() < 1.002){
         warn $d;
         warn $a;
         warn "$label -> " . $a->maximum_ind;
         say "\n"x 2;
      }
      if ($pass%250==0 and $i<5){
         warn $a;
         warn $d;
         warn "$label -> " . $a->maximum_ind;
      }
   }
   $delta /= $images->dim(0);
   $delta *= .2;
   $out_neurons -= $delta;
   if ($pass%200==0){
      warn $delta(100:104);
      warn $out_neurons(100:104);
   }  
   show784($delta(:,0));
   show784($delta(:,6));
   show784($delta(:,4));
}
#die join (',',$nncost->dims);
use PDL::Graphics2D;
sub show784{
   my $w = shift;
   $w = $w->squeeze;
   my $min = $w->minimum;
   $w -= $min;
   my $max = $w->maximum;
   $w /= $max;
   $w = $w->reshape(28,28);
   imag2d $w;
}
sub sigmoid{
   my $foo = shift;
   return 1/(1+E**-$foo);
}

sub logistic{
   #find sigmoid before calling this.
   #grad=logistic(sigmoid(foo))
   my $foo = shift;
   return $foo * (1-$foo);
}
