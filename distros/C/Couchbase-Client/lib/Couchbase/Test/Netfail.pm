package Couchbase::Test::Netfail;
use strict;
use warnings;
use Test::More;
use base qw(Couchbase::Test::Common);
use Couchbase::Client::Errors;
use Couchbase::MockServer;
use Time::HiRes qw(sleep);
use Data::Dumper;

use Class::XSAccessor {
    accessors => [qw(cbo vbconf)]
};

my $have_vbucket = eval {
    require Couchbase::Config::UA;
    require Couchbase::VBucket;
    die('');
    1;
};

if($Couchbase::Test::Common::RealServer) {
    __PACKAGE__->SKIP_CLASS("Can't perform network failure tests on real cluster");
}

sub startup_tests :Test(startup)
{
    my $self = shift;
    $self->mock_init();
    if($have_vbucket) {
        my $confua = Couchbase::Config::UA->new(
            $self->common_options->{server},
            username => $self->common_options->{username},
            password => $self->common_options->{password});
        my $pool = $confua->list_pools();
        $confua->pool_info($pool);
        my $buckets = $confua->list_buckets($pool);
        my $bucket = (grep {$_->name eq $self->common_options->{bucket}}
                      @$buckets)[0];
        $self->vbconf($bucket->vbconf);
    }
    
}

sub setup_test :Test(setup) {
    my $self = shift;
    my $options = $self->common_options("couchbase");
    my $cbo = Couchbase::Client->new({
        %{$self->common_options("couchbase")},
        no_init_connect => 1
    });
    $self->cbo($cbo);
    alarm(30); #things can hang, so don't wait more than a minute for each
    #function
}

sub teardown_test :Test(teardown) {
    alarm(0);
    #$SIG{ALRM} = 'DEFAULT';
}

sub T40_tmpfail_basic :Test(no_plan) {
    my $self = shift;
    
    my $cbo = $self->cbo;
    my $mock = $self->mock;
    my $wv;
    
    note "Suspending mock server";
    $mock->suspend_process();
    $cbo->timeout(0.5);
    ok(!$cbo->connect(), "Connect failed");
    my $errors = $cbo->get_errors;
    ok(scalar @$errors, "Have connection error");
    is($errors->[0]->[0], COUCHBASE_CONNECT_ERROR, "CONNECT_ERROR");
    
    note "Resuming mock server";
    $mock->resume_process();
    $wv = $cbo->connect();
    $cbo->timeout(5);
    
    ok($wv, "Connected ok");
    ok($cbo->set("Foo", "foo_value")->is_ok, "set ok");    
}

sub T41_degraded :Test(no_plan) {
    my $self = shift;
    
    local $TODO = "CouchbaseMock does not have 'server-down' mode";
    return;

    my $cbo = $self->cbo;
    my $mock = $self->mock;
    
    if(!$have_vbucket) {
        $self->builder->skip("Need Couchbase::VBucket");
        return;
    }
    
    my $key = "Foo";
    my $value = "foofoo";
    
    ok($cbo->connect(), "Connected ok (sanity check)");
    ok($cbo->set($key,$value)->is_ok, "Set (initial, sanity check)");
    
    
    my ($server,$idx) = $self->vbconf->map($key);
    $mock->failover_node($idx, $self->common_options->{bucket});
    
    my $ret = $cbo->set($key, $value);
    is($ret->errnum, COUCHBASE_ETMPFAIL, "got expected error");
    
    $mock->respawn_node($idx, $self->common_options->{bucket});
    $ret = $cbo->set($key, $value);
    ok($ret->is_ok, "Respawned node, set is OK");
}

1;