#!/usr/bin/env perl
use strict; use warnings;
use Test::Simple tests=>17;

use App::AFNI::SiemensPhysio;
use feature 'say';

# we dont export these functions, but still want to save some finger work/screen space
sub getMRAcqSecs { App::AFNI::SiemensPhysio::getMRAcqSecs(@_) };
sub timeCheck    { App::AFNI::SiemensPhysio::timeCheck(@_)};
sub timeToSamples{ App::AFNI::SiemensPhysio::timeToSamples(@_) };
sub sandwichIdx  { App::AFNI::SiemensPhysio::sandwichIdx(@_) };

# check that we convert dicom to seconds succesfully
ok(getMRAcqSecs('000000.0010') == .001);
ok(getMRAcqSecs('000001.0000') == 1);
ok(getMRAcqSecs('000100.0000') == 60);
ok(getMRAcqSecs('010000.0000') == 60*60);
ok(getMRAcqSecs('165043.097500') == 60643.0975 );

# check timecheck
#my ($start,$end,$n,$tau) = @_;
ok( timeCheck(0,1,1,1)   ,  "time check");
ok( timeCheck(1,100,50,2), "time check" );
ok( ! eval { timeCheck(1,100,50,5) }, "bad time check: 50 sampels at 5 should be 250" ); 

# timeToSamples = how many samples in a given time
# my ($start, $end, $rate) = @_;
ok(timeToSamples(0,10,1)==10,           "time samples" );
ok(timeToSamples(1,10,.5)==18,          "time samples r<1" );
ok(timeToSamples( .5 , 5   , .25 )==18, "time samples s<1" );
ok(timeToSamples( .62, 5   , .25 )==18, "time samples start low" );
ok(timeToSamples( .63, 5   , .25 )==17, "time samples start high" ); 
ok(timeToSamples( .5 , 5.12, .25 )==18, "time samples end low" );
ok(timeToSamples( .5 , 5.13, .25 )==19, "time samples end high" );

# sandwich indexing
# sub sandwichIdx {  my ($bread, $meat, $n, $r) = @_;
# returns start and end
my ($s,$e) = sandwichIdx([0,100],[10,50], 50, 2);
ok( $s  == 5, "sandwitch simple: start"  );
ok( $e  == 25, "sandwitch simple: end"  );

