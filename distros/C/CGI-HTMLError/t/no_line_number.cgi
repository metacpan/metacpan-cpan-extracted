#!/usr/bin/perl
use blib;
use CGI::HTMLError;

die_now(1);

sub die_now {
	die "Another perfectly safe warning\n";
}


