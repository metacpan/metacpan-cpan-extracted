use strict;
use warnings;
use Test::More;
use Argon::Message;
use Argon qw(:commands);

use_ok('Argon::Dispatcher');
my $d = new_ok('Argon::Dispatcher');

$d->respond_to($CMD_PING, sub { 42 });

is($d->dispatch(Argon::Message->new(cmd => $CMD_PING)), 42, 'dispatch');

eval { $d->dispatch(Argon::Message->new(cmd => $CMD_ACK)) };
ok($@, 'dispatch croaks on unhandled command');

done_testing;
