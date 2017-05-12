#! /usr/bin/perl -w

# this is an example script of how you would use coderefs to define
# your CGI::Ajax functions.
#
# NB The CGI::Ajax object must come AFTER the coderefs are declared.

use strict;
use CGI::Ajax;
use CGI;

my $q = new CGI;

my $exported_fx = sub {
  my $value_a = shift;
  my $iq = new CGI;
  my $a = $q->param('a');
  my $b = $q->param('b');
  my $test = $q->param('test');
  return( 
  'entered value was: ' . $value_a . 
  '<br/>a was: ' . $a . "..." .
  '<br/>b was: ' . $b . "..." .
  '<br/>test was: ' . $test . "..." 
  );
};


my $Show_Form = sub {
  my $html = "";
  $html .= <<EOT;
<HTML>
<HEAD><title>CGI::Ajax Example</title>
</HEAD>
<BODY>
<form>
this javascript object is sent in as an argument:
{'a':123,'b':345,'test':'123 Evergreen Terrace'}
<br/><br/>
  Enter something else:&nbsp;
  <input type="text" name="val1"  size="6" onkeyup="myfunc(
  ['val1',{'a':123,'b':345,'test':'123 Evergreen Terrace'} ], 'resultdiv' ); return true;"><br>

    <hr>
    <DIV id="resultdiv" style="border: 1px solid black; width: 440px; height: 80px; overflow: auto">
    </div>
</form>
</BODY>
</HTML>
EOT

  return $html;
};

my $pjx = CGI::Ajax->new( 'myfunc' => $exported_fx);
$pjx->JSDEBUG(2);
$pjx->DEBUG(2);
print $pjx->build_html($q,$Show_Form); # this outputs the html for the page

