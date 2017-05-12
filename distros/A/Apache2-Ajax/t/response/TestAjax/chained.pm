package TestAjax::chained;
use strict;
use warnings;
use Apache2::Ajax;
use Apache2::Const -compile => qw(OK SERVER_ERROR);
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::RequestUtil ();

my $multiply =  sub {
  my $a = shift;
  my $b = shift;
  return $a * $b;
};

my $divide = sub {
  my $a = shift;
  my $b = shift;
  return $a / $b;
};

my $Show_Form = sub {
  my $html = "";
  $html .= <<EOT;
<HTML>
<HEAD><title>CGI::Ajax Chained function Example</title>
</HEAD>
<BODY>
<form>
  Enter Number:
<input type="text" id="val1" size="6" value=2 
    onkeyup="divide(['val1','val2'], ['out1']); multiply(['val1','val2'], ['out2']);">

<input type="text" id="val2" size="6" value = 7
    onkeyup="divide(['val1','val2'], ['out1']); multiply(['val1','val2'], ['out2']);"><br/><br/>

<input type=text id="out1">
<input type=text id="out2">


</form>
</BODY>
</HTML>
EOT
  return $html;
};

sub handler {
  my ($r) = @_;
  my $ajax = Apache2::Ajax->new($r, 
				multiply => $multiply,
				divide => $divide);
  $r->print($ajax->build_html(html => $Show_Form));
  return Apache2::Const::OK;
}

1;

__DATA__

PJX_JSDEBUG 2
PJX_DEBUG 0

<Base>
  PerlLoadModule TestAjax::chained
</Base>
