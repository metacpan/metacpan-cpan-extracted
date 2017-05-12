#!perl

use strict;
use warnings;
use FindBin 1.49;
use lib "$FindBin::Bin/lib";

use Test::More 0.98;
use Test::Exception 0.31;

my $good_config = {
    couchdb_uri => 'http://localhost:5984/',
    dbname      => 'demouser',
    designdoc   => '_design/user',
    view        => 'user',
};

use_ok('Catalyst::Authentication::Store::CouchDB');

foreach my $keyname ( sort keys %$good_config) {
    my $bad_config = { %$good_config };
    delete $bad_config->{$keyname};
    
    throws_ok (
        sub {
            my $test_user = Catalyst::Authentication::Store::CouchDB->new($bad_config, undef);
        },
        'Catalyst::Exception',
        $keyname.' missing throws an exception'
    );
}

my $bad_config = {
    %$good_config,
    designdoc => 'a load of rubbish',
};

throws_ok (
    sub {
        my $test_user = Catalyst::Authentication::Store::CouchDB->new($bad_config, undef),
    },
    'Catalyst::Exception',
    'incorrect designdoc throws an exception',
);

done_testing;
