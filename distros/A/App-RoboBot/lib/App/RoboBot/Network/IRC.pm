package App::RoboBot::Network::IRC;
$App::RoboBot::Network::IRC::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

use AnyEvent;
use AnyEvent::IRC::Client;
use Data::Dumper;
use Text::Wrap qw( wrap );
use Time::HiRes qw( usleep );

use App::RoboBot::Channel;
use App::RoboBot::Message;
use App::RoboBot::Nick;

extends 'App::RoboBot::Network';

has '+type' => (
    default => 'irc',
);

has 'host' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'port' => (
    is      => 'ro',
    isa     => 'Int',
    default => 6667,
);

has 'ssl' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 'username' => (
    is  => 'ro',
    isa => 'Str',
);

has 'password' => (
    is  => 'ro',
    isa => 'Str',
);

has 'client' => (
    is      => 'ro',
    isa     => 'AnyEvent::IRC::Client',
    default => sub { AnyEvent::IRC::Client->new },
);

has 'nick_cache' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

sub BUILD {
    my ($self) = @_;

    $self->client->enable_ssl() if $self->ssl;
}

sub connect {
    my ($self) = @_;

    $self->log->info(sprintf('Connecting to IRC server at %s:%s.', $self->host, $self->port));

    $self->client->reg_cb( registered => sub {
        my ($con) = @_;

        $self->client->enable_ping(30, sub {});
    });

    $self->client->reg_cb( publicmsg => sub {
        my ($con, $chan, $msg_h) = @_;
        $self->handle_message($msg_h);
    });

    $self->client->reg_cb( privatemsg => sub {
        my ($con, $sender, $msg_h) = @_;
        $self->handle_message($msg_h);
    });

    $self->client->connect($self->host, $self->port, { nick => $self->nick->name });

    $self->log->info('Connected.');

    $_->join for @{$self->channels};
}

sub disconnect {
    # TODO: remove callbacks
    #       call client->disconnect
}

sub kick {
    my ($self, $response, $nick, $message) = @_;

    return unless $response->has_channel;
    my $channel = '#' . $response->channel->name;

    return unless defined $nick && defined $message && $nick =~ m{\w+} && $message =~ m{\w+};

    $self->client->send_long_message('utf8', 0, "KICK", $channel, $nick, $message);

    return;
}

sub send {
    my ($self, $response) = @_;

    local $Text::Wrap::columns = 400;

    # Make sure that linebreaks are treated as separators for "line" output in IRC,
    # since that isn't always the case for every protocol. And re-wrap any long
    # lines.
    my @output =
        map { length($_) > 300 ? split(/\n/, wrap('', '', $_)) : $_ }
        grep { defined $_ && $_ =~ m{\S+} }
        map { split(/\n/, $_) }
        @{$response->content};

    # TODO: Move maximum number of output lines into a config var for each IRC
    #       network (with a default).
    my $max_lines = 12;

    if (@output > $max_lines) {
        my $n = scalar @output;
        my $split_at = int($max_lines / 2) - 2;

        @output = (
            @output[0..$split_at],
            '... Output Truncated (' . ($n - (($split_at + 1) * 2)) . ' lines removed) ...',
            @output[($n - ($split_at + 1))..($n - 1)]
        );
    }

    my $recipient = $response->has_channel ? '#' . $response->channel->name : $response->nick->name;

    my $d = 0;
    for (my $i = 0; $i <= $#output; $i++) {
        my $line = $output[$i];

        if ($line =~ m{^/me\s+(.+)}) {
            $self->client->send_long_message('utf8', 0, "PRIVMSG\001ACTION", $recipient, $1);
        } else {
            $self->client->send_long_message('utf8', 0, "PRIVMSG", $recipient, $line);
            #$self->client->send_srv( PRIVMSG => $recipient, $line);
        }

        # TODO: Move send rate to a config var which can be overridden per
        #       network.

        # Ignorant and ineffective flood "protection" will gradually slow down
        # message sending the more lines there are to deliver, unless we've just
        # sent the last line.
        $d += 25_000 * log($i+1); # will cause a 10 line response to take about 2 seconds in total to send
        usleep($d) unless $i == $#output;
    }

    # Clear content that has been sent. Error conditions/messages are left intact
    # if present, so that we can continue to send other output, while still short
    # circuiting any further list processing.
    $response->clear_content;

    return;
}

sub handle_message {
    my ($self, $msg) = @_;

    my $message;

    if ($msg->{'command'} eq 'PRIVMSG') {
        # TODO  Make sure we're handling non-nicked messages (if any) properly
        #       instead of just short-circuiting here).
        return unless exists $msg->{'prefix'} && $msg->{'prefix'} =~ m{\w+!.+}o;

        my $channel = undef;
        if (substr($msg->{'params'}->[0], 0, 1) eq '#') {
            $channel = (grep { '#' . $_->name eq $msg->{'params'}->[0] } @{$self->channels})[0];
            # TODO log messages that came from channels we don't know we're on?
            return unless defined $channel;
        }

        my $message = App::RoboBot::Message->new(
            bot     => $self->bot,
            raw     => $msg->{'params'}->[1],
            network => $self,
            sender  => $self->resolve_nick($msg->{'prefix'}),
        );

        $message->channel($channel) if defined $channel;

        $message->process;
    }
}

sub join_channel {
    my ($self, $channel) = @_;

    $self->log->info(sprintf('Joining channel #%s.', $channel->name));

    $self->client->send_srv( JOIN => '#' . $channel->name );
}

sub resolve_nick {
    my ($self, $prefix) = @_;

    my $username = (split(/!/, $prefix))[0];

    return $self->nick_cache->{$username} if exists $self->nick_cache->{$username};

    my $res = $self->config->db->do(q{ select id, name from nicks where lower(name) = lower(?) }, $username);

    if ($res && $res->next) {
        $self->nick_cache->{$username} = App::RoboBot::Nick->new(
            id     => $res->{'id'},
            name   => $res->{'name'},
            config => $self->config,
        );

        return $self->nick_cache->{$username};
    }

    $res = $self->config->db->do(q{
        insert into nicks ??? returning id, name
    }, { name => $username });

    if ($res && $res->next) {
        $self->nick_cache->{$username} = App::RoboBot::Nick->new(
            id     => $res->{'id'},
            name   => $res->{'name'},
            config => $self->config,
        );

        return $self->nick_cache->{$username};
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;
