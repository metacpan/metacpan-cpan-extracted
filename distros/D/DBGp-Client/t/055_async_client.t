#!/usr/bin/perl

use t::lib::Test;

use IO::Select;
use DBGp::Client::AsyncConnection;

my $LISTEN = dbgp_listen();

dbgp_run_fake();

my $socket = $LISTEN->accept;

die "Did not receive any connection from the fake debugger: ", $LISTEN->error
    unless $socket;
$socket->blocking(0);

my $conn = DBGp::Client::AsyncConnection->new(socket => $socket);
my $output = '';
my @notifications;

$conn->on_stream(sub { $output .= $_[0]->content });
$conn->on_notification(sub { push @notifications, $_[0]->name });

pull_data_while($socket, sub { !$conn->init });

is($conn->init->language, 'Perl');
is($output, "");
is_deeply(\@notifications, []);

my $res1;
$conn->send_command(sub { $res1 = $_[0] }, 'stack_depth');
pull_data_while($socket, sub { !$res1 });

is($res1->transaction_id, 1);
is($output, "Step 1\n");
is_deeply(\@notifications, []);

my $res2;
$conn->send_command(sub { $res2 = $_[0] }, 'stack_depth');
pull_data_while($socket, sub { !$res2 });

is($res2->transaction_id, 2);
is($output, "Step 1\n");
is_deeply(\@notifications, ['stdin']);

done_testing();

sub pull_data_while {
    my ($socket, $test) = @_;

    my $fds = IO::Select->new;

    $fds->add($socket);

    while ($test->()) {
        my ($rd, undef, $err) = $fds->select($fds, undef, $fds, 10);

        die "There was an error" if $err && @$err;

        # uses 1 to test the buffering/parsing logic
        sysread $socket, my $buf, 1;
        $conn->add_data($buf);
    }
}
