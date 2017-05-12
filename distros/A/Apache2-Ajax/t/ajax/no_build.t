########################################################################
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

my $module = 'TestAjax::no_build';
my $path = Apache::TestRequest::module2path($module);

plan tests => 5;

my $res = GET "/$path";
ok t_cmp($res->code, 200, "Checking request was OK");
ok t_cmp $res->header('Content-Type'),
    qr{text/html}, 'Content-Type: made it';
my $content = $res->content;
ok t_cmp($content, qr{function tester}, 
         "Checking presence of tester");
ok t_cmp($content, qr{onkeyup}, 
         "Checking presence of onkeyup");
ok t_cmp($content, qr{pjxdebugrequest}, 
	"Checking presence of pjxdebugrequest");
