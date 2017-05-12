use strict;
use warnings;
use Test::More;
use AnyEvent::Multilog;
use Directory::Scratch;
use t::lib::multilog qw/check_multilog/;

my $path = check_multilog 0;
my $tmp = Directory::Scratch->new;
my $logfile = $tmp->base->subdir('foo')->absolute->stringify;

my $done = AnyEvent->condvar;
my $log = AnyEvent::Multilog->new(
    multilog => $path,
    script   => [qw/t +*/, $logfile],
    on_exit  => sub { $done->send(\@_) },
);

isa_ok $log, 'AnyEvent::Multilog';

$log->start;
$log->push_write('hello there') for 1..100;
$log->run->delegate('input_handle')->handle->{wbuf} = "<extra1>\n";
$log->push_write('end');
# XXX: this may be timing-dependent if there is a write watcher around
$log->run->delegate('input_handle')->handle->{wbuf} = 'extra';
$log->push_shutdown;

my ($success, $msg, $status) = @{$done->recv || []};
ok $success, 'exited ok 1';
like $msg, qr/leftover/, 'got advice';

ok $tmp->exists('foo/current'), 'has log';

ok $log->has_leftover_data, 'has some leftover data';
is $log->leftover_data, 'extra', 'got extra data';

done_testing;
