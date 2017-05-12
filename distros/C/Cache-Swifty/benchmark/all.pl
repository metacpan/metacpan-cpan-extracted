#! /usr/bin/perl

use strict;
use warnings;

use Benchmark qw(timethese cmpthese);
use Cache::Memcached;
use Cache::FastMmap;
use Cache::Swifty qw(:all);
use File::Remove qw(remove);

sub MEMCACHED_SERVERS () { [ '127.0.0.1:11211' ] }
sub SWIFTY_CACHE_DIR () { '/tmp/cache-swify-bench' }

sub OUTER_LOOP () { 500 }
sub INNER_LOOP () { 1000 }

my $hash = HashWrap->new();

my $memd = Cache::Memcached->new({
    servers => MEMCACHED_SERVERS,
});

my $fm = Cache::FastMmap->new();

remove \1, SWIFTY_CACHE_DIR;
system('swifty ' . SWIFTY_CACHE_DIR . ' --build 4 8 1024');
my $swifty = Cache::Swifty->new({
    dir => SWIFTY_CACHE_DIR,
});

my $swifty_direct = swifty_new(SWIFTY_CACHE_DIR, 3600, 0, 0);


my $outer_loop = shift @ARGV || 500;
my $only = @ARGV ? sub {
    my $i = shift;
    my %o = map { $_ => $i->{$_} } @ARGV;
    \%o;
} : sub {
    shift;
};

benchmark('tiny', '0123456789abcdef');
benchmark('medium', '0123456789abcdef' x 64);

sub benchmark {
    my ($n, $v) = @_;
    my $len = length $v;
    print "\nWrite ($len bytes):\n";
    cmpthese($outer_loop, $only->({
        'hash' => sub {
            test_write($hash, $n, $v);
        },
        'Cache::Memcached' => sub {
            test_write($memd, $n, $v);
        },
        'Cache::FastMmap' => sub {
            test_write($fm, $n, $v);
        },
        'Cache::Swifty' => sub {
            test_write($swifty, $n, $v);
        },
        swifty_direct => sub {
            for (1..INNER_LOOP) {
                swifty_set($swifty_direct, -1, $n, $v, 0);
            }
        },
    }));
    print "\nRead  ($len bytes):\n";
    cmpthese($outer_loop, $only->({
        'hash' => sub {
            test_read($hash, $n);
        },
        'Cache::Memcached' => sub {
            test_read($memd, $n);
        },
        'Cache::FastMmap' => sub {
            test_read($fm, $n);
        },
        'Cache::Swifty' => sub {
            test_read($swifty, $n);
        },
        swifty_direct => sub {
            for (1..INNER_LOOP) {
                swifty_get($swifty_direct, -1, $n);
            }
        },
    }));
}

sub test_write {
    my ($c, $n, $v) = @_;
    $c->set($n, $v) for 1..INNER_LOOP;
}

sub test_read {
    my ($c, $n) = @_;
    $c->get($n) for 1..INNER_LOOP;
}

package HashWrap;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub get {
    my ($self, $n) = @_;
    $self->{$n};
}

sub set {
    my ($self, $n, $v) = @_;
    $self->{n} = $v;
}

1;
