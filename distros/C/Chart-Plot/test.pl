
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "Beginning tests 1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Chart::Plot;
$loaded = 1;
print "Ok 1: loaded module Chart::Plot version $Chart::Plot::VERSION.\n";

 
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $report;
eval {
  my $img = Chart::Plot->new;
  $report = "You have GD version $GD::VERSION.\n\tIt supports these image formats: ";
  for ($img->image_type()) { $report .= " $_"; }
};
$_ = ($@ ? "Not ok 2: $@" : "Ok 2: $report.\n");
print;

my @extensions;
my ($GDobject, $black, $white);

eval {
  my $img = Chart::Plot->new(400,400); 
  my @data = qw( -3 9   -2 4   -1 1   0 0   1 1  2 4  3 9);
  $img->setData (\@data) or die ( $img->error() );
  $img->setGraphOptions ('title' => 'Test Title',
                          'horAxisLabel' => 'X axis',
                          'vertAxisLabel' => 'Y axis'); 
  @extensions = $img->image_type();
  for (@extensions) {
    open (WR,">test.$_") or die ("Failed to write file: $!");
    binmode WR;
    if ($#extensions) { # multiple image types
      print WR $img->draw($_);
    } else {
      print WR $img->draw();
    }
    close WR;

    # erase the image, fill it with white, leaving the black border
    ($GDobject, $black, $white) = $img->getGDobject();
    $GDobject->filledRectangle(1,1,398,398,$white);
    
  }
};

$report = 'Ok 3: created test.' 
  . join(' test.', @extensions) 
  . ". You should check it or them.\n";
$_ = $@ ? "Not ok 3: $@" : $report;
print;


__END__

# older tests no longer used

eval {
  my $img = Chart::Plot->new(500,400); 
  my @xdata = -10..10;
  my @ydata = map $_**3, @xdata;
  $img->setData (\@xdata, \@ydata, 'red nolines points') 
    or die ( $img->error() );
  $img->setGraphOptions ('title' => 'Test B: Y = X**3',
                          'horGraphOffset' => 40,
                          'vertGraphOffset' => 20);
  $extension = $img->image_type();
  open (WR,">testb.$extension") or die ("Failed to write file: $!");
  binmode WR;
  print WR $img->draw();
  close WR;
};
$_ = $@ ? "Not ok 4: $@" : "Ok 4: created testb.$extension\n";;
print;

eval {
  my $img = Chart::Plot->new; 
  my @data = qw(1 1  2 2  3 3);
  $img->setData (\@data, 'lines nopoints') or die ( $img->error() );

  my %xTickLabels = qw (1 One 2 Two 3 Three);
  my %yTickLabels = qw (1 Jan 2 Feb 3 Mar);
  $img->setGraphOptions ('xTickLabels' => \%xTickLabels,
			 'yTickLabels' => \%yTickLabels)
    or die ($img->error);

  my $gd = $img->getGDobject();
  my ($gd, $black, $white, $red, $green, $blue) 
    = $img->getGDobject();
  my ($px,$py); 
  for (my $i=0; $i<$#data; $i+=2) {
    ($px,$py) = $img->data2pxl ($data[$i], $data[$i+1]);
    $gd->arc($px,$py,15,15,0,360,$green);
    }

  $extension = $img->image_type();
  open (WR,">testc.$extension") or die ("Failed to write file: $!");
  binmode WR;
  print WR $img->draw();
  close WR;
};
$_ = $@ ? "Not ok 5: $@" : "Ok 5: created testc.$extension\n";;
print;

