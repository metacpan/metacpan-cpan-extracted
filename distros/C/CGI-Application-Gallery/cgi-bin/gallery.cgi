#!/usr/bin/perl -w
use lib './lib';
use CGI::Application::Gallery;
use strict;

my $g = new CGI::Application::Gallery( 
   TMPL_PATH => './',
	PARAMS    => { rel_path_default => '/gallery' },
);
$g->run;


