########################################################################
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

my $module = 'TestAutocomplete::names';
my $path = Apache::TestRequest::module2path($module);

plan tests => 9;

my $res = GET "/$path";
ok t_cmp($res->code, 200, "Checking request was OK");
ok t_cmp $res->header('Content-Type'),
    qr{text/html}, 'Content-Type: made it';
my $content = $res->content;
ok t_cmp($content, qr{parent.sendRPCDone}, 
	"Checking presence of parent.sendRPCDone");

$res = GET "/$path?qu=al;js=true";
ok t_cmp($res->code, 200, "Checking request was OK");
ok t_cmp $res->header('Content-Type'),
    qr{text/html}, 'Content-Type: made it';
$content = $res->content;
ok t_cmp($content, qr{sendRPCDone}, 
	"Checking presence of sendRPCDone");
ok t_cmp($content, qr{alice}, 
	"Checking that alice arrived");
ok t_cmp($content, qr{allen}, 
	"Checking that allen arrived");
ok t_cmp($content, qr{"42 is the answer"}, 
	"Checking that '42 is the answer' arrived");
