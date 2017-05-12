#!/usr/bin/perl

use t::lib::Test;

use DBGp::Client::Connection;

my $LISTEN = dbgp_listen();

dbgp_run_fake();

my $socket = $LISTEN->accept;

die "Did not receive any connection from the fake debugger: ", $LISTEN->error
    unless $socket;

my $conn = DBGp::Client::Connection->new(socket => $socket);
my $output = '';
my @notifications;

$conn->on_stream(sub { $output .= $_[0]->content });
$conn->on_notification(sub { push @notifications, $_[0]->name });

my $init = $conn->parse_init;

is($init->language, 'Perl');
is($output, "");
is_deeply(\@notifications, []);

my $res1 = $conn->send_command('stack_depth');

is($res1->transaction_id, 1);
is($output, "Step 1\n");
is_deeply(\@notifications, []);

my $res2 = $conn->send_command('stack_depth');

is($res2->transaction_id, 2);
is($output, "Step 1\n");
is_deeply(\@notifications, ['stdin']);

done_testing();
