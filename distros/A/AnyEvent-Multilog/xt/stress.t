use strict;
use warnings;
use Test::More;
use AnyEvent::Multilog;
use EV;
use File::Slurp;
use Directory::Scratch;
use List::Util qw(reduce);

our ($a, $b); # i hate you all

my $tmp = Directory::Scratch->new;

my @words = read_file('/usr/share/dict/words');
chomp @words;

my $dest = $tmp->base->absolute;
diag $dest;

my $log = AnyEvent::Multilog->new(
    script  => [qw|t +* s10240 n100|, "$dest"],
    on_exit => sub { EV::unloop },
);

$log->start;

my $timer = AnyEvent->timer( after => 10, cb => sub { $log->shutdown } );

my $idle = AnyEvent->idle( cb => sub {
    $log->push_write(join ' ', map { $words[$_] } map { int rand scalar @words } 1..(int rand 100));
});

EV::loop();

my $count = $tmp->ls;
cmp_ok $count, '>=', 100, 'n100 -> at least 100 files';
cmp_ok $count, '<=', 103, 'no more than 103 files';

my $size = reduce { $a + $b } map { -s $dest->file($_) } $tmp->ls;
cmp_ok $size, '<', 110 * 10240, 'size is less than 110 10240 byte files';
cmp_ok $size, '>', 80  * 10240, 'size is more than 80 10240 byte files';

done_testing;
