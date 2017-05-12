#! /usr/bin/perl -w

# this is an example script of how you would use URLs to define
# your CGI::Ajax functions.

use strict;
use CGI::Ajax;
use CGI;

my $q = new CGI;

# the format here implies that 'convert_degrees.pl' is at the same
# level in the web server's document root as this script.
my $pjx = CGI::Ajax->new( 'myfunc' => 'convert_degrees.pl');
$pjx->JSDEBUG(1);

my $Show_Form = sub {
  my $html = "";
  $html .= <<EOT;
<HTML>
<HEAD><title>CGI::Ajax Outside URL Example</title>
</HEAD>
<BODY>
<form>
  Degrees Centigrade:&nbsp;
  <input type="text" name="val1" id="val1" size="6"
    onkeyup="myfunc( ['Centigrade__' + getVal('val1')], ['val2'] );
    return true;">
  <br/>

  Degrees Kelvin:&nbsp;
  <input type="text" name="val2" id="val2" size="6"
    onkeyup="myfunc( ['Kelvin__' + getVal('val2')], ['val1'] );
    return true;">
</form>
</BODY>
</HTML>
EOT

  return $html;
};

print $pjx->build_html($q,$Show_Form); # this outputs the html for the page
