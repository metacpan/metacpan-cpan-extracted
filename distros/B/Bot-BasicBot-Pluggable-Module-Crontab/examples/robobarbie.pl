#!/usr/bin/env perl
use strict;
use warnings;

package RoboBarbie;
use base qw( Bot::BasicBot::Pluggable );

use Data::Dumper;
use DateTime;
use IO::File;
use Time::Crontab;

my @crontab;
my $cron_file   = 'robobarbie.cron';
my $load_time   = 0;

# help text for the bot
sub help { "RoboBarbie ... serving Dev since 2015 :)" }

sub chanjoin {
    my ($self, $hash) = @_;

    my $channel = $self->channel_data( $hash->{channel} )
        or return;
    return if(!$channel->{ $self->nick }->{op});
    return if( $channel->{ $hash->{who} }->{op});
    $self->mode("$hash->{channel} +o $hash->{who}");
}

my $bot = RoboBarbie->new(

    server   => "irc.example.com",
    port     => "9999",
    ssl      => 1,
    password => 'password',

    nick     => "robobarbie",
    altnicks => ["robotbarbie"],
    username => "RoboBarbie",
    name     => "RoboBarbie (Yet Another Pluggable Bot)",

    channels => ['#green','#yellow','#pink','#blue','#red','#purple'],

    ignore_list => [qw(support)],

);

my $auth = $bot->load('Auth');
$auth->set( 'password_admin', 'secret');

$bot->load('Loader');
$bot->load('Seen');
$bot->load('Join');
$bot->load('Karma');
$bot->load('Crontab');
$bot->load('Notify');

$bot->run;

1;

