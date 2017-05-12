#!/usr/bin/perl

use Test::More tests => 6;
use_ok("AI::NaiveBayes1");

require 't/auxfunctions.pl';

my $nb = AI::NaiveBayes1->new;

# Example from Witten I. and Frank E. book "Data Mining" (the WEKA
# book), page 86
#
# @relation weather
# 
# @attribute outlook {sunny, overcast, rainy}
# @attribute temperature real
# @attribute humidity real
# @attribute windy {TRUE, FALSE}
# @attribute play {yes, no}
# 
# @data
# sunny,85,85,FALSE,no
# sunny,80,90,TRUE,no
# overcast,83,86,FALSE,yes
# rainy,70,96,FALSE,yes
# rainy,68,80,FALSE,yes
# rainy,65,70,TRUE,no
# overcast,64,65,TRUE,yes
# sunny,72,95,FALSE,no
# sunny,69,70,FALSE,yes
# rainy,75,80,FALSE,yes
# sunny,75,70,TRUE,yes
# overcast,72,90,TRUE,yes
# overcast,81,75,FALSE,yes
# rainy,71,91,TRUE,no
#

$nb->set_real('temperature', 'humidity');

$nb->add_instance(attributes=>{outlook=>'sunny',temperature=>85,humidity=>85,windy=>'FALSE'},label=>'play=no');
$nb->add_instance(attributes=>{outlook=>'sunny',temperature=>80,humidity=>90,windy=>'TRUE'},label=>'play=no');
$nb->add_instance(attributes=>{outlook=>'overcast',temperature=>83,humidity=>86,windy=>'FALSE'},label=>'play=yes');
$nb->add_instance(attributes=>{outlook=>'rainy',temperature=>70,humidity=>96,windy=>'FALSE'},label=>'play=yes');
$nb->add_instance(attributes=>{outlook=>'rainy',temperature=>68,humidity=>80,windy=>'FALSE'},label=>'play=yes');
$nb->add_instance(attributes=>{outlook=>'rainy',temperature=>65,humidity=>70,windy=>'TRUE'},label=>'play=no');
$nb->add_instance(attributes=>{outlook=>'overcast',temperature=>64,humidity=>65,windy=>'TRUE'},label=>'play=yes');
$nb->add_instance(attributes=>{outlook=>'sunny',temperature=>72,humidity=>95,windy=>'FALSE'},label=>'play=no');
$nb->add_instance(attributes=>{outlook=>'sunny',temperature=>69,humidity=>70,windy=>'FALSE'},label=>'play=yes');
$nb->add_instance(attributes=>{outlook=>'rainy',temperature=>75,humidity=>80,windy=>'FALSE'},label=>'play=yes');
$nb->add_instance(attributes=>{outlook=>'sunny',temperature=>75,humidity=>70,windy=>'TRUE'},label=>'play=yes');
$nb->add_instance(attributes=>{outlook=>'overcast',temperature=>72,humidity=>90,windy=>'TRUE'},label=>'play=yes');
$nb->add_instance(attributes=>{outlook=>'overcast',temperature=>81,humidity=>75,windy=>'FALSE'},label=>'play=yes');
$nb->add_instance(attributes=>{outlook=>'rainy',temperature=>71,humidity=>91,windy=>'TRUE'},label=>'play=no');

$nb->train;

my $printedmodel =  "Model:\n" . $nb->print_model;
$printedmodel = &shorterdecimals($printedmodel);

#putfile('t/4-1.out', $printedmodel);
&compare_by_line($printedmodel, 't/4-1.out', __FILE__, __LINE__);

#putfile('t/4-2.out', $nb->export_to_YAML());
#is($nb->export_to_YAML(), getfile('t/4-2.out'));

eval "require YAML;";
plan skip_all => "YAML module required for the remaining tests in 4.t" if $@;

$nb->export_to_YAML_file('t/tmp1');
my $nb1 = AI::NaiveBayes1->import_from_YAML_file('t/tmp1');
&compare_by_line("Model:\n" . &shorterdecimals($nb1->print_model),
		 't/4-1.out', __FILE__, __LINE__);

my $tmp = $nb->export_to_YAML();
my $nb2 = AI::NaiveBayes1->import_from_YAML($tmp);
&compare_by_line("Model:\n" . &shorterdecimals($nb2->print_model),
		 't/4-1.out', __FILE__, __LINE__);

my $p = $nb->predict(attributes=>{outlook=>'sunny',temperature=>66,humidity=>90,windy=>'TRUE'});

#putfile('t/4-3.out', YAML::Dump($p));
ok(abs($p->{'play=no'}  - 0.792) < 0.001);
ok(abs($p->{'play=yes'} - 0.208) < 0.001);
