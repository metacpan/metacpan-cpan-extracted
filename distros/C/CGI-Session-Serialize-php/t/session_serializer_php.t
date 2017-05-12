use strict;
use warnings;

use Test::More;
use CGI::Session;

my $session = CGI::Session->new('serializer:php;id:md5', undef) or die CGI::Session->errstr;

plan tests => 8;
ok($session, 'Session object created successfully');
ok($session->id, 'ID created successfully');
ok(!$session->is_empty, 'Session is not empty');
ok(!$session->is_expired, 'Session is not expired');
ok($session->ctime && $session->atime, 'ctime & atime are set');
ok($session->atime == $session->ctime, 'ctime == atime');
ok($session->id, 'session id is ' . $session->id);

# Arrays are converted to Hashes. PHP array handling leaves a ot to be desired.
$session->param(-name=>'emails', -value=>['ted.mechanic@sample.org', 'ted.mechanic@sample.org']);

my $sid = $session->id;
$session->flush();

$session = CGI::Session->load('serializer:php;id:md5', $sid);

ok(ref($session->param('emails')) eq 'HASH', "'emails' array converted to a hash" );