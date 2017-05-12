#!/usr/bin/perl

use Test::More tests => 4;
use_ok("AI::NaiveBayes1");

require 't/auxfunctions.pl';

my $nb = AI::NaiveBayes1->new;

$nb->add_instances(attributes=>{model=>'H',place=>'B'},label=>'repairs=Y',cases=>30);
$nb->add_instances(attributes=>{model=>'H',place=>'B'},label=>'repairs=N',cases=>10);
$nb->add_instances(attributes=>{model=>'H',place=>'N'},label=>'repairs=Y',cases=>18);
$nb->add_instances(attributes=>{model=>'H',place=>'N'},label=>'repairs=N',cases=>16);
$nb->add_instances(attributes=>{model=>'T',place=>'B'},label=>'repairs=Y',cases=>22);
$nb->add_instances(attributes=>{model=>'T',place=>'B'},label=>'repairs=N',cases=>14);
$nb->add_instances(attributes=>{model=>'T',place=>'N'},label=>'repairs=Y',cases=> 6);
$nb->add_instances(attributes=>{model=>'T',place=>'N'},label=>'repairs=N',cases=>84);

$nb->train;

my $printedmodel =  "Model:\n" . $nb->print_model;
$printedmodel = &shorterdecimals($printedmodel);
#putfile('t/1-1.out', $printedmodel);
&compare_by_line($printedmodel, 't/1-1.out');

#putfile('t/1-2.out', $nb->export_to_YAML());
#is($nb->export_to_YAML(), getfile('t/1-2.out'));

eval "require YAML;";
plan skip_all => "YAML module required for the remaining tests in 1.t" if $@;

$nb->export_to_YAML_file('t/tmp1');

my $nb1 = AI::NaiveBayes1->import_from_YAML_file('t/tmp1');

$printedmodel = &shorterdecimals($nb1->print_model);
#is("Model:\n" . $printedmodel, getfile('t/1-1.out'));
&compare_by_line("Model:\n" . $printedmodel, 't/1-1.out');

my $tmp = $nb->export_to_YAML();
my $nb2 = AI::NaiveBayes1->import_from_YAML($tmp);
$printedmodel = &shorterdecimals($nb2->print_model);
#is("Model:\n" . $printedmodel, getfile('t/1-1.out'));
&compare_by_line("Model:\n" . $printedmodel, 't/1-1.out');
