#!/usr/bin/perl -w
use strict;
use Test::More (tests => 2);

BEGIN
{
	use_ok('Chart::Gnuplot');
	use_ok('Chart::Gnuplot::Util');
}
