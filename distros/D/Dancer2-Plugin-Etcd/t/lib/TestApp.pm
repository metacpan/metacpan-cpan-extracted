package TestApp;

use strict;
use warnings;

BEGIN {
    $ENV{DANCER_CONFDIR} = 't';
    $ENV{DANCER_ENVDIR}  = 't/environments';
}

use Dancer2;
use Dancer2::Plugin::Etcd;
use Data::Dumper;


get '/etcd/put' => sub {
    my $etcd = etcd('foo');
    $etcd->put({ key =>'foo1', value => 'bar' })->request;
#    print STDERR Dumper($etcd);
    return ref($etcd);
};

get '/etcd/range' => sub {
    my $etcd = etcd('foo');
    $etcd->range({ key =>'foo1' })->get_value;
#    print STDERR  Dumper($etcd);
    return ref($etcd);
};
