package libmemcached_test;

use strict;
use warnings;
use base 'Exporter';

use Cache::Memcached::libmemcached;
use Test::More;

our @EXPORT = qw(
    libmemcached_test_create
    libmemcached_test_key
    libmemcached_version_ge
    libmemcached_test_servers
);

sub libmemcached_test_servers {
    my $servers = $ENV{PERL_LIBMEMCACHED_TEST_SERVERS};
    # XXX add the default port as well to stop uninit
    # warnings from the test suite
    $servers ||= 'localhost:11211';
    return split(/\s*,\s*/, $servers);
}


sub libmemcached_test_create {
    my ($args) = @_;

    my $min_version = delete $args->{min_version};

    $args->{ servers } = [ libmemcached_test_servers() ];

    if ($ENV{LIBMEMCACHED_BINARY_PROTOCOL}) {
        $args->{binary_protocol} = 1;
    }

    my $cache = Cache::Memcached::libmemcached->new($args);
    my $time  = time();
    $cache->set( foo => $time );
    my $value = $cache->get( 'foo' );

    plan skip_all => "Can't talk to any memcached servers"
        if (! defined $value || $time ne $value);

    plan skip_all => "memcached server version less than $min_version"
        if $min_version && not libmemcached_version_ge($cache, $min_version);

    return $cache;
}


sub libmemcached_version_ge {
    my ($memc, $min_version) = @_;
    my @min_version = split /\./, $min_version;

    my @memcached_version = $memc->memcached_version;

    for (0,1,2) {
        return 1 if $memcached_version[$_] > $min_version[$_];
        return 0 if $memcached_version[$_] < $min_version[$_];
    }
    return 1; # identical versions
}


sub libmemcached_test_key {
    # return a value suitable for use as a memcached key
    # that is unique for each run of the script
    # but returns the same value for the life of the script
    our $time_rand ||= ($^T + rand());
    return $time_rand;
}

1;
