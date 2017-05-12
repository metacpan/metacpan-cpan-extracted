package TestAjax::subs;
use strict;
use warnings;
use Apache2::Ajax;
use Apache2::Const -compile => qw(OK SERVER_ERROR);
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::RequestUtil ();

sub handler {
  my ($r) = @_;
  my $header = {'Content-Type' => 'text/html; charset=utf-8',
		'X-err_header_out' => 'err_headers_out',
	       };
  my $ajax = Apache2::Ajax->new($r);
  $r->print($ajax->build_html(header => $header));
  return Apache2::Const::OK;
}

sub exported_fx {
  my $value_a = shift;
  my $value_b = shift;
  $value_a = "" if not defined $value_a; # make sure there's def
  $value_b = "" if not defined $value_b; # make sure there's def

  if ( $value_a =~ /\D+/ or $value_a eq "" ) {
    return( $value_a . " and " . $value_b );
  } elsif ( $value_b =~ /\D+/ or $value_b eq "" ) {
    return( $value_a . " and " . $value_b );
  } else {
    # got two numbers, so lets multiply them together
    return( $value_a * $value_b );
  }
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

PJX_fn myfunc exported_fx
PJX_html Show_Form
PJX_JSDEBUG 2
PJX_DEBUG 0

<Base>
  PerlLoadModule TestAjax::subs
</Base>
