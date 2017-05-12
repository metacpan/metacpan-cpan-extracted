#!/usr/bin/perl

use Test::More tests => 6;
use_ok("AI::NaiveBayes1");

require 't/auxfunctions.pl';

my $nb = AI::NaiveBayes1->new;

# Example from Witten I. and Frank E. book "Data Mining" (the WEKA
# book), page82
#
# @relation weather.symbolic
# 
# @attribute outlook {sunny, overcast, rainy}
# @attribute temperature {hot, mild, cool}
# @attribute humidity {high, normal}
# @attribute windy {TRUE, FALSE}
# @attribute play {yes, no}
# 
# @data
# sunny,hot,high,FALSE,no
# sunny,hot,high,TRUE,no
# overcast,hot,high,FALSE,yes
# rainy,mild,high,FALSE,yes
# rainy,cool,normal,FALSE,yes
# rainy,cool,normal,TRUE,no
# overcast,cool,normal,TRUE,yes
# sunny,mild,high,FALSE,no
# sunny,cool,normal,FALSE,yes
# rainy,mild,normal,FALSE,yes
# sunny,mild,normal,TRUE,yes
# overcast,mild,high,TRUE,yes
# overcast,hot,normal,FALSE,yes
# rainy,mild,high,TRUE,no

$nb->add_instance(attributes=>{outlook=>'sunny',temperature=>'hot',humidity=>'high',windy=>'FALSE'},label=>'play=no');
$nb->add_instance(attributes=>{outlook=>'sunny',temperature=>'hot',humidity=>'high',windy=>'TRUE'},label=>'play=no');
$nb->add_instance(attributes=>{outlook=>'overcast',temperature=>'hot',humidity=>'high',windy=>'FALSE'},label=>'play=yes');
$nb->add_instance(attributes=>{outlook=>'rainy',temperature=>'mild',humidity=>'high',windy=>'FALSE'},label=>'play=yes');
$nb->add_instance(attributes=>{outlook=>'rainy',temperature=>'cool',humidity=>'normal',windy=>'FALSE'},label=>'play=yes');
$nb->add_instance(attributes=>{outlook=>'rainy',temperature=>'cool',humidity=>'normal',windy=>'TRUE'},label=>'play=no');
$nb->add_instance(attributes=>{outlook=>'overcast',temperature=>'cool',humidity=>'normal',windy=>'TRUE'},label=>'play=yes');
$nb->add_instance(attributes=>{outlook=>'sunny',temperature=>'mild',humidity=>'high',windy=>'FALSE'},label=>'play=no');
$nb->add_instance(attributes=>{outlook=>'sunny',temperature=>'cool',humidity=>'normal',windy=>'FALSE'},label=>'play=yes');
$nb->add_instance(attributes=>{outlook=>'rainy',temperature=>'mild',humidity=>'normal',windy=>'FALSE'},label=>'play=yes');
$nb->add_instance(attributes=>{outlook=>'sunny',temperature=>'mild',humidity=>'normal',windy=>'TRUE'},label=>'play=yes');
$nb->add_instance(attributes=>{outlook=>'overcast',temperature=>'mild',humidity=>'high',windy=>'TRUE'},label=>'play=yes');
$nb->add_instance(attributes=>{outlook=>'overcast',temperature=>'hot',humidity=>'normal',windy=>'FALSE'},label=>'play=yes');
$nb->add_instance(attributes=>{outlook=>'rainy',temperature=>'mild',humidity=>'high',windy=>'TRUE'},label=>'play=no');

$nb->train;

my $printedmodel =  "Model:\n" . $nb->print_model;
$printedmodel = &shorterdecimals($printedmodel);

#putfile('t/3-1.out', $printedmodel);
&compare_by_line($printedmodel, 't/3-1.out', __FILE__, __LINE__);

#putfile('t/3-2.out', $nb->export_to_YAML());
#is($nb->export_to_YAML(), getfile('t/3-2.out'));

eval "require YAML;";
plan skip_all => "YAML module required for the remaining tests in 3.t" if $@;

$nb->export_to_YAML_file('t/tmp1');
my $nb1 = AI::NaiveBayes1->import_from_YAML_file('t/tmp1');
&compare_by_line("Model:\n" . &shorterdecimals($nb1->print_model),
		 't/3-1.out', __FILE__, __LINE__);

my $tmp = $nb->export_to_YAML();
my $nb2 = AI::NaiveBayes1->import_from_YAML($tmp);
&compare_by_line("Model:\n" . &shorterdecimals($nb2->print_model),
		 't/3-1.out', __FILE__, __LINE__);

my $p = $nb->predict(attributes=>{outlook=>'sunny',temperature=>'cool',humidity=>'high',windy=>'TRUE'});

#putfile('t/3-3.out', YAML::Dump($p));
ok(abs($p->{'play=no'}  - 0.795) < 0.001);
ok(abs($p->{'play=yes'} - 0.205) < 0.001);
