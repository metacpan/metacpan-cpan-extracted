#!/usr/bin/perl
use warnings;
use strict;

use Test::Most tests => 21;

use Bot::BasicBot::Pluggable;
use Bot::BasicBot::Pluggable::Module;
use Bot::BasicBot::Pluggable::Module::Notify;
use POE::Component::IRC::State;
use Test::MockModule;

my (@to,$to,$subject,$body);

my $mock1 = Test::MockModule->new('POE::Component::IRC::State');
$mock1->mock( 'new'   => sub { my $atts = {}; my $class = shift; bless $atts, $class; } );
$mock1->mock( 'nicks' => sub { qw( alex barbie carly donna emma ) } );
$mock1->mock( 'isupport' => sub { return; } );
$mock1->mock( 'nick_info' => sub {
    my ( $self, $nick ) = @_;
    return { Real => ucfirst $nick, User => ucfirst $nick, Userhost => ucfirst $nick };
} );

my $mock2 = Test::MockModule->new('Bot::BasicBot::Pluggable');
$mock2->mock( 'channel_info' => sub {
    return {
        alex   => 1,
        barbie => 1,
        carly  => 1,
        donna  => 1,
        emma   => 1
    };
} );
$mock2->mock( 'channel_data' => sub {
    my %data = (
        alex   => { op => 0, voice => 0 },
        barbie => { op => 0, voice => 0 },
        carly  => { op => 0, voice => 0 },
        donna  => { op => 0, voice => 0 },
        emma   => { op => 0, voice => 0 },
    );
    return \%data;
} );
$mock2->mock( 'pocoirc'   => sub { return POE::Component::IRC::State->new; } );
$mock2->mock( 'channels'  => sub { return qw( purple ); } );

my $mock3 = Test::MockModule->new('MIME::Lite');
$mock3->mock( 'new' => sub {
    my ($class,%hash) = @_;

    $to      = $hash{ 'To' };
    $subject = $hash{ 'Subject' };
    $body    = $hash{ 'Data' };
    push @to, $to;

    return 'MIME::Lite';
    
} );
$mock3->mock( 'send' => sub { return; } );

$SIG{__WARN__} = sub
{
    my $warning = shift;
    warn $warning unless $warning =~ /Subroutine .* redefined at|Loading .* from .* at|table ".*" already exists/;
};

{
    {
        my $autobot = setbot();
        ( @to, $to, $subject, $body ) = ();

        $autobot->store->set( 'notify', 'notifications', 't/data/01test.csv' );
        is( $autobot->store->get( 'notify', 'notifications' ), 't/data/01test.csv' );

        ( @to, $to, $subject, $body ) = ();
        is( $autobot->told( { body => 'Test Message', channel => '#purple', who => 'carly' } ), 0, 'no mail sent' );
        cmp_deeply(
            [ sort @to ],
            [  ],
            '0 emails sent' );
        is( $subject, undef, 'no subject sent' );
        is( $body, undef, 'no message sent' );

        ( @to, $to, $subject, $body ) = ();
        is( $autobot->told( { body => 'Test Message @all', channel => '#purple', who => 'carly' } ), 1, 'mails sent' );
        cmp_deeply(
            [ sort @to ],
            [ 'alex@example.com', 'barbie@example.com', 'emma@example.com' ],
            '3 emails sent' );
        like( $subject, qr/IRC: carly sent you a message/, 'correct subject sent' );
        like( $body, qr/Test Message/s, 'correct message sent' );

        ( @to, $to, $subject, $body ) = ();
        is( $autobot->told( { body => '@alex Hi', channel => '#purple', who => 'barbie' } ), 1, 'mails sent' );
        cmp_deeply(
            [ sort @to ],
            [ 'alex@example.com' ],
            '1 emails sent' );
        like( $subject, qr/IRC: barbie sent you a message/, 'correct subject sent' );
        like( $body, qr/alex Hi/s, 'correct message sent' );

        ( @to, $to, $subject, $body ) = ();
        is( $autobot->told( { body => '@here Blah Blah Blah', channel => '#purple', who => 'barbie' } ), 1, 'mails sent' );
        cmp_deeply(
            [ sort @to ],
            [ 'alex@example.com', 'emma@example.com' ],
            '2 emails sent' );
        like( $subject, qr/IRC: barbie sent you a message/, 'correct subject sent' );
        like( $body, qr/here Blah Blah Blah/s, 'correct message sent' );

        ( @to, $to, $subject, $body ) = ();
        is( $autobot->told( { body => '@all Blah Blah Blah', channel => '#purple', who => 'barbie' } ), 1, 'mails sent' );
        cmp_deeply(
            [ sort @to ],
            [ 'alex@example.com', 'emma@example.com' ],
            '2 emails sent' );
        like( $subject, qr/IRC: barbie sent you a message/, 'correct subject sent' );
        like( $body, qr/all Blah Blah Blah/s, 'correct message sent' );
    }

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

