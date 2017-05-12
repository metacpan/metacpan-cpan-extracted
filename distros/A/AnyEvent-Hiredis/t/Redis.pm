package t::Redis;
use strict;
use warnings;
use Test::TCP;
use Test::More;
use FindBin;
use File::Which qw(which);

use base qw(Exporter);
our @EXPORT = qw(test_redis);

sub test_redis(&;$) {
    my $cb        = shift;
    my $args      = shift;

    my $redis_server = which 'redis-server';
    unless ($redis_server && -e $redis_server && -x _) {
        plan skip_all => 'redis-server not found in your PATH';
    }

    test_tcp
        server => sub {
            my $port = shift;
            rewrite_redis_conf($port);
            open STDOUT, '>', '/dev/null' or die q/Can't redirect STDOUT/;
            exec "redis-server", "t/redis.conf";
        },
        client => sub {
            my $port = shift;
            $cb->($port);
        };
}

sub rewrite_redis_conf {
    my $port = shift;
    my $dir  = $FindBin::Bin;

    open my $in, "<", "t/redis.conf.base" or die $!;
    open my $out, ">", "t/redis.conf" or die $!;

    while (<$in>) {
        s/__PORT__/$port/;
        s/__DIR__/$dir/;
        print $out $_;
    }
}

END { unlink $_ for "t/redis.conf", "t/dump.rdb" }

1;
