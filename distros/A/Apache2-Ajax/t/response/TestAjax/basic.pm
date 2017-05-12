package TestAjax::basic;
use strict;
use warnings;
use Apache::Test qw(-withtestmore);
use Apache::TestUtil;
use Apache2::Ajax;
use Apache2::Const -compile => qw(OK SERVER_ERROR);
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::RequestUtil ();

my $multiply = sub {
  my ($x, $y) = @_;
  return ($x * $y);
};

my $divide = sub {
  my ($x, $y) = @_;
  return ($x / $y);
};

my $sub_map = {js_add => \&add, js_subtract => \&subtract,
	      js_multiply => $multiply, js_divide => $divide};

sub handler {
  my ($r) = @_;
  plan $r, tests => 24;
  my $ajax = Apache2::Ajax->new($r, 
				'js_multiply' => $multiply,
				'js_divide' => $divide,
			       );
  isa_ok($ajax, 'Apache2::Ajax');
  for my $method(qw(build_html show_javascript)) {
    can_ok($ajax, $method);
  }
  my $cgi = $ajax->cgi;
  like(ref($cgi), qr{^CGI});
  my $self_r = $ajax->r;
  isa_ok($self_r, 'Apache2::RequestRec');
 SKIP: {
    eval {require CGI::Apache2::Wrapper;};
    skip "CGI::Apache2::Wrapper not installed", 3 if $@;
    isa_ok($cgi, 'CGI::Apache2::Wrapper');
    my $cgi_r = $cgi->r;
    isa_ok($cgi_r, 'Apache2::RequestRec');
    my $cgi_req = $cgi->req;
    isa_ok($cgi_req, 'Apache2::Request');
  }
  my $pjx = $ajax->pjx;
  isa_ok($pjx, 'CGI::Ajax');
  my $html = $ajax->html;
  isa_ok($html, 'CODE');
  my $url = $cgi->url;
  foreach my $func(qw(js_add js_subtract js_multiply js_divide)) {
    is($pjx->url_list->{$func}, $url, "\$pjx->url_list->{$func} is $url");
    my $sub = $pjx->coderef_list->{$func};
    isa_ok($sub, 'CODE');
    my $result = $sub_map->{$func}->(4, 2);
    is($sub->(4, 2), $result,
      "Verifying $func returns $result");
  }
  is ($pjx->JSDEBUG, 2, "JSDEBUG is 2");
  is ($pjx->DEBUG, 1, "DEBUG is 1");

  return Apache2::Const::OK;
}

sub add {
  my $value_a = shift;
  my $value_b = shift;
  return( $value_a + $value_b );
}

sub subtract {
  my $value_a = shift;
  my $value_b = shift;
  return( $value_a - $value_b );
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

PJX_fn js_add add
PJX_fn js_subtract subtract
PJX_html Show_Form
PJX_JSDEBUG 2
PJX_DEBUG 1

<Base>
  PerlLoadModule TestAjax::basic
</Base>


