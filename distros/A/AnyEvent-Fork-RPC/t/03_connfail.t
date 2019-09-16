# connection failure test, written by Johan Finnved <johan@finnved.se>

$| = 1;
print "1..5\n";

use AnyEvent;
use AnyEvent::Fork::RPC;

print "ok 1\n";

my $done = AE::cv;

# Test behavior when AnyEvent::Fork::Remote connection fails
# without creating dependency to AnyEvent::Fork::Remote

# Equivalent of
# my $rpc = AnyEvent::Fork::Remote
#    ->new_execp ("ssh", "ssh", 'host-down.example.com', "perl")
#    ->AnyEvent::Fork::RPC::run ("run",

my $rpc = AnyEvent::Fork::Remote::Dummy
   ->new
   ->AnyEvent::Fork::RPC::run ("run",
      async      => 1,
      on_error   => sub { $done->send ("ok 5 - expected on_error\n") },
      on_event   => sub { print "on_event $_[0]\n" },
      on_destroy => sub { $done->send ("not ok 5 - on_destroy\n") },
   );

print "ok 2\n";

$rpc->(3, sub { print $_[0] });

print "ok 3\n";

undef $rpc;

print "ok 4\n";

my $w = AE::timer 5, 0, sub {$done->send("not ok 5 - timeout connection error not reported\n") };

print $done->recv;

package AnyEvent::Fork::Remote::Dummy;

sub new { my $a ; bless \$a }

sub eval { $_[0] }
sub send_arg { $_[0] }

# Report connection error by not returning fh
# just like AnyEvent::Fork::Remote
sub run {
    my ($self, $remoteMethod, $connectCb) = @_;
    AE::postpone { $connectCb->() }; 
    $self;
}

