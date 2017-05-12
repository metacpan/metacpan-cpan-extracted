#! /usr/bin/perl -w

# this is an example script of how you would use coderefs to define
# your CGI::Ajax functions, and the methods return multiple results to
# the page
#
# NB The CGI::Ajax object must come AFTER the coderefs are declared.

use strict;
use CGI::Ajax;
use CGI;

my $q = new CGI;

my $divide = sub {
  my $a = shift;
  my $b = shift;
  return ($a / $b,"this is 2nd return value");
};

my $Show_Form = sub {
  my $html = "";
  $html .= <<EOT;
<HTML>
<HEAD><title>CGI::Ajax Multiple Return Value Example</title>
<script>
  my_call = function(){
   document.getElementById('out1').value = arguments[0];
   document.getElementById('out2').value = arguments[1];
  }
</script>
</HEAD>
<BODY>
<form>
  Enter Number:
<input type="text" id="val1" size="6" value=2 onkeyup="divide(['val1','val2'], [my_call]);">
<input type='text' id='val2' size=6 value=34 onkeyup="divide(['val1','val2'],[my_call]);">

<input type=text id="out1" value ="">
<input type=text id="out2" value ="">


</form>
</BODY>
</HTML>
EOT

  return $html;
};

my $pjx = CGI::Ajax->new('divide' => $divide);
$pjx->JSDEBUG(1);
$pjx->DEBUG(1);
print $pjx->build_html($q,$Show_Form); # this outputs the html for the page
