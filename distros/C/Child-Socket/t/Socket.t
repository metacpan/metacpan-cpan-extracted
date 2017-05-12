#!/usr/bin/perl;
use strict;
use warnings;

use Test::More;
our $CLASS = 'Child::Socket';

require_ok( $CLASS );

my $child = $CLASS->new( sub {
    my $parent = shift;
    $parent->say( "Have self" );
    $parent->say( "parent: " . $parent->pid );
    my $in = $parent->read();
    $parent->say( $in );
}, socket => 1 );

my $proc = $child->start;
is( $proc->read(), "Have self\n", "child has self" );
is( $proc->read(), "parent: $$\n", "child has parent PID" );
{
    local $SIG{ALRM} = sub { die "non-blocking timeout" };
    alarm 5;
    ok( !$proc->is_complete, "Not Complete" );
    alarm 0;
}
$proc->say("XXX");
is( $proc->read(), "XXX\n", "Full IPC" );
ok( $proc->wait, "wait" );
ok( $proc->is_complete, "Complete" );
is( $proc->exit_status, 0, "Exit clean" );

$proc = $CLASS->new( sub { sleep 100 } )->start;

my $ret = eval { $proc->say("XXX"); 1 };
ok( !$ret, "Died, no IPC" );
like( $@, qr/Child was created without IPC support./, "No IPC" );
$proc->kill(2);

$proc = $CLASS->new( sub {
    my $parent = shift;
    $SIG{INT} = sub { exit( 2 ) };
    $parent->say( "go" );
    sleep 100;
}, socket => 1 )->start;

$proc->read;
sleep 1;
ok( $proc->kill(2), "Send signal" );
ok( !$proc->wait, "wait" );
ok( $proc->is_complete, "Complete" );
is( $proc->exit_status, 2, "Exit 2" );
ok( $proc->unix_exit > 2, "Real exit" );

$child = $CLASS->new( sub {
    my $parent = shift;
    $parent->autoflush(0);
    $parent->say( "A" );
    $parent->flush;
    $parent->say( "B" );
    sleep 5;
    $parent->flush;
}, socket => 1 );

$proc = $child->start;
is( $proc->read(), "A\n", "A" );
my $start = time;
is( $proc->read(), "B\n", "B" );
my $end = time;

ok( $end - $start > 2, "No autoflush" );

$proc = $CLASS->new( sub {
    my $parent = shift;
    $parent->detach;
    $parent->say( $parent->detached );
}, socket => 1 )->start;

is( $proc->read(), $proc->pid . "\n", "Child detached" );

$proc = $CLASS->new( sub {
    my $parent = shift;
    $parent->disconnect;
    $parent->connect( 10 );
    $parent->say( "Hi" );
}, socket => 1 )->start;

my $pid = $proc->pid;
my $file = $proc->socket_file;

$proc->disconnect;
$proc = Child::IPC::Socket->child_class->new_from_file( $file );
is( $proc->pid, $pid, "Connected" );
is( $proc->read(), "Hi\n", "Communicating" );

done_testing;
