#! /usr/bin/perl -w

# this is an  script calls an external script and avoids caching: 
# NB The CGI::Ajax object must come AFTER the coderefs are declared.

use strict;
use CGI::Ajax;
use CGI;

my $q = new CGI;

my $Show_Form = sub {
  my $html = "";
  $html .= <<EOT;
<HTML><title>CGI::Ajax No_Cache Example</title>
<HEAD>
</HEAD>
<BODY>
<i>
If the same URL is requested, A browser may cache the result 
and return it without querying the requested URL. To avoid that, use
the 'NO_CACHE' keyword as a parameter in your javascript function.
</i><br/>
<form>
Click the button and a perl script 'pjx_NO_CACHE_callee.pl should
return the current time:<br/><br/>

<input type="button" id="b1" size="6" value='This will cache (in IE)' onclick="perl_script([], ['out1']);return false"><br/>

<input type="button" id="b2" size="6" value='This will NOT cache' onclick="perl_script(['NO_CACHE'], ['out1']);"><br/>

New Time:<input type=text id="out1">


</form>
</BODY>
</HTML>
EOT

  return $html;
};

my $pjx = CGI::Ajax->new( 'perl_script' => 'pjx_NO_CACHE_callee.pl');
$pjx->JSDEBUG(1);
$pjx->DEBUG(1);
print $pjx->build_html($q,$Show_Form); # this outputs the html for the page
