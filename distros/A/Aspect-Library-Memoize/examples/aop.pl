#!/usr/bin/perl

use strict;
use warnings;
use Aspect;

aspect Memoize => call qr/^Calibrator::calibrate_color_\w+$/;
# regular memoize interface is:
#    memoize("Calibrator::calibrate_color_$_) for qw(RGB CYMK);

my $was_computed = 0;
my %colors = (
	RGB  => {red => [255, 0, 0], blue => [0, 0, 255]},
	CYMK => {cyan => [100, 0, 0, 0]},
);

my $acme  = Calibrator->new('acme');
my $zerox = Calibrator->new('zerox');

print "\nTrying [RGB:acme:red] twice\n";
calibrate('RGB' , 'red' , $acme);
calibrate('RGB' , 'red' , $acme);

print "\nTrying [RGB:zerox:red]\n";
calibrate('RGB' , 'red' , $zerox);

print "\nTrying [RGB:acme:blue]\n";
calibrate('RGB' , 'blue', $acme);

print "\nTrying [CYMK:acme:cyan] twice\n";
calibrate('CYMK', 'cyan', $acme);
calibrate('CYMK', 'cyan', $acme);

sub calibrate {
	my ($color_space, $color_name, $printer_model) = @_;
	my $sub_name = "calibrate_color_$color_space";
	my $color    = $colors{$color_space}->{$color_name};
	my @result   = $printer_model->$sub_name(@$color);
	print "\t". ($was_computed? 'Computed': 'Memoized'). " result: @result\n";
	$was_computed = 0;
}

# ----------------------------------------------------------------------------

package Calibrator;

sub new {
	bless { printer_model => pop }, shift;
}

# returns ink color calibrated for specific printer model, in RGB
sub calibrate_color_RGB {
	my ($self, $r, $g, $b) = @_;
	# do some long computation, changing $r $g and $b...
	$was_computed = 1;
	return ($r, $g, $b);
}

# returns ink color calibrated for specific printer model, in CYMK
sub calibrate_color_CYMK {
	my ($self, $c, $y, $m, $k) = @_;
	# do some long computation, changing $c $y $m and $k...
	$was_computed = 1;
	return ($c, $y, $m, $k);
}
