########################################################################
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

my $module = 'TestAutocomplete::names_header';
my $path = Apache::TestRequest::module2path($module);

plan tests => 11;

my $res = GET "/$path";
ok t_cmp($res->code, 200, "Checking request was OK");
ok t_cmp $res->header('Content-Type'),
    'text/html; charset=utf-8',
    'Content-Type: made it';
ok t_cmp $res->header('X-err_header_out'),
    'err_headers_out',
    'X-err_header_out: made it';
my $content = $res->content;
ok t_cmp($content, qr{parent.sendRPCDone}, 
	"Checking presence of parent.sendRPCDone");

$res = GET "/$path?qu=ja;js=true";
ok t_cmp($res->code, 200, "Checking request was OK");
ok t_cmp $res->header('Content-Type'),
    'text/html; charset=utf-8',
    'Content-Type: made it';
ok t_cmp $res->header('X-err_header_out'),
    'err_headers_out',
    'X-err_header_out: made it';
$content = $res->content;
ok t_cmp($content, qr{sendRPCDone}, 
	"Checking presence of sendRPCDone");
ok t_cmp($content, qr{jane}, 
	"Checking that janice arrived");
ok t_cmp($content, qr{janice}, 
	"Checking that janice arrived");
ok t_cmp($content, qr{"42 is the answer"}, 
	"Checking that '42 is the answer' arrived");
