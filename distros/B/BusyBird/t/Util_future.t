use strict;
use warnings;
use Test::More;
use BusyBird::Util qw(future_of);
use Test::MockObject;
use Carp;

note('tests for BusyBird::Util::future_of()');

sub create_futurizable_mock {
    my $mock = Test::MockObject->new();
    my $pending_callback;
    $mock->mock('success_undef', sub {
        my ($self, %args) = @_;
        $args{callback}->(undef, 1, 2, 3);
    });
    $mock->mock('success_false', sub {
        my ($self, %args) = @_;
        $args{callback}->(0);
    });
    $mock->mock('failure_result', sub {
        my ($self, %args) = @_;
        $args{callback}->('failure', 'detailed', 'reason');
    });
    $mock->mock('die', sub {
        die "fatal error\n";
    });
    $mock->mock('pend_this', sub {
        my ($self, %args) = @_;
        $pending_callback = $args{callback};
    });
    $mock->mock('fire', sub {
        my ($self, @args) = @_;
        $pending_callback->(@args);
    });
}

sub keys_from_list {
    my (@list) = @_;
    return keys %{ +{@list} };
}

{
    note('--- immediate cases');
    my $mock = create_futurizable_mock();
    foreach my $case (
        {label => "success undef", method => 'success_undef', in_args => [foo => 'bar'],
         exp_result_type => 'fulfill', exp_result => [1,2,3]},
        {label => "success false", method => 'success_false', in_args => [hoge => 'fuga'],
         exp_result_type => 'fulfill', exp_result => []},
        {label => 'failure result', method => 'failure_result', in_args => [],
         exp_result_type => 'reject', exp_result => ['failure', 1]},
        {label => 'die', method => 'die', in_args => [hoge => 10],
         exp_result_type => 'reject', exp_result => ["fatal error\n"]},
    ) {
        note("--- -- case: $case->{label}");
        $mock->clear;
        my $f = future_of($mock, $case->{method}, @{$case->{in_args}});
        is($mock->call_pos(1), $case->{method}, "$case->{method} should be called on the mock");
        my @got_args = $mock->call_args(1);
        is(shift(@got_args), $mock, "invocant OK");
        is_deeply([sort {$a cmp $b} keys_from_list(@got_args)],
                  [sort {$a cmp $b} keys_from_list(@{$case->{in_args}}), 'callback'],
                  "$case->{method} arg keys OK");
        isa_ok($f, 'Future::Q', 'result of future_of()');
        ok($f->is_ready, 'f is ready');
        my @got_result;
        my $got_result_type;
        $f->then(sub {
            @got_result = @_;
            $got_result_type = 'fulfill';
        }, sub {
            @got_result = @_;
            $got_result_type = 'reject';
        });
        is($got_result_type, $case->{exp_result_type}, "result type should be $case->{exp_result_type}");
        is_deeply(\@got_result, $case->{exp_result}, "result OK");
    }
}

{
    local $Carp::Verbose = 0;
    note('--- failure cases');
    my $mock = create_futurizable_mock();
    foreach my $case (
        {label => 'non existent method',
         in_invocant => $mock, in_method => 'non_existent_method',
         exp_failure => qr/no such method.*Util_future\.t/i},
        {label => 'undef method',
         in_invocant => $mock, in_method => undef,
         exp_failure => qr/method parameter is mandatory.*Util_future\.t/i},
        {label => "non-object invocant",
         in_invocant => 'plain string', in_method => 'hoge',
         exp_failure => qr/not blessed.*Util_future\.t/i},
        {label => "undef invocant",
         in_invocant => undef, in_method => undef,
         exp_failure => qr/invocant parameter is mandatory.*Util_future\.t/i},
    ) {
        note("--- -- case: $case->{label}");
        $mock->clear;
        my $f = future_of($case->{in_invocant}, $case->{in_method});
        isa_ok($f, "Future::Q");
        ok($f->is_rejected, 'f should be rejected');
        my @result;
        $f->catch(sub { @result = @_ });
        is(scalar(@result), 1, "1 result element");
        like($result[0], $case->{exp_failure}, "failure message OK");
        note("failure message: $result[0]");
    }
}

{
    note("--- pending cases");
    my $mock = create_futurizable_mock();
    foreach my $case (
        {label => "fulfill empty", fire => [undef], exp_result_type => 'fulfill', exp_result => []},
        {label => "fulfill with 0", fire => [0, 'a', 'b'], exp_result_type => 'fulfill', exp_result => ['a', 'b']},
        {label => "fulfill with empty string", fire => ['', 100], exp_result_type => 'fulfill', exp_result => [100]},
        {label => "really empty callback", fire => [], exp_result_type => 'fulfill', exp_result => []},
        {label => "reject", fire => ["hoge"], exp_result_type => 'reject', exp_result => ["hoge", 1]}
    ) {
        note("--- -- $case->{label}");
        $mock->clear;
        my $f = future_of($mock, "pend_this");
        ok($f->is_pending, "f is pending");
        is($mock->call_pos(1), "pend_this", "pend_this method should be called");
        my @got_args = $mock->call_args(1);
        is(shift(@got_args), $mock, "invocant OK");
        is_deeply([keys_from_list(@got_args)], ['callback'], "pend_this called with 'callback' param only");
        $mock->fire(@{$case->{fire}});
        ok(!$f->is_pending, 'f is ready');
        my $got_result_type;
        my @got_result;
        $f->then(sub {
            @got_result = @_;
            $got_result_type = 'fulfill';
        }, sub {
            @got_result = @_;
            $got_result_type = 'reject';
        });
        is($got_result_type, $case->{exp_result_type}, "result type OK");
        is_deeply(\@got_result, $case->{exp_result}, "result OK");
    }
}


done_testing();

