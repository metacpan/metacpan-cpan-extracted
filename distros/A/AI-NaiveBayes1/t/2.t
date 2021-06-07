#!/usr/bin/perl

use Test::More tests => 6;
use_ok("AI::NaiveBayes1");

use lib '.';
require 't/auxfunctions.pl';

my $nb = AI::NaiveBayes1->new;

# @relation spam-b
#
# @attribute morning {Y,N}
# @attribute html    {Y,N}
# @attribute size1   {S,L}
# @attribute spam    {Y,N}
#
# @data
# Y, N, S, N
# N, Y, L, Y
# Y, Y, L, Y
# N, Y, S, Y
# N, N, S, N
# Y, Y, L, Y
# Y, Y, L, N
# N, Y, L, Y
# N, Y, L, Y
# N, Y, S, Y
# N, Y, S, Y
# N, Y, L, Y
# Y, Y, L, Y
# N, Y, L, Y
# Y, Y, L, Y
# N, Y, S, Y
# N, Y, S, Y
# Y, Y, L, Y
# Y, Y, S, Y
# N, N, S, Y

$nb->add_instance(attributes=>{morning=>'Y',html=>'N',size1=>'S'},label=>'spam=N');
$nb->add_instance(attributes=>{morning=>'N',html=>'Y',size1=>'L'},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'Y',html=>'Y',size1=>'L'},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'N',html=>'Y',size1=>'S'},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'N',html=>'N',size1=>'S'},label=>'spam=N');
$nb->add_instance(attributes=>{morning=>'Y',html=>'Y',size1=>'L'},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'Y',html=>'Y',size1=>'L'},label=>'spam=N');
$nb->add_instance(attributes=>{morning=>'N',html=>'Y',size1=>'L'},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'N',html=>'Y',size1=>'L'},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'N',html=>'Y',size1=>'S'},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'N',html=>'Y',size1=>'S'},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'N',html=>'Y',size1=>'L'},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'Y',html=>'Y',size1=>'L'},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'N',html=>'Y',size1=>'L'},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'Y',html=>'Y',size1=>'L'},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'N',html=>'Y',size1=>'S'},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'N',html=>'Y',size1=>'S'},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'Y',html=>'Y',size1=>'L'},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'Y',html=>'Y',size1=>'S'},label=>'spam=Y');
$nb->add_instance(attributes=>{morning=>'N',html=>'N',size1=>'S'},label=>'spam=Y');

$nb->train;

my $printedmodel =  "Model:\n" . $nb->print_model;
$printedmodel = &shorterdecimals($printedmodel);
#putfile('t/2-1.out', $printedmodel);
&compare_by_line($printedmodel, 't/2-1.out', __FILE__ , __LINE__);

#putfile('t/2-2.out', $nb->export_to_YAML());
#is($nb->export_to_YAML(), getfile('t/2-2.out'));

eval "require YAML;";
plan skip_all => "YAML module required for the remaining tests in 2.t" if $@;

$nb->export_to_YAML_file('t/tmp2');
my $nb1 = AI::NaiveBayes1->import_from_YAML_file('t/tmp2');
$printedmodel = "Model:\n" . $nb1->print_model;
$printedmodel = &shorterdecimals($printedmodel);
&compare_by_line($printedmodel, 't/2-1.out', __FILE__ , __LINE__);
#is("Model:\n" . $nb1->print_model, getfile('t/2-1.out'));

my $tmp = $nb->export_to_YAML();
my $nb2 = AI::NaiveBayes1->import_from_YAML($tmp);
$printedmodel = "Model:\n" . $nb2->print_model;
$printedmodel = &shorterdecimals($printedmodel);
&compare_by_line($printedmodel, 't/2-1.out', __FILE__ , __LINE__);
#is("Model:\n" . $nb2->print_model, getfile('t/2-1.out'));

my $p = $nb->predict(attributes=>{morning=>'Y',html=>'Y',size1=>'L'});

#putfile('t/2-3.out', YAML::Dump($p));
like($p->{'spam=N'}, qr/0\.0627/);
like($p->{'spam=Y'}, qr/0\.9372/);
