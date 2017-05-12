package TestCGI::misc;
use strict;
use warnings;
use Apache::Test;
use Apache::TestUtil;
use CGI;
use CGI::Apache2::Wrapper;
use Apache2::Const -compile => qw(OK SERVER_ERROR);
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::RequestUtil ();

sub handler {
  my ($r) = @_;
  $r->content_type('text/plain');
  my @methods = qw(server_name server_port remote_addr
		  query_string request_method auth_type remote_user
		  path_info server_protocol self_url url);
  my @url_options = qw(-full -base -absolute -path_info -relative -query);
  plan $r, tests => (3 + (scalar @methods) + (scalar @url_options) );
  my $cgi = CGI::Apache2::Wrapper->new($r);
  ok t_cmp(ref($cgi), 'CGI::Apache2::Wrapper');
  my $cgi_pm = CGI->new($r);
  ok t_cmp(ref($cgi_pm), 'CGI');
  foreach my $method(@methods) {
    ok t_cmp($cgi->$method, $cgi_pm->$method, "Testing $method")
  }
  foreach my $opt(@url_options) {
    ok t_cmp($cgi->url($opt => 1), 
	     $cgi_pm->url($opt => 1), "Testing url option $opt");
  }
  my %opts = map {$_ => 1} qw(-path_info -query);
  ok t_cmp($cgi->url(%opts), $cgi_pm->url(%opts), 
	   "Testing url options -path_info and -query");

  return Apache2::Const::OK;
}

1;

__END__
