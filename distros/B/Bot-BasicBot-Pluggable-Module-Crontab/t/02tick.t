#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 15;

use FindBin::libs;

use Bot::BasicBot::Pluggable;
use Bot::BasicBot::Pluggable::Module;
use Bot::BasicBot::Pluggable::Module::Crontab;
use Test::MockModule;
use File::Temp qw( tmpnam );
use IO::File;

my ($channel,$message);

my $mock = Test::MockModule->new('Bot::BasicBot::Pluggable::Module');
$mock->mock( 'say' => sub {
    my ($self,%args) = @_;

    $channel = $args{ channel };
    $message = $args{ body };
    
});

$SIG{__WARN__} = sub
{
    my $warning = shift;
    warn $warning unless $warning =~ /Subroutine .* redefined at/;
};

{
    { # every minute
        my $cron = setbot();
        ( $channel, $message ) = ( undef, undef );

        $cron->store->set( 'crontab', 'file', 't/data/01test.cron' );
        is( $cron->store->get( 'crontab', 'file' ), 't/data/01test.cron' );

        $cron->tick;
        is( $channel, '#dev', 'message sent to correct channel' );
        is( $message, 'Minute Check!', 'correct message sent' );
    }

    { # this week
        my $cron = setbot();
        ( $channel, $message ) = ( undef, undef );

        $cron->store->set( 'crontab', 'file', 't/data/02test.cron' );
        is( $cron->store->get( 'crontab', 'file' ), 't/data/02test.cron' );

        $cron->tick;
        is( $channel, '#dev', 'message sent to correct channel' );
        is( $message, 'This Week!', 'correct message sent' );
    }


    { # not this week
        my $cron = setbot();
        ( $channel, $message ) = ( undef, undef );

        $cron->store->set( 'crontab', 'file', 't/data/03test.cron' );
        is( $cron->store->get( 'crontab', 'file' ), 't/data/03test.cron' );

        $cron->tick;
        is( $channel, undef, 'no channel set' );
        is( $message, undef, 'no message sent' );
    }

    { # this week number
        my $wkno = DateTime->now->week_number;
        my $cron = setbot();
        ( $channel, $message ) = ( undef, undef );
        my $tempfile = tmpnam();
        my $fh = IO::File->new( $tempfile, 'w+' );
        unless( $fh ) {
            ok(0); ok(0); ok(0);
            next;
        }

        print $fh "* * * * * $wkno #dev Week Number\n";
        $fh->close;

        $cron->store->set( 'crontab', 'file', $tempfile );
        is( $cron->store->get( 'crontab', 'file' ), $tempfile );

        $cron->tick;
        is( $channel, '#dev', 'no channel set' );
        is( $message, 'Week Number', 'no message sent' );

        unlink( $tempfile );
    }

    { # not this week number
        my $wkno = DateTime->now->week_number + 1;
        my $cron = setbot();
        ( $channel, $message ) = ( undef, undef );
        my $tempfile = tmpnam();
        my $fh = IO::File->new( $tempfile, 'w+' );
        unless( $fh ) {
            ok(0); ok(0); ok(0);
            next;
        }

        print $fh "* * * * * $wkno #dev Week Number\n";
        $fh->close;

        $cron->store->set( 'crontab', 'file', $tempfile );
        is( $cron->store->get( 'crontab', 'file' ), $tempfile );

        $cron->tick;
        is( $channel, undef, 'no channel set' );
        is( $message, undef, 'no message sent' );

        unlink( $tempfile );
    }

}

sub setbot {
    my $bot = CronBot->new(

        server   => "localhost",
        port     => "9999",
        password => 'password',

        nick     => "cronbot",
        altnicks => ["cronbot"],
        username => "CronBot",
        name     => "CronBot",

        channels => ['#dev'],

    );

    my $auth = $bot->load('Auth');
    $auth->set( 'password_admin', 'cronbot');

    $bot->load('Loader');
    return $bot->load('Crontab');
}

package CronBot;
use base qw( Bot::BasicBot::Pluggable );

use Data::Dumper;
use DateTime;
use IO::File;
use Time::Crontab;

my @crontab;
my $cron_file   = 't/data/01test.cron';
my $load_time   = 0;

# help text for the bot
sub help { "CronBot ... serving messages since 2015" }

sub chanjoin {
    my ($self, $hash) = @_;

    my $channel = $self->channel_data( $hash->{channel} )
        or return;
    return if(!$channel->{ $self->nick }->{op});
    return if( $channel->{ $hash->{who} }->{op});
    $self->mode("$hash->{channel} +o $hash->{who}");
}

1;

