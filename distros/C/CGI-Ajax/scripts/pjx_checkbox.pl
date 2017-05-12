#!/usr/bin/perl -w
use strict;
use CGI::Ajax;
use CGI;


my $perl_func = sub {
  my $input = shift;

  print "got $input";
}; 

sub Show_HTML {
  my $html = "";
  $html .= <<EOT;

<html>
<head><title>CGI::Ajax Example</title>
</head>
<body>
<form>
  <input type="checkbox" name="val1" id="val1" value="44" size="6" /> val1<br/>
  <input type='submit' onmouseover=jsFunc(['val1'],['out']); />
     
  <div id="out"> </div>
</body>
</html>
EOT

  return $html;
}

my $cgi = new CGI();  # create a new CGI object

my $pjx = new CGI::Ajax( 'jsFunc' => $perl_func );
$pjx->JSDEBUG(1);
$pjx->DEBUG(1);

print $pjx->build_html($cgi,\&Show_HTML); # this outputs the html for the page

