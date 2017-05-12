#! /usr/bin/perl -w
use strict;
use CGI::Ajax;
use CGI;

my $q = new CGI;

my $concatter = sub {
  my $str = "All Values Are <br/>\n";
  map { $str .= ' and ' . $_ } @_;
  print STDERR $str;
  return $str;
};

my $Show_Form = sub {
  my $html = "";
  $html = <<EOT
<HTML>
<HEAD><title>CGI::Ajax Multiple Return Value Example</title>
</HEAD>
<BODY>
<form>
<input type="text" id="val1" size="6" value=2 ><br/>
<input type="text" id="val2" size="6" value=hello ><br/>
<input type='text' id='val3' size=6 value=34><br/>
<input type='text' id='val4' size=8 value='something'><br/>
<input type='text' id='val5' size=6 value='\$123.39'><br/>
<input type='text' id='val6' size=6 value='address'><br/>
<input type='text' id='val7' size=9 value='123 fake st'><br/>
<input type='text' id='val8' size=9 value='some input'><br/>
<input type='text' id='val9' size=9 value=another><br/>
<select id='fred'>
<option value='1234'>1234
<option value='abcd' SELECTED >abcd
<option value='zxyw'>zxyw
</select>
<br/>
<button onclick='jsFunc(formDump(),["out"]);return false' > Send In All Form Elements </button>
<div id="out">
</div>


</form>
</BODY>
</HTML>
EOT
;

  return $html;
};


my $pjx = CGI::Ajax->new( 'jsFunc' => $concatter);
$pjx->JSDEBUG(2);
$pjx->DEBUG(1);
print $pjx->build_html($q,$Show_Form); # this outputs the html for the page
