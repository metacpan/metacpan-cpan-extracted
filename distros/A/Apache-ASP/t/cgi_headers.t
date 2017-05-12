use Apache::ASP::CGI::Test;
use lib qw(t ../t);
use T;

my $r = Apache::ASP::CGI::Test->do_self(NoState => 1, CgiHeaders => 1, Debug => 0);

my $t = T->new;
my $ok;

$t->eok($ok = $r->test_header_out =~ /Status: 200\n/s, "response header");
$t->eok($ok = $r->test_body_out =~ /^1..1\nok\s+$/s, "response body");
$t->done;

__END__
Status: 200

<% 

$t->ok;

%>

