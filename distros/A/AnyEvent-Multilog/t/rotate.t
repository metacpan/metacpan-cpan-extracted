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
    script   => [qw/t +* s9999/, $logfile],
    on_exit  => sub { $done->send(\@_) },
);

isa_ok $log, 'AnyEvent::Multilog';

$log->start;

# wait for exec
my $wait = AnyEvent->condvar;
my $t = AnyEvent->timer( after => 1, cb => $wait );
$wait->recv;

my $state = 0;
$log->run->delegate('input_handle')->handle->on_drain(sub {
    if($state < 10){
        $log->rotate;
        $state++;
        $log->push_write("this is line $state");
    }
    elsif($state == 10) {
        $log->shutdown;
    }
});

my ($success, $msg, $status) = @{$done->recv || []};
ok $success, 'exited ok 1';
like $msg, qr/^normal exit/, 'normal exit';

ok $tmp->exists('foo/current'), 'has log';
my @files = $tmp->ls('foo');
cmp_ok((scalar grep { m{^foo/@} } @files), '>', 1,
    'got more than 1 @...s file');

done_testing;
