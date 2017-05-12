package Does_It_Work;

use Apache2::RequestRec ();
use Apache2::ServerRec  ();
use Apache2::RequestIO  ();
use Apache2::DebugLog   ();

use Apache2::Const  -compile => qw(OK);
use Apache::Test qw(-withtestmore);

sub handler {
    my $r = shift;
    plan $r, tests => 4;
    $r->log_debug('foo', 3, 'omg teh debug!');
    ok(1, "request log normal");
    $r->log_debugf('bar', 9, 'omg teh %s sprintf!', 'debug');
    ok(2, "request log formatted");
    $r->server->log_debug('foo', 3, 'omg teh debug!');
    ok(3, "server log formatted");
    $r->server->log_debugf('bar', 9, 'omg teh %s sprintf!', 'debug');
    ok(4, "server log formatted");

    Apache2::Const::OK;
}

1;
