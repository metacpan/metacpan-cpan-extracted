#!/usr/bin/perl

use Test::More tests => 6;
use_ok("AI::NaiveBayes1");

use lib '.';
require 't/auxfunctions.pl';

my $nb = AI::NaiveBayes1->new;

# @relation spam
#
# @attribute morning {Y,N}
# @attribute html    {Y,N}
# @attribute size    real
# @attribute spam    {Y,N}
#
# @data
# Y, N, 408, N
# N, Y, 3353, Y
# Y, Y, 4995, Y
# N, Y, 1853, Y
# N, N, 732, N
# Y, Y, 4017, Y
# Y, Y, 3190, N
# N, Y, 2345, Y
# N, Y, 3569, Y
# N, Y, 559, Y
# N, Y, 1732, Y
# N, Y, 2042, Y
# Y, Y, 3893, Y
# N, Y, 3601, Y
# Y, Y, 2176, Y
# N, Y, 877, Y
# N, Y, 272, Y
# Y, Y, 2740, Y
# Y, Y, 514, Y
# N, N, 1321, Y

$nb->add_instance(attributes=>{morning=>'Y',html=>'N',size=>408},label=>'spam=N');
$nb->add_instance(attributes=>{morning=>'N',html=>'Y',size=>3353},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'Y',html=>'Y',size=>4995},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'N',html=>'Y',size=>1853},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'N',html=>'N',size=>732},label=>'spam=N');
$nb->add_instance(attributes=>{morning=>'Y',html=>'Y',size=>4017},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'Y',html=>'Y',size=>3190},label=>'spam=N');
$nb->add_instance(attributes=>{morning=>'N',html=>'Y',size=>2345},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'N',html=>'Y',size=>3569},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'N',html=>'Y',size=>559},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'N',html=>'Y',size=>1732},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'N',html=>'Y',size=>2042},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'Y',html=>'Y',size=>3893},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'N',html=>'Y',size=>3601},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'Y',html=>'Y',size=>2176},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'N',html=>'Y',size=>877},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'N',html=>'Y',size=>272},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'Y',html=>'Y',size=>2740},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'Y',html=>'Y',size=>514},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'N',html=>'N',size=>1321},label=>'spam=Y');

$nb->set_real('size');
$nb->train;

my $printedmodel =  "Model:\n" . $nb->print_model;
$printedmodel = &shorterdecimals($printedmodel);

#putfile('t/5-1.out', $printedmodel);
&compare_by_line($printedmodel, 't/5-1.out', __FILE__, __LINE__);

#putfile('t/5-2.out', $nb->export_to_YAML());
#is($nb->export_to_YAML(), getfile('t/5-2.out'));

eval "require YAML;";
plan skip_all => "YAML module required for the remaining tests in 5.t" if $@;

$nb->export_to_YAML_file('t/tmp5');
my $nb1 = AI::NaiveBayes1->import_from_YAML_file('t/tmp5');
&compare_by_line("Model:\n" . &shorterdecimals($nb1->print_model),
		 't/5-1.out', __FILE__, __LINE__);

my $tmp = $nb->export_to_YAML();
my $nb2 = AI::NaiveBayes1->import_from_YAML($tmp);
&compare_by_line("Model:\n" . &shorterdecimals($nb2->print_model),
		 't/5-1.out', __FILE__, __LINE__);

my $p = $nb->predict(attributes=>{morning=>'Y',html=>'Y',size=>4749});

#putfile('t/5-3.out', YAML::Dump($p));
ok(abs($p->{'spam=N'} - 0.043) < 0.001);
ok(abs($p->{'spam=Y'} - 0.957) < 0.001);
