#!/usr/bin/perl

use Test;
use Data::TimeSeries;
use Data::TimeSeries::ChronoKey;
use strict;
use Data::Dumper;
use strict;
BEGIN {plan test=>23}

#Create A time series
my $start =Data::TimeSeries::ChronoKey::new(Data::TimeSeries::ChronoKey::WEEK, "2004W48");
my $stop =Data::TimeSeries::ChronoKey::new(Data::TimeSeries::ChronoKey::WEEK, "2005W02");
my $timeSeries=Data::TimeSeries::new($start, 
            $stop,Data::TimeSeries::ChronoKey::WEEK,'{3,4,5,6,7,8,9,10}');
ok($timeSeries->getLength(), 8);

#Add a point at the very beginning
$timeSeries->addPoint(Data::TimeSeries::FIRST, 2);
ok($timeSeries->getLength(), 9);

#Add a point at the end
$timeSeries->addPoint(Data::TimeSeries::LAST, 12);
ok($timeSeries->getLength(), 10);

#Sum the points
my $total=0;
$timeSeries->seriesOperate(sub {$total+=$_;});
ok($total,66);

#Remove The last Point
$timeSeries->removePoint(Data::TimeSeries::LAST);
ok($timeSeries->getLength(), 9);

#Remove The First Point
$timeSeries->removePoint(Data::TimeSeries::FIRST);
ok($timeSeries->getLength(), 8);

#Sum the points
$total=0;
$timeSeries->seriesOperate(sub {$total+=$_;});
ok($total,52);

#create a copy and normalize it.
my $copy=$timeSeries->copy();
$copy->normalize();
$total=0;
$copy->seriesOperate(sub {$total+=$_;});
ok($total,1);

#Make sure original did not change.
$total=0;
$timeSeries->seriesOperate(sub {$total+=$_;});
ok($total,52);

#Test Resize
my $resized=$timeSeries->copy();
my $rstart =Data::TimeSeries::ChronoKey::new(Data::TimeSeries::ChronoKey::WEEK, "2004W45");
my $rstop =Data::TimeSeries::ChronoKey::new(Data::TimeSeries::ChronoKey::WEEK, "2004W51");
$resized->resize($rstart, $rstop);
$total=0;
$timeSeries->seriesOperate(sub {$total+=$_;});
ok($total,52);
ok($resized->getLength(), 7);

#Test Clip
$copy=$timeSeries->copy();
$rstart =Data::TimeSeries::ChronoKey::new(Data::TimeSeries::ChronoKey::WEEK, "2004W49");
$rstop =Data::TimeSeries::ChronoKey::new(Data::TimeSeries::ChronoKey::WEEK, "2005W02");
$copy->clip($rstart, $rstop);
$total=0;
$copy->seriesOperate(sub {$total+=$_;});
ok($total,49);
ok($copy->getLength(), 7);

#Test Stationize. (Index based on a certain date.
my $station =Data::TimeSeries::ChronoKey::new(Data::TimeSeries::ChronoKey::WEEK, "2004W50");
$copy->stationize($station);
$total=0;
$copy->seriesOperate(sub {$total+=$_;});
ok($total,9.8);
ok($copy->getLength(), 7);

#Test getStrDateArray. 

my $dateArr=$copy->getStrDateArray();
ok ($dateArr->[5],'1/3/2005');

#Test Remap
$copy=$timeSeries->copy();
$copy->remap(Data::TimeSeries::ChronoKey::DAY, Data::TimeSeries::SPREAD);
my $copytotal=0;
$copy->seriesOperate(sub {$copytotal+=$_;});
my $tstotal=0;
$timeSeries->seriesOperate(sub {$tstotal+=$_;});
ok($copytotal,$tstotal);
my $currlen=$copy->getCalcLen();
ok($currlen,56);


#TEST synchronize
$copy=$timeSeries->copy();
my $copy2=$resized->copy();

ok(Data::TimeSeries::synchronize($copy, $copy2),1);
$total=0;
$copy->seriesOperate(sub {$total+=$_;});
ok($total,6.0);
ok($copy->getLength(), 4);
$total=0;
$copy2->seriesOperate(sub {$total+=$_;});
ok($total,5.07692307692308);
ok($copy2->getLength(), 4);
