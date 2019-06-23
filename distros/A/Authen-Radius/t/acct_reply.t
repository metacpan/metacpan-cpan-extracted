use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok('Authen::Radius', qw(ACCOUNTING_RESPONSE)) };

my $r = Authen::Radius->new(Host => '127.0.0.1', Secret => 'secret', Debug => 0);
ok($r, 'object created');

# without any attributes
my $reply = $r->send_packet(ACCOUNTING_RESPONSE);
ok($reply);
# diag $r->get_error;
# diag $r->error_comment;
