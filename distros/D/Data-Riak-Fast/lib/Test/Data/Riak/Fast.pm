package Test::Data::Riak::Fast;

use strict;
use warnings;

use Try::Tiny;
use Test::More;
use Digest::MD5 qw/md5_hex/;

use Sub::Exporter;

use Data::Riak::Fast::HTTP;

my @exports = qw[
    skip_unless_riak
    skip_unless_leveldb
    remove_test_bucket
    create_test_bucket_name
];

Sub::Exporter::setup_exporter({
    exports => \@exports,
    groups  => { default => \@exports }
});

sub create_test_bucket_name {
	my $prefix = shift || 'data-riak-test';
    return $prefix . '-' . md5_hex(scalar localtime)
}

sub skip_unless_riak {
    my $up = Data::Riak::Fast::HTTP->new->ping;
    unless($up) {
        plan skip_all => 'Riak did not answer, skipping tests'
    };
    return $up;
}

sub skip_unless_leveldb {
    my $storage_backend = Data::Riak::Fast->new(transport => Data::Riak::Fast::HTTP->new)->stats->{storage_backend};
    if ($storage_backend ne 'riak_kv_eleveldb_backend') {
        plan skip_all => 'Only storage_backend => riak_kv_eleveldb_backend'
    };
    return $storage_backend;
}

sub remove_test_bucket {
    my $bucket = shift;

    try {
        $bucket->remove_all;
        Test::More::diag "Removing test bucket so sleeping for a moment to allow riak to eventually be consistent ...";
        my $keys = $bucket->list_keys;
        while ( $keys && @$keys ) {
            sleep(1);
            $keys = $bucket->list_keys;
        }
    } catch {
        is($_->value, "not found\n", "Bucket is now empty");
        is($_->code, "404", "Calling list_keys on an empty bucket gives a 404");
    };
}

