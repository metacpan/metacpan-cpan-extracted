package TestAjax::error_fn;
use strict;
use warnings;
use Apache2::Ajax;
use Apache2::Const -compile => qw(OK SERVER_ERROR);
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::RequestUtil ();
use Apache::Test;
use Apache::TestUtil;

sub handler {
  my ($r) = @_;
  t_server_log_error_is_expected();
  my $ajax = Apache2::Ajax->new($r) or return Apache2::Const::SERVER_ERROR;
  $r->print($ajax->build_html());
  return Apache2::Const::OK;
}

sub Show_Form {
  my $html = "";
  $html .= <<EOT;
<HTML>
<HEAD><title>CGI::Ajax Example</title>
</HEAD>
<BODY>
<form>
  Enter something:&nbsp;
  <input type="text" name="val1" id="val1" size="6" onkeyup="myfunc( ['val1','val2'], ['resultdiv'] );"><br>

  Enter something else:&nbsp;
  <input type="text" name="val2" id="val2" size="6" onkeyup="myfunc( ['val1','val2'], ['resultdiv'] );"><br>

    <hr>
    <div id="resultdiv" style="border: 1px solid black; width: 440px; height: 80px; overflow: auto">
    </div>
</form>
</BODY>
</HTML>
EOT
  return $html;
}


1;

__DATA__

PJX_html Show_Form
PJX_JSDEBUG 2
PJX_DEBUG 0

<Base>
  PerlLoadModule TestAjax::error_fn
</Base>
