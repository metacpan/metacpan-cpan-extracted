########################################################################
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

my $module = 'TestAjax::formdump';
my $path = Apache::TestRequest::module2path($module);

plan tests => 5;

my $res = GET "/$path";
ok t_cmp($res->code, 200, "Checking request was OK");
ok t_cmp $res->header('Content-Type'),
    qr{text/html}, 'Content-Type: made it';
my $content = $res->content;
ok t_cmp($content, qr{function jsFunc}, 
         "Checking presence of jsFunc");
ok t_cmp($content, qr{onclick}, 
         "Checking presence of onclick");
ok t_cmp($content, qr{pjxdebugrequest}, 
	"Checking presence of pjxdebugrequest");
