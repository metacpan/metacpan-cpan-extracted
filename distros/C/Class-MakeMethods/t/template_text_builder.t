#!/usr/bin/perl

use Test;
BEGIN { plan tests => 2 }

use Class::MakeMethods::Template::TextBuilder 'text_builder';

my $base_text = "You owe us AMOUNT. Please pay up!\n\n" . 
		"THREAT{SEVERITY}";
my @exprs = (
  "Dear NAME\n\n*",
  "*\n\n-- The Management",

  "\t\t\t\tDATE\n*",
  { 'DATE' => 'Tuesday, April 1, 2001' },
  
  { 'THREAT{}' => { 'good'=>'Please?', 'bad'=>'Or else!' } },
);

my $one = { 'NAME'=>'John', 'AMOUNT'=>'200 camels', 'SEVERITY'=>'bad' };
my $two = { 'NAME'=>'Dave', 'AMOUNT'=>'one elephant', 'SEVERITY'=>'good' };

my $m_one = "\t\t\t\tTuesday, April 1, 2001\n" . 
	    "Dear John\n\n" . 
	    "You owe us 200 camels. Please pay up!\n\n" . 
	    "Or else!" . 
	    "\n\n-- The Management";

my $m_two = "\t\t\t\tTuesday, April 1, 2001\n" . 
	    "Dear Dave\n\n" . 
	    "You owe us one elephant. Please pay up!\n\n" . 
	    "Please?" . 
	    "\n\n-- The Management";

my $l_one = text_builder( $base_text, @exprs, $one );

my $l_two = text_builder( $base_text, @exprs, $two );

ok($l_one, $m_one);

ok($l_two, $m_two);

exit 0;
