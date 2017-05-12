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

my $exported_fx = sub {
  my $value_a = shift;
  my $value_b = shift;
  $value_a = "" if not defined $value_a; # make sure there's def
  $value_b = "" if not defined $value_b; # make sure there's def

  if ( $value_a =~ /\D+/ or $value_a eq "" ) {
    return( $value_a, $value_b, 'NaN' );
  } elsif ( $value_b =~ /\D+/ or $value_b eq "" ) {
    return( $value_a, $value_b, 'NaN' );
  } else {
    # got two numbers, so lets multiply them together
    return( $value_a, $value_b, $value_a * $value_b );
  }
};


my $Show_Form = sub {
  my $html = "";
  $html .= <<EOT;
<HTML>
<HEAD><title>CGI::Ajax Multiple Return Value Example</title>
</HEAD>
<BODY>
<form>
  Enter something:&nbsp;
  <input type="text" name="val1" id="val1" size="6" onkeyup="myfunc( ['val1','val2'], ['inputa','inputb','resultdiv'] ); return true;"><br>

  Enter something else:&nbsp;
  <input type="text" name="val2" id="val2" size="6" onkeyup="myfunc( ['val1','val2'], ['inputa','inputb','resultdiv'] ); return true;"><br>

    <hr>
    <table>
      <tr>
        <td>Input A</td>
        <td>Input B</td>
        <td>Result</td>
      </tr>
      <tr>
        <td>
          <div id="inputa" style="text-align: center; border: 1px solid black; width: 80px; height: 20px; overflow: auto"></div>
        </td>
        <td>
          <div id="inputb" style="text-align: center; border: 1px solid black; width: 80px; height: 20px; overflow: auto"></div>
        </td>
        <td>
          <div id="resultdiv" style="text-align: center; border: 1px solid black; width: 80px; height: 20px; overflow: auto"></div>
        </td>
      </tr>
    </table>
</form>
</BODY>
</HTML>
EOT

  return $html;
};

my $pjx = CGI::Ajax->new( 'myfunc' => $exported_fx);
$pjx->JSDEBUG(1);
print $pjx->build_html($q,$Show_Form); # this outputs the html for the page
