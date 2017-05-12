########################################################################
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

my $module = 'TestAjax::subs';
my $path = Apache::TestRequest::module2path($module);

plan tests => 6;

my $res = GET "/$path";
ok t_cmp($res->code, 200, "Checking request was OK");
my $content = $res->content;
ok t_cmp($content, qr{function myfunc}, 
         "Checking presence of myfunc");
ok t_cmp($content, qr{onkeyup}, 
         "Checking presence of onkeyup");
ok t_cmp($content, qr{pjxdebugrequest}, 
	"Checking presence of pjxdebugrequest");
ok t_cmp $res->header('Content-Type'),
    'text/html; charset=utf-8',
    'Content-Type: made it';
ok t_cmp $res->header('X-err_header_out'),
    'err_headers_out',
    'X-err_header_out: made it';
