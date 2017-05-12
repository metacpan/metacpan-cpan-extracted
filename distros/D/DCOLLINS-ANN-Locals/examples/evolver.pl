#!/usr/bin/perl
use strict;
use warnings;

use DCOLLINS::ANN::Robot;
use DCOLLINS::ANN::SimWorld;
use Data::Dumper;

$w=new DCOLLINS::ANN::SimWorld; 
while (1) {
	$n=new DCOLLINS::ANN::Robot; 
	$r=$w->run_robot($n); 
	print Dumper($r);
}
