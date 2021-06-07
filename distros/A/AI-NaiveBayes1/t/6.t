#!/usr/bin/perl

use Test::More tests => 9;
use_ok("AI::NaiveBayes1");

use lib '.';
require 't/auxfunctions.pl';

my $nb = AI::NaiveBayes1->new;

$nb->add_instances(attributes=>{C=>'Y',F=>2},label=>'S=Y',cases=>30);
$nb->add_instances(attributes=>{C=>'Y',F=>2},label=>'S=N',cases=>10);
$nb->add_instances(attributes=>{C=>'Y',F=>0},label=>'S=Y',cases=>18);
$nb->add_instances(attributes=>{C=>'Y',F=>0},label=>'S=N',cases=>16);
$nb->add_instances(attributes=>{C=>'N',F=>2},label=>'S=Y',cases=>22);
$nb->add_instances(attributes=>{C=>'N',F=>2},label=>'S=N',cases=>14);
$nb->add_instances(attributes=>{C=>'N',F=>0},label=>'S=Y',cases=> 6);
$nb->add_instances(attributes=>{C=>'N',F=>0},label=>'S=N',cases=>84);

$nb->train;

my $printedmodel =  "Model:\n" . $nb->print_model;
$printedmodel = &shorterdecimals($printedmodel);

#putfile('t/6-1.out', $printedmodel);
&compare_by_line($printedmodel, 't/6-1.out', __FILE__, __LINE__);

eval "require YAML;";
plan skip_all => "YAML module required for the remaining tests in 6.t" if $@;

$nb->export_to_YAML_file('t/tmp6');
my $nb1 = AI::NaiveBayes1->import_from_YAML_file('t/tmp6');
&compare_by_line("Model:\n" . &shorterdecimals($nb1->print_model),
		 't/6-1.out', __FILE__, __LINE__);

my $p = $nb->predict(attributes=>{C=>'Y',F=>0});

#putfile('t/6-2.out', YAML::Dump($p));
ok(abs($p->{'S=N'} - 0.580) < 0.001);
ok(abs($p->{'S=Y'} - 0.420) < 0.001);

# Continual

$nb = AI::NaiveBayes1->new;

$nb->add_instances(attributes=>{C=>'Y',F=>2},label=>'S=Y',cases=>30);
$nb->add_instances(attributes=>{C=>'Y',F=>2},label=>'S=N',cases=>10);
$nb->add_instances(attributes=>{C=>'Y',F=>0},label=>'S=Y',cases=>18);
$nb->add_instances(attributes=>{C=>'Y',F=>0},label=>'S=N',cases=>16);
$nb->add_instances(attributes=>{C=>'N',F=>2},label=>'S=Y',cases=>22);
$nb->add_instances(attributes=>{C=>'N',F=>2},label=>'S=N',cases=>14);
$nb->add_instances(attributes=>{C=>'N',F=>0},label=>'S=Y',cases=> 6);
$nb->add_instances(attributes=>{C=>'N',F=>0},label=>'S=N',cases=>84);

$nb->set_real('F');
$nb->train;

$printedmodel =  "Model:\n" . $nb->print_model;
$printedmodel = &shorterdecimals($printedmodel);

#putfile('t/6-3.out', $printedmodel);
&compare_by_line($printedmodel, 't/6-3.out', __FILE__, __LINE__);

$nb->export_to_YAML_file('t/tmp6-2');
$nb1 = AI::NaiveBayes1->import_from_YAML_file('t/tmp6-2');

&compare_by_line("Model:\n" . &shorterdecimals($nb1->print_model),
		 't/6-3.out', __FILE__, __LINE__);

$p = $nb->predict(attributes=>{C=>'Y',F=>1});

#putfile('t/6-4.out', YAML::Dump($p));
ok(abs($p->{'S=N'} - 0.339) < 0.001);
ok(abs($p->{'S=Y'} - 0.661) < 0.001);
