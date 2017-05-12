use Apache::ASP::CGI::Test;

use lib qw(t . ..);
use T;
use strict;

my $t = T->new;
my $r = Apache::ASP::CGI::Test->do_self(
					UseStrict => 1, 
					CookieDomain => 'apache-asp.com', 
					SecureSession => 1,
					CookiePath => '/eg/'
					);
my $header = $r->test_header_out;
my $body = $r->test_body_out;

my @cookie_tests = (
		    'Set-Cookie: test=cookie; path=/',
		    'Set-Cookie: test2=value; expires=Wed, 06 Nov 2002 21:52:30 GMT; path=/path/; domain=test.com; secure',
		    'Set-Cookie: test3=key1=value1&key2=value2; path=/',
		    'Set-Cookie: session-id=[0-9a-f]+; path=/eg/; domain=apache-asp.com; secure',
		    );

for my $cookie_test ( @cookie_tests ) {
#    $cookie_test =~ s/(\W)/$1/isg;
    $t->eok(($header =~ /$cookie_test/s) ? 1 : 0, "Cookies header test");
}

$t->eok($body =~ /^\s*1\.\.1\nok\s*$/ ? 1 : 0, "Body test");
$t->done;

__END__
<% 
$Response->{Cookies}{test} = "cookie";
$Response->{Cookies}{test2} = { 
    Value => 'value', 
    Path => "/path/", 
    Secure => 1,
    Expires => "Wed, 06 Nov 2002 21:52:30 GMT",
    Domain => 'test.com',
    };
$Response->Cookies("test3", "key1", "value1");
$Response->Cookies("test3", "key2", "value2");
$t->ok;
%>

