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
my $G = 'asdf';
my $Show_Form = sub {
  my $html = "";
  $html .= qq!
<HTML>
<HEAD><title>CGI::Ajax Multiple Return Value Example</title>
<script>
  my_call = function(){
   document.getElementById('out1').value = arguments[0];
   call_2();
   document.getElementById('out3').innerHTML = this.url;
  }
  call_2 =function(){
   multiply(['val1','val2'],['out2'],'POST');
  }

</script>
</HEAD>
<BODY>
<form>
  Enter Number:
<input type="text" id="val1" size="6" value=2 
    onkeyup="divide(['val1','val2','args__$G'], [my_call], 'POST');">
<input type='text' id='val2' size=6 value=34>

<input type=text id="out1">
<input type=text id="out2"><br/>
URL FROM "this" in callback:<div id="out3"> </div>


</form>
</BODY>
</HTML>
!;

  return $html;
};


my $pjx = CGI::Ajax->new( 'multiply' => $multiply, 'divide' => $divide);
$pjx->JSDEBUG(1);
$pjx->DEBUG(1);
print $pjx->build_html($q,$Show_Form); # this outputs the html for the page
