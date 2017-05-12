#!/usr/bin/perl

use common::sense;

use Text::Xslate;

# ----------------

my($tx) = Text::Xslate -> new
(
 input_layer => '',
 path        => './htdocs/assets/templates/app/office/cms',
);
my($context) = 'new';
my($param)   =
{
 error => 1,
 data  =>
 [
  {
	  td => 'one',
  },
  {
	  td => 'two',
  },
 ],
};

print $tx -> render('update.report.tx', $param);
