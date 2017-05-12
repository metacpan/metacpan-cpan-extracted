package TestCGI::basic;
use strict;
use warnings;
use Apache::Test qw(-withtestmore);
use Apache::TestUtil;
use CGI::Apache2::Wrapper;
use Apache2::Const -compile => qw(OK SERVER_ERROR);
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::RequestUtil ();

my @methods = qw(param header url remote_addr
		 server_name server_port remote_host
		 auth_type remote_ident remote_user user_name
		 query_string server_protocol request_method
		 content_type path_info redirect status
		 cookie upload tmpFileName uploadInfo);
sub handler {
  my ($r) = @_;
  plan $r, tests => 4 + @methods;
  my $cgi = CGI::Apache2::Wrapper->new($r);
  isa_ok($cgi, 'CGI::Apache2::Wrapper');
  my $cgi_r = $cgi->r;
  isa_ok($cgi_r, 'Apache2::RequestRec');
  my $cgi_req = $cgi->req;
  isa_ok($cgi_req, 'Apache2::Request');
  foreach my $method (@methods) {
    can_ok($cgi, $method);
  }
  my $c = $cgi->cookie(-name    => 'foo',
		       -value   => 'bar',
		       -expires => '+3M',
		       -domain  => '.capricorn.com',
		       -path    => '/cgi-bin/database',
		       -secure  => 1
		      );
  isa_ok($c, 'CGI::Apache2::Wrapper::Cookie');
  return Apache2::Const::OK;
}

1;

__END__
