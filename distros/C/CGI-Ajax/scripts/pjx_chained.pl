#! /usr/bin/perl -w

# pjx_chained.pl: Multiple exported perl subs, and the exported
# functions are chained to an event, like this...
# onclick="func1(['in1'],['out1']); func2(['in1'],['out2']);"

use strict;
use CGI::Ajax;
use CGI;

my $q = new CGI;

my $multiply = sub {
  my $a = shift;
  my $b = shift;
  return $a * $b;
};

my $divide = sub {
  my $a = shift;
  my $b = shift;
  return $a / $b;
};

my $Show_Form = sub {
  my $html = "";
  $html .= <<EOT;
<HTML>
<HEAD><title>CGI::Ajax Chained function Example</title>
</HEAD>
<BODY>
<form>
  Enter Number:
<input type="text" id="val1" size="6" value=2 
    onkeyup="divide(['val1','val2'], ['out1']); multiply(['val1','val2'], ['out2']);">

<input type="text" id="val2" size="6" value = 7
    onkeyup="divide(['val1','val2'], ['out1']); multiply(['val1','val2'], ['out2']);"><br/><br/>

<input type=text id="out1">
<input type=text id="out2">


</form>
</BODY>
</HTML>
EOT
  return $html;
};

my $pjx = CGI::Ajax->new( 'multiply' => $multiply, 'divide' => $divide);
$pjx->JSDEBUG(1);
$pjx->DEBUG(1);
print $pjx->build_html($q,$Show_Form); # this outputs the html for the page
