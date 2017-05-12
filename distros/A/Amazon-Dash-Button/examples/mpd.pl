#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Amazon::Dash::Button ();

use constant MPC => q{/usr/bin/mpc};

die
  "You should run this script as root. Please run:\nsudo $0 [en0|eth0|wlan0]\n"
  if $>;

my $device = $ARGV[0] || q{wlan0};

Amazon::Dash::Button->new( dev => $device, )->add(
    name    => 'KY',
    mac     => '34:d2:70:9f:bf:04',
    onClick => sub {
        print "clicked ! from the KY button\n";
        start_stop();
    },
    _fork_for_onClick => 0,    # fast enough do not need to fork there
  )->add(
    name    => 'Trojan',
    mac     => '68:54:fd:b5:2d:a0',
    onClick => sub {
        print "clicked ! from the Trojan button\n";
        go_to_bed();
    },
  )->listen;

sub go_to_bed {

    return mpc('stop') if is_mpc_playing();

    my @decrease = (

        # volume , time in minute
        [ 10, 2 ],
        [ 9,  2 ],
        [ 8,  5 ],
        [ 7,  5 ],
        [ 6,  20 ],
        [ 5,  10 ],
        [ 4,  2 ],
    );

    mpc('stop');
    mpc('clear');

    #mpc('add', 'NAS/QNap/random' );
    mpc( 'add', 'NAS/QNap/00-NETGEAR/Musique Classique' );
    mpc('shuffle');
    volume( $decrease[0]->[0] );    # set the volume at the beginning
    tlog("start play...");
    mpc('play');

    foreach my $rule (@decrease) {
        my ( $volume, $time ) = @$rule;
        tlog("volume at $volume for $time minutes");
        volume($volume);
        sleep( 60 * $time );
    }

    mpc('stop');

    return;
}

sub start_stop {

    return mpc('stop') if is_mpc_playing();
    start();

    return;
}

sub start {

    mpc('stop');
    mpc('clear');
    mpc( 'add', 'NAS/QNap/random' );
    mpc('shuffle');
    volume(65);
    mpc('play');

    return;
}

sub is_mpc_playing {
    my $mpc = MPC;
    my $out = qx{$mpc};
    return $out =~ qr{^\[playing\]}mi ? 1 : 0;
}

sub mpc {
    my @args = @_;

    system MPC, @args;

    return $? == 0;
}

sub volume {
    my $v = shift;
    tlog("set volume to $v");
    return mpc( 'volume', $v );
}

sub tlog {    # dummy helper to print timed log
    print STDERR join( ' ', @_, "\n" );
    return;
}
