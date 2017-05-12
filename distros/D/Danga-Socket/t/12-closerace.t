#!/usr/bin/perl -w
#
#  This test simulates epoll_wait returning two objects, one of which
#  deletes the other before the other is later then processed.  If we
#  remove the fd from DescriptorMap at the wrong time, then
#  Danga::Socket emits warnings.  Danga::Socket now delays removing
#  from DescriptorMap until later.

use strict;
use Test::More tests => 7;
use Danga::Socket;
use IO::Socket::INET;
use POSIX;
no  warnings qw(deprecated);

use vars qw($done);

my $ssock = IO::Socket::INET->new(Listen    => 5,
                                  LocalAddr => '127.0.0.1',
                                  LocalPort => 60000,
                                  Proto     => 'tcp',
                                  ReuseAddr => 1,
                                  );
ok($ssock, "made server");
my $c1 = IO::Socket::INET->new(PeerAddr => "127.0.0.1:60000");
ok($c1, "made client1");
my $sc1 = $ssock->accept;
ok($sc1, "got client1");
my $c2 = IO::Socket::INET->new(PeerAddr => "127.0.0.1:60000");
ok($c2, "made client2");
my $sc2 = $ssock->accept;
ok($sc2, "got client2");

my $ds1 = ClientIn->new($c1);
my $ds2 = ClientIn->new($c2);
$ds1->watch_write(1);
$ds2->watch_write(1);

use vars qw($no_warnings);
$no_warnings = 1;

$SIG{__WARN__} = sub {
    my $msg = shift;
    print STDERR "WARNING: $msg";
    $no_warnings = 0;
};

Danga::Socket->EventLoop;


package ClientIn;
use base 'Danga::Socket';
use fields (
            'got',
            'state',
            );

our %set;
our @history;

sub new {
    my ($class, $sock) = @_;

    my $self = fields::new($class);
    $self->SUPER::new($sock);       # init base fields
    $self->watch_read(1);
    $self->{state} = "init";
    $self->{got}   = "";

    $set{$self->{fd}} = $self;
    return $self;
}

sub event_write {
    my $self = shift;

    my $brother_fd = (grep { $_ != $self->{fd} } keys %set)[0];
    my $brother    = $set{$brother_fd};

    push @history, $self->{fd};
    if (@history > 10) {
        Test::More::ok(scalar(grep { $_ != $self->{fd} } @history) == 0, "only ourselves in the history");
        Test::More::ok($main::no_warnings, "no warnings");
        exit(0);
    }

    $brother->close;
}
