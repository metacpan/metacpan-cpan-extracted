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
    script   => [qw/t +* /, $logfile],
    on_exit  => sub { $done->send(\@_) },
);

isa_ok $log, 'AnyEvent::Multilog';

$log->start;
$log->push_write('hello there');
$log->push_write('this is a test');
$log->shutdown;

my ($success, $msg, $status) = @{$done->recv || []};
ok $success, 'exited ok 1';
is $msg, 'normal exit', 'got advice';

ok !$log->has_leftover_data, 'no leftover data';

my $logdir = $tmp->exists('foo');
ok $logdir, 'created log dir';
ok -d $logdir, 'is a dir';

my $cur = $tmp->exists('foo/current');
ok $cur, 'got current file';
ok -f $cur, 'current is a file';

my @lines = $tmp->read('foo/current');

is @lines, 2, 'got two lines';
like $lines[0], qr/^\@[a-f0-9]+ hello there$/, 'got first line';
like $lines[1], qr/^\@[a-f0-9]+ this is a test$/, 'got second line';

done_testing;
