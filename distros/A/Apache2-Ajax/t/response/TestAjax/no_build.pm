package TestAjax::no_build;
use strict;
use warnings;
use Apache2::Ajax;
use Apache2::Const -compile => qw(OK SERVER_ERROR);
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::RequestUtil ();

sub handler {
  my $r = shift;
  my $my_func = sub {
    my $arg = shift;
    return ( $arg . " with some extra" );
  };
  my $ajax = Apache2::Ajax->new($r, tester => $my_func);
  my $html = "";
  $html .= "<HTML>";
  $html .= "<HEAD>";

  $html .= $ajax->show_javascript;

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

  my $cgi = $ajax->cgi;
  my $pjx = $ajax->pjx;
  $cgi->header();

  if ( not $cgi->param('fname') ) {
    $r->print($html);
  }
  else {
    $r->print($pjx->handle_request());
  }
  return Apache2::Const::OK;
}


1;

__DATA__

PJX_JSDEBUG 2
PJX_DEBUG 0

<Base>
  PerlLoadModule TestAjax::no_build
</Base>
