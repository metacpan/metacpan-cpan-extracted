package Couchbase::Test::Async;
use strict;
use warnings;

use base qw(Couchbase::Test::Common);
use base qw(POE::Sugar::Attributes);
use Test::More;
use Couchbase::Client::Async;
use Couchbase::Client::Errors;
use Couchbase::Client::IDXConst;
use Array::Assign;
use Data::Dumper;
use Log::Fu;

my $loop_session = "cbc_test_async";
my $client_session = 'our_client';
my $poe_kernel = 'POE::Kernel';

my $can_async = eval {
    use Couchbase::Test::Async::Loop;
    use POE::Kernel; 1;
};

if(!$can_async) {
    __PACKAGE__->SKIP_CLASS("Can't run async tests: $@");
}

if($^O eq 'netbsd') {
    __PACKAGE__->SKIP_CLASS("Skipping Async tests on netbsd ".
                            "due to weird kernel bug");
}
$poe_kernel->run();


my $ReadyReceived = 0;
my $Return = undef;
my $Errnum;

sub setup_async :Test(startup) {
    my $self = shift;
    $self->mock_init();

    Couchbase::Test::Async::Loop->spawn($loop_session,
        on_ready => \&loop_ready,
        on_error => sub { $Errnum = $_[0]; diag "Grrr!"; },
        %{$self->common_options}
    );
}

sub loop_ready {
    $ReadyReceived = 1;
}

sub _run_poe {
    $poe_kernel->run_one_timeslice() while ($ReadyReceived == 0);
}

sub cb_result_single {
    my ($key,$return,$errnum) = @_;
    if($errnum >= 0) {
        is($return->errnum, $errnum,
           "Got return for key $key (expected=$errnum)");
    }
    $Return = $return;
}

sub reset_vars :Test(setup) {
    $ReadyReceived = 0;
    $Return = undef;
    $Errnum = -1;
}

sub post_to_loop {
    my ($self,$command,$opargs,$errnum) = @_;
    reset_vars();
    $poe_kernel->post($loop_session, $command, $opargs,
                      {callback => \&cb_result_single, arg => $errnum });
    _run_poe();
    ok($Return, "Have return object");
    return $Return;
}

sub T10_connect :Test(no_plan) {
    my $self = shift;
    $poe_kernel->run_one_timeslice() while ($ReadyReceived == 0);
    
    ok($ReadyReceived, "Eventually connected..");
    ok($Errnum <= 0, "Got no errors ($Errnum)");
    if($Errnum > 0) {
        die("Got errors. Cannot continue");
        $self->FAIL_ALL("Async tests cannot continue without hanging");
    }
}

sub T11_set :Test(no_plan) {
    my $self = shift;
    my $key = "async_key";
    my $value = $self->k2v($key);
    $self->post_to_loop(set => [ $key, $value ], COUCHBASE_SUCCESS);
}

sub T12_get :Test(no_plan) {
    my $self = shift;
    my $key = "async_key";
    
    my $ret = $self->post_to_loop(get => "async_key", COUCHBASE_SUCCESS);
    is($ret->value, $self->k2v($key), "Got expected value");
}

sub T14_arith_ext :Test(no_plan) {
    my $self = shift;
    my $key = "async_key";
    
    my $ret;
    $self->post_to_loop(remove => [$key], -1);
    
    $ret = $self->post_to_loop(
        arithmetic => [ $key, 42, undef ], COUCHBASE_KEY_ENOENT);
    is($ret->value, undef, "Didn't get value for missing initial value");
    
    $ret = $self->post_to_loop(
        arithmetic => [ $key, 9999, 42 ], COUCHBASE_SUCCESS);
        
    is($Return->value, 42, "Initial value set via arithmetic");
        
}

1;