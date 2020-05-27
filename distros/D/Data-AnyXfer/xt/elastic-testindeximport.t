#!/usr/bin/env perl

use v5.16.3;
use strict;
use warnings;

BEGIN {
    use Data::AnyXfer;
    Data::AnyXfer->test(1);
}

use lib 't/lib';
use TestImport;
use Try::Tiny;
use Test::Most tests => 2;
use Sys::Hostname;

use Data::AnyXfer::Elastic::Indices;


my $index_name = 'london_termini';
my $index_type = 'terminus';

clean_index();

TestImport->new(
    silo         => 'public_data',
    index_name   => $index_name,
    index_type   => $index_type,
    connect_hint => 'readwrite',
);

sleep(2);    # required for elasticsearch synchronisation

my $indices = Data::AnyXfer::Elastic::Indices->new(
    silo         => 'public_data',
    connect_hint => 'readwrite',
);
ok( $indices->exists( index => $index_name ), "Index created." );

# check that 9 documents have been inserted
is( Data::AnyXfer::Elastic::Index->new(
        silo         => 'public_data',
        index_name   => $index_name,
        index_type   => $index_type,
        connect_hint => 'readwrite',
        )->count->{count},
    9,
    '9 documents inserted succesfully'
);

clean_index();

done_testing();

# remove index from elasticsearch
sub clean_index {

    try {
        $indices->delete( index => $index_name, );
    };
}
