#!/usr/bin/perl

use utf8;
use strict;
use Color::Calc::WWW;

binmode STDOUT, ':utf8:crlf';

my $col1 = '#EEE';
my $col2 = '#908';

my $bkg = $col1;
my $fg  = color_contrast(color_grey($bkg));

my $bk2 = $col2;
my $fg2 = color_contrast(color_grey($bk2));

print <<__EOF;
Content-Type: text/css; charset=utf-8

body		      {
			background:	$bkg;
			color:		$fg;
		      }

h1 		      {	
			background:	$bk2;
			color:		$fg2;
		      }
__EOF
