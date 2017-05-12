use strict;
use warnings;

use Test::More tests => 60;

use Data::Remember POE => 'Memory';
use POE;

sub ping {
    my $kernel = $_[KERNEL];

    my $pings = recall 'pings';
    remember pings => $pings - 1;

    $kernel->yield( 'ping' ) if $pings > 1;
    $kernel->yield( 'pong' );
}

sub pong {
    pass('ponged again');
}

my $too_many = 0;
sub ping_then_forget {
    my $kernel = $_[KERNEL];

    if (recall 'forget_this') {
        forget 'forget_this';
        $kernel->yield( 'ping_then_forget' );
        pass('i did not forget yet');

        if (++$too_many > 50) {
            # screw it, just stop NOW
            fail('something is messed up, i should have forgotten "forget_this" by now');
            exit;
        }
    }
}

sub _start {
    my $kernel = $_[KERNEL];

    remember pings => 5;
    remember forget_this => 1;

    $kernel->yield( 'ping' );
    $kernel->yield( 'ping_then_forget' );
}

for ( 1 .. 10 ) {
    POE::Session->create(
        inline_states => {
            _start           => \&_start,
            ping             => \&ping,
            pong             => \&pong,
            ping_then_forget => \&ping_then_forget,
        },
        heap => brain->new_heap,
    );
}

POE::Kernel->run;
