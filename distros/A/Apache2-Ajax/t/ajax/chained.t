########################################################################
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

my $module = 'TestAjax::chained';
my $path = Apache::TestRequest::module2path($module);

plan tests => 6;

my $res = GET "/$path";
ok t_cmp($res->code, 200, "Checking request was OK");
ok t_cmp $res->header('Content-Type'),
    qr{text/html}, 'Content-Type: made it';
my $content = $res->content;
ok t_cmp($content, qr{function multiply}, 
	"Checking presence of multiply");
ok t_cmp($content, qr{function divide}, 
	"Checking presence of divide");
ok t_cmp($content, qr{onkeyup}, 
	"Checking presence of onkeyup");
ok t_cmp($content, qr{pjxdebugrequest}, 
	"Checking presence of pjxdebugrequest");
