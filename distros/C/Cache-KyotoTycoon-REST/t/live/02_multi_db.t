use strict;
use warnings;
use Test::More;
use Test::TCP;
use File::Which;
use Cache::KyotoTycoon::REST;
use File::Temp;

my $ktserver = which('ktserver');
plan skip_all => 'ktserver is required for this test' unless $ktserver;

my $db0 = File::Temp->new(SUFFIX => '.kch', UNLINK => 0);
my $db1 = File::Temp->new(SUFFIX => '.kch', UNLINK => 0);

test_tcp(
    client => sub {
        my $port = shift;

        my $key = "hoge" . rand();
        my $r0 = Cache::KyotoTycoon::REST->new(port => $port, db => 0);
        my $r1 = Cache::KyotoTycoon::REST->new(port => $port, db => 1);

        is $r0->base, "http://127.0.0.1:$port/0/", 'base';
        is $r1->base, "http://127.0.0.1:$port/1/", 'base';

        $r0->put('foo' => 'yay');
        $r1->put('foo' => 'wow');
        is scalar($r0->get('foo')), 'yay';
        is scalar($r1->get('foo')), 'wow';

        eval { unlink $db0->filename };
        eval { unlink $db1->filename };
    },
    server => sub {
        my $port = shift;
        exec $ktserver, '-port', $port, $db0->filename, $db1->filename;
        die "cannot execute";
    },
);

done_testing;
