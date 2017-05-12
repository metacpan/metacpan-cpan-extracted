#!/usr/bin/perl

use t::lib::Test;

my $connected = AnyEvent->condvar;
my $listen = dbgp_anyevent_listen(sub {
    $connected->send($_[0]);
});

dbgp_run_fake();

my $conn = $connected->recv;

while (!$conn->init) {
    my $wait = AnyEvent->condvar;
    my $w = AnyEvent->timer(
        after   => 0.1,
        cb      => sub { $wait->send },
    );
    $wait->recv;
}
is($conn->init->language, 'Perl');

my @out;
my @expected_out = (['stdout', "Some output\n"]);
$conn->on_stream(sub {
    push @out, [$_[0]->type, $_[0]->content];
});

my $res1;
my $cv1 = $conn->send_command(sub { $res1 = $_[0] }, 'stack_depth');
my $res1_cv = $cv1->recv;

dbgp_parsed_response_cmp($res1, {
    transaction_id  => 1,
    is_error        => 0,
});
is_deeply(\@out, []);
is($res1, $res1_cv);

my $cv2 = AnyEvent->condvar;
$conn->send_command($cv2, 'stack_depth');
my $res2 = $cv2->recv;

dbgp_parsed_response_cmp($res2, {
    transaction_id  => 2,
    is_error        => 0,
});
is_deeply(\@out, \@expected_out);

my $cv3 = $conn->send_command(undef, 'stack_depth');
my $res3 = $cv3->recv;

dbgp_parsed_response_cmp($res3, {
    transaction_id  => 3,
    is_error        => 0,
});
is_deeply(\@out, \@expected_out);

my $cv4 = $conn->send_command(undef, 'stack_depth');
my $res4 = $cv4->recv;

dbgp_parsed_response_cmp($res4, {
    transaction_id  => 4,
    is_error        => 1,
    is_internal_error => 1,
    message         => 'Broken connection',
});
is_deeply(\@out, \@expected_out);

done_testing();
