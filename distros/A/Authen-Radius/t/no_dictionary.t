use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok('Authen::Radius') };

my $r = Authen::Radius->new(Host => '127.0.0.1', Secret => 'secret', Debug => 0);
ok($r, 'object created');

# Name as ID but missing Type
$r->add_attributes(
    { Name => 1, Value => 'test' },
    { Name => 2, Value => 'test' },
);

is( scalar($r->get_attributes), 0, 'no attributes encoded');
ok( $r->send_packet(ACCESS_REQUEST), 'sent without attributes');
# diag $r->get_error;
# diag $r->error_comment;

