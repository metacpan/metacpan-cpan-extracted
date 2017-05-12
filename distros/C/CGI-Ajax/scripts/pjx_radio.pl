#! /usr/bin/perl -w
use strict;
use CGI::Ajax 0.57;
use CGI;

my $q = new CGI;  # need a new CGI object

# compose our list of functions to export to js
my %hash = ( 'myFunc'         => \&perl_func,);

my $pjx = CGI::Ajax->new( %hash ); # this is our CGI::Ajax object

$pjx->DEBUG(1);   # turn on debugging
$pjx->JSDEBUG(1); # turn on javascript debugging, which will place a
                  #  new div element at the bottom of our page showing
                  #  the asynchrously requested URL

print $pjx->build_html( $q, \&Show_HTML ); # this builds our html
                                           #  page, inserting js

# This subroutine is responsible for outputting the HTML of the web
# page. 
sub Show_HTML {
  my $html = <<EOT;
<HTML>
<HEAD><title>Radio Example</title>
</HEAD>
<BODY>
<form>
<DIV id="radiobuttons" onclick="myFunc( ['radio1'], ['result'] );"> 
<input TYPE="radio" ID="radio1" NAME="radio1" VALUE="red">red 
<input TYPE="radio" ID="radio1" NAME="radio1" VALUE="blue">blue 
<input TYPE="radio" ID="radio1" NAME="radio1" VALUE="yellow">yellow 
<input TYPE="radio" ID="radio1" NAME="radio1" VALUE="green">green 
</DIV> 
<div id='result'> </div>
</form>
</BODY>
</HTML>
EOT

  return($html);
}

# this is the exported function 
sub perl_func {
  $a = shift;
  return $a . " was selected"; 
}
