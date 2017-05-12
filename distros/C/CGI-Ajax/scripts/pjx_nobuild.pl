#! /usr/bin/perl -w

use strict;
use CGI::Ajax;

my $my_func = sub {
  my $arg = shift;
  return ( $arg . " with some extra" );
};

my $pjx = new CGI::Ajax( 'tester' => $my_func );
$pjx->JSDEBUG(1);
$pjx->DEBUG(1);

use CGI;
my $cgi = new CGI();
print $cgi->header();

$pjx->cgi( $cgi );

my $html = "";
  $html .= "<HTML>";
  $html .= "<HEAD>";

  $html .= $pjx;

  $html .= <<EOT;
  </HEAD>
  <BODY>
  <FORM name="form">
  <INPUT type="text" id="inarg"
    onkeyup="tester(['inarg'],['output_div']); return true;">
  <hr>
  <div id="output_div"></div>
  </FORM>
  <br/><div id='pjxdebugrequest'></div><br/>
  </BODY>
  </HTML>
EOT

if ( not $cgi->param('fname') ) {
  print $html;
} else {
  print $pjx->handle_request();
}

