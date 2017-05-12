package TestAjax::formdump;
use strict;
use warnings;
use Apache2::Ajax;
use Apache2::Const -compile => qw(OK SERVER_ERROR);
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::RequestUtil ();

sub concatter {
  my $str = "All Values Are <br/>\n";
  map { $str .= ' and ' . $_ } @_;
#  print STDERR $str;
  return $str;
};

sub Show_Form {
  my $html = "";
  $html = <<EOT;
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


sub handler : method {
  my ($self, $r) = @_;
  my $ajax = Apache2::Ajax->new($r);
  $r->print($ajax->build_html());
  return Apache2::Const::OK;
}


1;

__DATA__

PJX_fn jsFunc concatter
PJX_html Show_Form
PJX_JSDEBUG 2
PJX_DEBUG 0

<Base>
  PerlLoadModule TestAjax::formdump
</Base>

