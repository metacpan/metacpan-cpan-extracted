package TestCGI::use_cgi_pm;
use strict;
use warnings;
use Apache::Test qw(-withtestmore);
use Apache::TestUtil;
use CGI::Apache2::Wrapper;
use Apache2::Const -compile => qw(OK SERVER_ERROR);
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::RequestUtil ();

BEGIN {
  $ENV{USE_CGI_PM} = 1;
};

sub handler {
  my ($r) = @_;
  plan $r, tests => 2;
  my $cgi = CGI::Apache2::Wrapper->new($r);
  isa_ok($cgi, 'CGI');
  my $c = $cgi->cookie(-name    => 'foo',
		       -value   => 'bar',
		       -expires => '+3M',
		       -domain  => '.capricorn.com',
		       -path    => '/cgi-bin/database',
		       -secure  => 1
		      );
  isa_ok($c, 'CGI::Cookie');
  return Apache2::Const::OK;
}

1;

__END__
