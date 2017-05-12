#!/usr/bin/perl

use CGI;
$cgi = CGI->new;
print $cgi->redirect("http://www.example.com/");
