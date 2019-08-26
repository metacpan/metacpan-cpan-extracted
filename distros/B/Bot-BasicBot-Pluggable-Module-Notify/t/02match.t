#!/usr/bin/perl
use warnings;
use strict;

use Test::Most tests => 7;

use Bot::BasicBot::Pluggable;
use Bot::BasicBot::Pluggable::Module;
use Bot::BasicBot::Pluggable::Module::Notify;

$SIG{__WARN__} = sub
{
    my $warning = shift;
    warn $warning unless $warning =~ /Subroutine .* redefined at|Loading .* from .* at|table ".*" already exists/;
};

{
        my $autobot = setbot();
        $autobot->store->set( 'notify', 'notifications', 't/data/01test.csv' );

        is( $autobot->store->get( 'notify', 'notifications' ), 't/data/01test.csv' );
        is( $autobot->_load_notification_file, 1, 'loaded notification file' );

        my %nicks = (
            'alex'   => { Real => 'Alex',   User => 'XXXX',   Userhost => 'XXXX'   },
            'barbie' => { Real => 'XXXXXX', User => 'Barbie', Userhost => 'XXXXXX' },
            'carly'  => { Real => 'Carly',  User => 'Carly',  Userhost => 'Carly'  },
            'donna'  => { Real => 'Donna',  User => 'Donna',  Userhost => 'Donna'  },
            'emma'   => { Real => 'XXXX',   User => 'XXXX',   Userhost => 'Emma'   }
        );
 
        is( $autobot->_match_user( 'alex',   \%nicks ), 'alex',   'matched' );
        is( $autobot->_match_user( 'barbie', \%nicks ), 'barbie', 'matched' );
        is( $autobot->_match_user( 'carly',  \%nicks ), undef,    'matched' );
        is( $autobot->_match_user( 'emma',   \%nicks ), 'emma',   'matched' );
        is( $autobot->_match_user( 'jenna',  \%nicks ), undef,    'matched' );
}

sub setbot {
    my $bot = AutoBot->new(

        server   => "localhost",
        port     => "9999",
        password => 'password',

        nick     => "autobot",
        altnicks => ["autobot"],
        username => "AutoBot",
        name     => "AutoBot",

        channels => ['#purple'],

    );

    my $auth = $bot->load('Auth');
    $auth->set( 'password_admin', 'autobot');

    $bot->load('Loader');
    return $bot->load('Notify');
}

package AutoBot;
use base qw( Bot::BasicBot::Pluggable );

# help text for the bot
sub help { "AutoBot ... serving messages since 2015" }

sub chanjoin {
    my ($self, $hash) = @_;

    my $channel = $self->channel_data( $hash->{channel} )
        or return;
    return if(!$channel->{ $self->nick }->{op});
    return if( $channel->{ $hash->{who} }->{op});
    $self->mode("$hash->{channel} +o $hash->{who}");
}

1;

