use strict;
use Test::More;
use Cwd;
use t::CLI;
use Data::Dumper;

BEGIN {
    my $cwd = getcwd;
    $ENV{'DANCER_CONFDIR'} =  $cwd . '/t';
    $ENV{'DANCER_ENVDIR'}  = $cwd . '/t/environments';
    $ENV{'DANCER_ENVIRONMENT'} = 'development';
     die "DANCER_ENVIRONMENT not set" unless $ENV{DANCER_ENVIRONMENT};
}

my ($host, $port);

if ( $ENV{ETCD_TEST_HOST} and $ENV{ETCD_TEST_PORT}) {
    $host = $ENV{ETCD_TEST_HOST};
    $port = $ENV{ETCD_TEST_PORT};
    plan tests => 2;
}
else {
    plan skip_all => "Please set environment variable ETCD_TEST_HOST and ETCD_TEST_PORT.";
}

subtest 'shepherd put' => sub {
    my $app = cli();
    my $path = getcwd . '/t/lib';
    my $action = $app->run("put", "--apppath", "$path", "--etcdhost", "$host", "--etcdport", "$port");
    cmp_ok( $app->stdout, '==', 0, "shepherd put" );
};

subtest 'shepherd get' => sub {
    my $app = cli();
    my $path = getcwd . '/t/lib';
    $app->run("get", "--apppath", "$path", "--etcdhost", "$host", "--etcdport", "$port");
    cmp_ok( $app->stdout, '==', 0, "shepherd get" );
};

done_testing;
