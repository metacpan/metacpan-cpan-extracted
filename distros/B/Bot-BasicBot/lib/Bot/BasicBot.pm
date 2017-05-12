package Bot::BasicBot;
our $AUTHORITY = 'cpan:BIGPRESH';
$Bot::BasicBot::VERSION = '0.91';
use strict;
use warnings;

use Carp;
use Encode qw(encode);
use Exporter;
use IRC::Utils qw(decode_irc);
use POE::Kernel;
use POE::Session;
use POE::Wheel::Run;
use POE::Filter::Line;
use POE::Component::IRC::State;
use POE::Component::IRC::Plugin::Connector;
use Text::Wrap ();

use base 'Exporter';
our @EXPORT = qw(say emote);

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    $self->{IRCNAME} = 'wanna'.int(rand(100000));
    $self->{ALIASNAME} = 'pony'.int(rand(100000));

    # call the set methods
    my %args = @_;
    for my $method (keys %args) {
        if ($self->can($method)) {
            $self->$method($args{$method});
        }
        else {
            $self->{$method} = $args{$method};
            #croak "Invalid argument '$method'";
        }
    }
    $self->{charset} = 'utf8' if !defined $self->{charset};

    $self->init or die "init did not return a true value - dying";

    return $self;
}

sub run {
    my $self = shift;

    # create the callbacks to the object states
    POE::Session->create(
        object_states => [
            $self => {
                _start => "start_state",
                die    => "die_state",

                irc_001          => "irc_001_state",
                irc_msg          => "irc_said_state",
                irc_public       => "irc_said_state",
                irc_ctcp_action  => "irc_emoted_state",
                irc_notice       => "irc_noticed_state",

                irc_disconnected => "irc_disconnected_state",
                irc_error        => "irc_error_state",

                irc_join         => "irc_chanjoin_state",
                irc_part         => "irc_chanpart_state",
                irc_kick         => "irc_kicked_state",
                irc_nick         => "irc_nick_state",
                irc_quit         => "irc_quit_state",

                fork_close       => "fork_close_state",
                fork_error       => "fork_error_state",

                irc_366          => "names_done_state",

                irc_332          => "topic_raw_state",
                irc_topic        => "topic_state",

                irc_shutdown     => "shutdown_state",

                irc_raw          => "irc_raw_state",
                irc_raw_out      => "irc_raw_out_state",

                tick => "tick_state",
            }
        ]
    );

    # and say that we want to recive said messages
    $poe_kernel->post($self->{IRCNAME}, 'register', 'all');

    # run
    $poe_kernel->run() if !$self->{no_run};
    return;
}

sub init { return 1; }

sub said { return }

sub emoted {
    return shift->said(@_);
}

sub noticed {
    return shift->said(@_);
}

sub chanjoin { return }

sub chanpart { return }

sub got_names { return }

sub topic { return }

sub nick_change { return }

sub kicked { return }

sub tick { return 0; }

sub help { return "Sorry, this bot has no interactive help." }

sub connected { return }

sub raw_in  { return }
sub raw_out { return }

sub userquit {
    my ($self, $mess) = @_;
    return;
}

sub schedule_tick {
    my $self = shift;
    my $time = shift || 5;
    $poe_kernel->delay('tick', $time);
    return;
}

sub forkit {
    my $self = shift;
    my $args;

    if (ref($_[0])) {
        $args = shift;
    }
    else {
        my %args = @_;
        $args = \%args;
    }

    return if !$args->{run};

    $args->{handler}   = $args->{handler}   || "_fork_said";
    $args->{arguments} = $args->{arguments} || [];

    #install a new handler in the POE kernel pointing to
    # $self->{$args{handler}}
    $poe_kernel->state( $args->{handler}, $args->{callback} || $self  );

    my $run;
    if (ref($args->{run}) =~ /^CODE/) {
        $run = sub {
            $args->{run}->($args->{body}, @{ $args->{arguments} })
        };
    }
    else {
        $run = $args->{run};
    }

    my $wheel = POE::Wheel::Run->new(
        Program      => $run,
        StdoutFilter => POE::Filter::Line->new(),
        StderrFilter => POE::Filter::Line->new(),
        StdoutEvent  => "$args->{handler}",
        StderrEvent  => "fork_error",
        CloseEvent   => "fork_close"
    );

    # Use a signal handler to reap dead processes
    $poe_kernel->sig_child($wheel->PID, "got_sigchld");

    # store the wheel object in our bot, so we can retrieve/delete easily

    $self->{forks}{ $wheel->ID } = {
        wheel => $wheel,
        args  => {
            channel => $args->{channel},
            who     => $args->{who},
            address => $args->{address}
        }
    };
    return;
}

sub _fork_said {
    my ($self, $body, $wheel_id) = @_[OBJECT, ARG0, ARG1];
    chomp $body;    # remove newline necessary to move data;

    # pick up the default arguments we squirreled away earlier
    my $args = $self->{forks}{$wheel_id}{args};
    $args->{body} = $body;

    $self->say($args);
    return;
}

sub say {
    # If we're called without an object ref, then we're handling saying
    # stuff from inside a forked subroutine, so we'll freeze it, and toss
    # it out on STDOUT so that POE::Wheel::Run's handler can pick it up.
    if (!ref $_[0]) {
        print $_[0], "\n";
        return 1;
    }

    # Otherwise, this is a standard object method

    my $self = shift;
    my $args;
    if (ref $_[0]) {
        $args = shift;
    }
    else {
        my %args = @_;
        $args = \%args;
    }

    my $body = $args->{body};

    # add the "Foo: bar" at the start
    if ($args->{channel} ne "msg" && defined $args->{address}) {
        $body = "$args->{who}: $body";
    }

    # work out who we're going to send the message to
    my $who = $args->{channel} eq "msg" ? $args->{who} : $args->{channel};

    if (!defined $who || !defined $body) {
        $self->log("Can't send a message without target and body\n"
              . " called from "
              . ( [caller]->[0] )
              . " line "
              . ( [caller]->[2] ) . "\n"
              . " who = '$who'\n body = '$body'\n");
        return;
    }

    # if we have a long body, split it up..
    local $Text::Wrap::columns = 300;
    local $Text::Wrap::unexpand = 0; # no tabs
    my $wrapped = Text::Wrap::wrap('', '..', $body); #  =~ m!(.{1,300})!g;
    # I think the Text::Wrap docs lie - it doesn't do anything special
    # in list context
    my @bodies = split /\n+/, $wrapped;

    # Allows to override the default "PRIVMSG". Used by notice()
    my $irc_command = defined $args->{irc_command}
        && $args->{irc_command} eq 'notice'
        ? 'notice'
        : 'privmsg';

    # post an event that will send the message
    for my $body (@bodies) {
        my ($enc_who, $enc_body) = $self->charset_encode($who, $body);
        #warn "$enc_who => $enc_body\n";
        $poe_kernel->post(
            $self->{IRCNAME},
            $irc_command,
            $enc_who,
            $enc_body,
        );
    }

    return;
}

sub emote {
    # If we're called without an object ref, then we're handling emoting
    # stuff from inside a forked subroutine, so we'll freeze it, and
    # toss it out on STDOUT so that POE::Wheel::Run's handler can pick
    # it up.
    if (!ref $_[0]) {
        print $_[0], "\n";
        return 1;
    }

    # Otherwise, this is a standard object method

    my $self = shift;
    my $args;
    if (ref $_[0]) {
        $args = shift;
    }
    else {
        my %args = @_;
        $args = \%args;
    }

    my $body = $args->{body};

    # Work out who we're going to send the message to
    my $who = $args->{channel} eq "msg"
        ? $args->{who}
        : $args->{channel};

    # post an event that will send the message
    # if there's a better way of sending actions i'd love to know - jw
    # me too; i'll look at it in v0.5 - sb

    $poe_kernel->post(
        $self->{IRCNAME},
        'ctcp',
        $self->charset_encode($who, "ACTION $body"),
    );
    return;
}

sub notice {
    if (!ref $_[0]) {
        print $_[0], "\n";
        return 1;
    }

    my $self = shift;
    my $args;
    if (ref $_[0]) {
        $args = shift;
    }
    else {
        my %args = @_;
        $args = \%args;
    }

    # Don't modify '$args' hashref in-place, or we might
    # make all subsequent calls into notices
    return $self->say(
        %{ $args },
        irc_command => 'notice'
    );

}

sub pocoirc {
    my $self = shift;
    return $self->{IRCOBJ};
}

sub reply {
    my $self = shift;
    my ($mess, $body) = @_;
    my %hash = %$mess;
    $hash{body} = $body;
    return $self->say(%hash);
}

sub channel_data {
    my $self = shift;
    my $channel = shift or return;
    my $irc = $self->{IRCOBJ};
    my $channels = $irc->channels();
    return if !exists $channels->{$channel};

    return {
        map {
            $_ => {
                op    => $irc->is_channel_operator($channel, $_) || 0,
                voice => $irc->has_channel_voice($channel, $_) || 0,
            }
        } $irc->channel_list($channel)
    };
}

sub server {
    my $self = shift;
    $self->{server} = shift if @_;
    return $self->{server} || "irc.perl.org";
}

sub port {
    my $self = shift;
    $self->{port} = shift if @_;
    return $self->{port} || "6667";
}

sub password {
    my $self = shift;
    $self->{password} = shift if @_;
    return $self->{password} || undef;
}

sub ssl {
    my $self = shift;
    $self->{ssl} = shift if @_;
    return $self->{ssl} || 0;
}

sub localaddr {
    my $self = shift;
    $self->{localaddr} = shift if @_;
    return $self->{localaddr} || 0;
}

sub useipv6 {
    my $self = shift;
    $self->{useipv6} = shift if @_;
    return $self->{useipv6} || 0;
}

sub nick {
    my $self = shift;
    $self->{nick} = shift if @_;
    return $self->{nick} if defined $self->{nick};
    return _random_nick();
}

sub _random_nick {
    my @things = ( 'a' .. 'z' );
    return join '', ( map { @things[ rand @things ] } 0 .. 4 ), "bot";
}

sub alt_nicks {
    my $self = shift;
    if (@_) {
        # make sure we copy
        my @args = ( ref $_[0] eq "ARRAY" ) ? @{ $_[0] } : @_;
        $self->{alt_nicks} = \@args;
    }
    return @{ $self->{alt_nicks} || [] };
}

sub username {
    my $self = shift;
    $self->{username} = shift if @_;
    return defined $self->{username} ? $self->{username} : $self->nick;
}

sub name {
    my $self = shift;
    $self->{name} = shift if @_;
    return defined $self->{name} ? $self->{name} : $self->nick . " bot";
}

sub channels {
    my $self = shift;
    if (@_) {
        # make sure we copy
        my @args = ( ref $_[0] eq "ARRAY" ) ? @{ $_[0] } : @_;
        $self->{channels} = \@args;
    }
    return @{ $self->{channels} || [] };
}

sub quit_message {
    my $self = shift;
    $self->{quit_message} = shift if @_;
    return defined $self->{quit_message} ? $self->{quit_message} : "Bye";
}

sub ignore_list {
    my $self = shift;
    if (@_) {
        # make sure we copy
        my @args = ( ref $_[0] eq "ARRAY" ) ? @{ $_[0] } : @_;
        $self->{ignore_list} = \@args;
    }
    return @{ $self->{ignore_list} || [] };
}

sub charset {
    my $self = shift;
    if (@_) {
        $self->{charset} = shift;
    }
    return $self->{charset};
}

sub flood {
    my $self = shift;
    $self->{flood} = shift if @_;
    return $self->{flood};
}

sub no_run {
    my $self = shift;
    $self->{no_run} = shift if @_;
    return $self->{no_run};
}

sub start_state {
    my ($self, $kernel, $session) = @_[OBJECT, KERNEL, SESSION];
    $kernel->sig('DIE', 'die');
    $self->{session} = $session;

    # Make an alias for our session, to keep it from getting GC'ed.
    $kernel->alias_set($self->{ALIASNAME});
    $kernel->delay('tick', 30);

    $self->{IRCOBJ} = POE::Component::IRC::State->spawn(
        alias => $self->{IRCNAME},
    );
    $self->{IRCOBJ}->plugin_add(
        'Connector',
        POE::Component::IRC::Plugin::Connector->new(),
    );
    $kernel->post($self->{IRCNAME}, 'register', 'all');

    $kernel->post(
	$self->{IRCNAME},
	'connect',
	{
	    Nick      => $self->nick,
	    Server    => $self->server,
	    Port      => $self->port,
	    Password  => $self->password,
	    UseSSL    => $self->ssl,
	    Flood     => $self->flood,
	    LocalAddr => $self->localaddr,
            useipv6   => $self->useipv6,
	    $self->charset_encode(
		Nick     => $self->nick,
		Username => $self->username,
		Ircname  => $self->name,
	    ),
	},
    );

    return;
}

sub die_state {
    my ($kernel, $self, $ex) = @_[KERNEL, OBJECT, ARG1];
    warn $ex->{error_str};
    $self->{IRCOBJ}->yield('shutdown');
    $kernel->sig_handled();
    return;
}

sub irc_001_state {
    my ($self, $kernel) = @_[OBJECT, KERNEL];

    # ignore all messages from ourselves
    $kernel->post(
        $self->{IRCNAME},
        'ignore',
        $self->charset_encode($self->nick),
    );

    # connect to the channel
    for my $channel ($self->channels) {
        $self->log("Trying to connect to '$channel'\n");
        $kernel->post(
            $self->{IRCNAME},
            'join',
            $self->charset_encode($channel),
        );
    }

    $self->schedule_tick(5);
    $self->connected();
    return;
}

sub irc_disconnected_state {
    my ($self, $kernel, $server) = @_[OBJECT, KERNEL, ARG0];
    $self->log("Lost connection to server $server.\n");
    return;
}

sub irc_error_state {
    my ($self, $err, $kernel) = @_[OBJECT, ARG0, KERNEL];
    $self->log("Server error occurred! $err\n");
    return;
}

sub irc_kicked_state {
    my ($self, $kernel, $heap, $session) = @_[OBJECT, KERNEL, HEAP, SESSION];
    my ($nickstring, $channel, $kicked, $reason) = @_[ARG0..$#_];
    my $nick = $self->nick_strip($nickstring);
    $_[OBJECT]->_remove_from_channel( $channel, $kicked );
    $self->kicked(
        {
            channel => $channel,
            who     => $nick,
            kicked  => $kicked,
            reason  => $reason,
        }
    );
    return;
}

sub irc_join_state {
    my ($self, $nick) = @_[OBJECT, ARG0];
    return;
}

sub irc_nick_state {
    my ($self, $nick, $newnick) = @_[OBJECT, ARG0, ARG1];
    $nick = $self->nick_strip($nick);
    $self->nick_change($nick, $newnick);
    return;
}

sub irc_quit_state {
    my ($self, $kernel, $session) = @_[OBJECT, KERNEL, SESSION];
    my ($nick, $message) = @_[ARG0..$#_];

    $nick = $self->nick_strip($nick);
    $self->userquit({ who => $nick, body => $message });
    return;
}

sub irc_said_state {
    irc_received_state( 'said', 'say', @_ );
    return;
}

sub irc_emoted_state {
    irc_received_state( 'emoted', 'emote', @_ );
    return;
}

sub irc_noticed_state {
    irc_received_state( 'noticed', 'emote', @_ );
    return;
}

sub irc_received_state {
    my $received = shift;
    my $respond  = shift;
    my ($self, $nick, $to, $body) = @_[OBJECT, ARG0, ARG1, ARG2];

    ($nick, $to, $body) = $self->charset_decode($nick, $to, $body);

    my $return;
    my $mess = {};

    # pass the raw body through
    $mess->{raw_body} = $body;

    # work out who it was from
    $mess->{who} = $self->nick_strip($nick);
    $mess->{raw_nick} = $nick;

    # right, get the list of places this message was
    # sent to and work out the first one that we're
    # either a memeber of is is our nick.
    # The IRC protocol allows messages to be sent to multiple
    # targets, which is pretty clever. However, noone actually
    # /does/ this, so we can get away with this:

    my $channel = $to->[0];
    if (lc($channel) eq lc($self->nick)) {
        $mess->{channel} = "msg";
        $mess->{address} = "msg";
    }
    else {
        $mess->{channel} = $channel;
    }

    # okay, work out if we're addressed or not

    $mess->{body} = $body;
    if ($mess->{channel} ne "msg") {
        my $own_nick = $self->nick;

        if ($mess->{body} =~ s/^(\Q$own_nick\E)\s*[:,-]?\s*//i) {
          $mess->{address} = $1;
        }

        for my $alt_nick ($self->alt_nicks) {
            last if $mess->{address};
            if ($mess->{body} =~ s/^(\Q$alt_nick\E)\s*[:,-]?\s*//i) {
              $mess->{address} = $1;
            }
        }
    }

    # strip off whitespace before and after the message
    $mess->{body} =~ s/^\s+//;
    $mess->{body} =~ s/\s+$//;

    # check if someone was asking for help
    if ($mess->{address} && $mess->{body} =~ /^help/i) {
        $mess->{body} = $self->help($mess) or return;
        $self->say($mess);
        return;
    }

    # okay, call the said/emoted method
    $return = $self->$received($mess);

    ### what did we get back?

    # nothing? Say nothing then
    return if !defined $return;

    # a string?  Say it how we were addressed then
    if (!ref $return && length $return) {
        $mess->{body} = $return;
        $self->$respond($mess);
        return;
    }
}

sub irc_chanjoin_state {
    my $self = $_[OBJECT];
    my ($channel, $nick) = @_[ ARG1, ARG0 ];
    $nick = $_[OBJECT]->nick_strip($nick);

    if ($self->nick eq $nick) {
      my @channels = $self->channels;
      push @channels, $channel unless grep { $_ eq $channel } @channels;
      $self->channels(\@channels);
    }
    irc_chan_received_state('chanjoin', 'say', @_);
    return;
}

sub irc_chanpart_state {
    my $self = $_[OBJECT];
    my ($channel, $nick) = @_[ ARG1, ARG0 ];
    $nick = $_[OBJECT]->nick_strip($nick);

    if ($self->nick eq $nick) {
      my @channels = $self->channels;
      @channels = grep { $_ ne $channel } @channels;
      $self->channels(\@channels);
    }
    irc_chan_received_state('chanpart', 'say', @_);
    return;
}

sub irc_chan_received_state {
    my $received = shift;
    my $respond  = shift;
    my ($self, $nick, $channel) = @_[OBJECT, ARG0, ARG1];

    my $return;
    my $mess = {};
    $mess->{who} = $self->nick_strip($nick);
    $mess->{raw_nick} = $nick;

    $mess->{channel} = $channel;
    $mess->{body} = $received; #chanjoin or chanpart
    $mess->{address} = "chan";

    # okay, call the chanjoin/chanpart method
    $return = $self->$received($mess);

    ### what did we get back?

    # nothing? Say nothing then
    return if !defined $return;

    # a string?  Say it how we were addressed then
    if (!ref $return) {
        $mess->{body} = $return;
        $self->$respond($mess);
        return;
    }
}


sub fork_close_state {
    my ($self, $wheel_id) = @_[OBJECT, ARG0];
    delete $self->{forks}{$wheel_id};
    return;
}

sub fork_error_state { }

sub tick_state {
    my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
    my $delay = $self->tick();
    $self->schedule_tick($delay) if $delay;
    return;
}

sub names_done_state {
    my ($self, $kernel, $server, $message) = @_[OBJECT, KERNEL, ARG0, ARG1];
    my ($channel) = split /\s/, $message;
    $self->got_names(
        {
            channel => $channel,
            names   => $self->channel_data($channel),
        }
    );
  return;
}

sub topic_raw_state {
    my ($self, $kernel, $server, $raw) = @_[OBJECT, KERNEL, ARG0, ARG1];
    my ($channel, $topic) = split / :/, $raw, 2;
    $self->topic(
        {
            channel => $channel,
            who     => undef,
            topic   => $topic,
        }
    );
    return;
}

sub topic_state {
    my ($self, $kernel, $nickraw, $channel, $topic)
        = @_[OBJECT, KERNEL, ARG0, ARG1, ARG2];
    my $nick = $self->nick_strip($nickraw);
    $self->topic(
        {
            channel => $channel,
            who     => $nick,
            topic   => $topic,
        }
    );
    return;
}

sub shutdown_state {
    my ($kernel, $self) = @_[KERNEL, OBJECT];
    $kernel->delay('tick');
    $kernel->alias_remove($self->{ALIASNAME});
    for my $fork (values %{ $self->{forks} }) {
        $fork->{wheel}->kill();
    }
    return;
}


sub irc_raw_state { 
    my ($self, $kernel, $raw_line) = @_[OBJECT, KERNEL, ARG0];
    $self->raw_in($raw_line);
}
sub irc_raw_out_state {
    my ($self, $kernel, $raw_line) = @_[OBJECT, KERNEL, ARG0];
    $self->raw_out($raw_line);
}



sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;
    $AUTOLOAD =~ s/.*:://;
    $poe_kernel->post(
        $self->{IRCNAME},
        $AUTOLOAD,
        $self->charset_encode(@_),
    );
    return;
}

# so it won't get AUTOLOADed
sub DESTROY { return }

sub log {
    my $self = shift;
    for (@_) {
      my $log_entry = $_;
      chomp $log_entry;
      print STDERR "$log_entry\n";
    }
    return;
}

sub ignore_nick {
    local $_ = undef;
    my $self = shift;
    my $nick = shift;
    return grep { $nick eq $_ } @{ $self->{ignore_list} };
}

sub nick_strip {
    my $self = shift;
    my $combined = shift || "";
    my ($nick) = $combined =~ m/(.*?)!/;
    return $nick;
}

sub charset_decode {
    my $self = shift;

    my @r;
    for (@_) {
        if (ref($_) eq 'ARRAY') {
            push @r, [ $self->charset_decode(@$_) ];
        }
        elsif (ref($_) eq "HASH") {
            push @r, { $self->charset_decode(%$_) };
        }
        elsif (ref($_)) {
            die "Can't decode object $_\n";
        }
        else {
            push @r, decode_irc($_);
        }
    }
    #warn Dumper({ decoded => \@r });
    return @r;
}

sub charset_encode {
    my $self = shift;

    my @r;
    for (@_) {
        if (ref($_) eq 'ARRAY') {
            push @r, [ $self->charset_encode(@$_) ];
        }
        elsif (ref($_) eq "HASH") {
            push @r, { $self->charset_encode(%$_) };
        }
        elsif (ref($_)) {
            die "Can't encode object $_\n";
        }
        else {
            push @r, encode($self->charset, $_);
        }
    }
    #warn Dumper({ encoded => \@r });
    return @r;
}

1;

=head1 NAME

Bot::BasicBot - simple irc bot baseclass

=head1 SYNOPSIS

  #!/usr/bin/perl
  use strict;
  use warnings;

  # Subclass Bot::BasicBot to provide event-handling methods.
  package UppercaseBot;
  use base qw(Bot::BasicBot);

  sub said {
      my $self      = shift;
      my $arguments = shift;    # Contains the message that the bot heard.

      # The bot will respond by uppercasing the message and echoing it back.
      $self->say(
          channel => $arguments->{channel},
          body    => uc $arguments->{body},
      );

      # The bot will shut down after responding to a message.
      $self->shutdown('I have done my job here.');
  }

  # Create an object of your Bot::BasicBot subclass and call its run method.
  package main;

  my $bot = UppercaseBot->new(
      server      => 'irc.example.com',
      port        => '6667',
      channels    => ['#bottest'],
      nick        => 'UppercaseBot',
      name        => 'John Doe',
      ignore_list => [ 'laotse', 'georgeburdell' ],
  );
  $bot->run();

=head1 DESCRIPTION

Basic bot system designed to make it easy to do simple bots, optionally
forking longer processes (like searches) concurrently in the background.

There are several examples of bots using Bot::BasicBot in the examples/
folder in the Bot::BasicBot tarball.

A quick summary, though - You want to define your own package that
subclasses Bot::BasicBot, override various methods (documented below),
then call L<C<new>|/new> and L<C<run>|/run> on it.

=head1 STARTING THE BOT

=head2 C<new>

Creates a new instance of the class. Key/value pairs may be passed
which will have the same effect as calling the method of that name
with the value supplied. Returns a Bot::BasicBot object, that you can
call 'run' on later.

eg:

  my $bot = Bot::BasicBot->new( nick => 'superbot', channels => [ '#superheroes' ] );

=head2 C<run>

Runs the bot.  Hands the control over to the POE core.

=head1 STOPPING THE BOT

To shut down the bot cleanly, use the L<C<shutdown>|/shutdown> method,
which will (through L<C<AUTOLOAD>|/AUTOLOAD>) send an
L<event|POE::Component::IRC/shutdown> of the same name to
POE::Component::IRC, so it takes the same arguments:

 $bot->shutdown( $bot->quit_message() );

=head1 METHODS TO OVERRIDE

In your Bot::BasicBot subclass, you want to override some of the following
methods to define how your bot works. These are all object methods - the
(implicit) first parameter to all of them will be the bot object.

=head2 C<init>

called when the bot is created, as part of new(). Override to provide
your own init. Return a true value for a successful init, or undef if
you failed, in which case new() will die.

=head2 C<said>

This is the main method that you'll want to override in your subclass -
it's the one called by default whenever someone says anything that we
can hear, either in a public channel or to us in private that we
shouldn't ignore.

You'll be passed a hashref that contains the arguments described below. 
Feel free to alter the values of this hash - it won't be used later on.

=over 4

=item who

Who said it (the nick that said it)

=item raw_nick

The raw IRC nick string of the person who said it. Only really useful
if you want more security for some reason.

=item channel

The channel in which they said it.  Has special value "msg" if it was in
a message.  Actually, you can send a message to many channels at once in
the IRC spec, but no-one actually does this so this is just the first
one in the list.

=item body

The body of the message (i.e. the actual text)

=item address

The text that indicates how we were addressed.  Contains the string
"msg" for private messages, otherwise contains the string off the text
that was stripped off the front of the message if we were addressed,
e.g. "Nick: ".  Obviously this can be simply checked for truth if you
just want to know if you were addressed or not.

=back

You should return what you want to say.  This can either be a simple
string (which will be sent back to whoever was talking to you as a
message or in public depending on how they were talking) or a hashref
that contains values that are compatible with say (just changing
the body and returning the structure you were passed works very well.)

Returning undef will cause nothing to be said.

=head2 C<emoted>

This is a secondary method that you may wish to override. It gets called
when someone in channel 'emotes', instead of talking. In its default
configuration, it will simply pass anything emoted on channel through to
the C<said> handler.

C<emoted> receives the same data hash as C<said>.

=head2 C<noticed>

This is like C<said>, except for notices instead of normal messages.

=head2 C<chanjoin>

Called when someone joins a channel. It receives a hashref argument
similar to the one received by said(). The key 'who' is the nick of the
user who joined, while 'channel' is the channel they joined.

This is a do-nothing implementation, override this in your subclass.

=head2 C<chanpart>

Called when someone parts a channel. It receives a hashref argument
similar to the one received by said(). The key 'who' is the nick of the
user who parted, while 'channel' is the channel they parted.

This is a do-nothing implementation, override this in your subclass.

=head2 C<got_names>

Whenever we have been given a definitive list of 'who is in the channel',
this function will be called. It receives a hash reference as an argument.
The key 'channel' will be the channel we have information for, 'names' is a
hashref where the keys are the nicks of the users, and the values are more
hashes, containing the two keys 'op' and 'voice', indicating if the user is
a chanop or voiced respectively.

The reply value is ignored.

Normally, I wouldn't override this method - instead, just use the L<names>
call when you want to know who's in the channel. Override this only if you
want to be able to do something as soon as possible. Also be aware that
the names list can be changed by other events - kicks, joins, etc, and this
method won't be called when that happens.

=head2 C<topic>

Called when the topic of the channel changes. It receives a hashref
argument. The key 'channel' is the channel the topic was set in, and 'who'
is the nick of the user who changed the channel, 'topic' will be the new
topic of the channel.

=head2 C<nick_change>

When a user changes nicks, this will be called. It receives two arguments:
the old nickname and the new nickname.

=head2 C<kicked>

Called when a user is kicked from the channel. It receives a hashref which
will look like this:

  {
    channel => "#channel",
    who => "nick",
    kicked => "kicked",
    reason => "reason",
  }

The reply value is ignored.

=head2 C<tick>

This is an event called every regularly. The function should return the
amount of time until the tick event should next be called. The default
tick is called 5 seconds after the bot starts, and the default
implementation returns '0', which disables the tick. Override this and
return non-zero values to have an ongoing tick event.

Use this function if you want the bot to do something periodically, and
don't want to mess with 'real' POE things.

Call the L<schedule_tick> event to schedule a tick event without waiting
for the next tick.

=head2 C<help>

This is the other method that you should override.  This is the text
that the bot will respond to if someone simply says help to it.  This
should be considered a special case which you should not attempt to
process yourself.  Saying help to a bot should have no side effects
whatsoever apart from returning this text.

=head2 C<connected>

An optional method to override, gets called after we have connected
to the server

=head2 C<userquit>

Receives a hashref which will look like:

    {
      who => "nick that quit",
      body => "quit message",
    }

=head1 BOT METHODS

There are a few methods you can call on the bot object to do things. These
are as follows:

=head2 C<schedule_tick>

Takes an integer as an argument. Causes the L<tick> event to be called
after that many seconds (or 5 seconds if no argument is provided). Note
that if the tick event is due to be called already, this will override it.
You can't schedule multiple future events with this funtction.

=head2 C<forkit>

This method allows you to fork arbitrary background processes. They
will run concurrently with the main bot, returning their output to a
handler routine. You should call C<forkit> in response to specific
events in your C<said> routine, particularly for longer running
processes like searches, which will block the bot from receiving or
sending on channel whilst they take place if you don't fork them.

Inside the subroutine called by forkit, you can send output back to the
channel by printing lines (followd by C<\n>) to STDOUT. This has the same
effect as calling L<C<< Bot::BasicBot->say >>|say>.

C<forkit> takes the following arguments:

=over 4

=item run

A coderef to the routine which you want to run. Bear in mind that the
routine doesn't automatically get the text of the query - you'll need
to pass it in C<arguments> (see below) if you want to use it at all.

Apart from that, your C<run> routine just needs to print its output to
C<STDOUT>, and it will be passed on to your designated handler.

=item handler

Optional. A method name within your current package which we can
return the routine's data to. Defaults to the built-in method
C<say_fork_return> (which simply sends data to channel).

=item callback

Optional. A coderef to execute in place of the handler. If used, the value
of the handler argument is used to name the POE event. This allows using
closures and/or having multiple simultanious calls to forkit with unique
handler for each call.

=item body

Optional. Use this to pass on the body of the incoming message that
triggered you to fork this process. Useful for interactive proceses
such as searches, so that you can act on specific terms in the user's
instructions.

=item who

The nick of who you want any response to reach (optional inside a
channel.)

=item channel

Where you want to say it to them in.  This may be the special channel
"msg" if you want to speak to them directly

=item address

Optional.  Setting this to a true value causes the person to be
addressed (i.e. to have "Nick: " prepended to the front of returned
message text if the response is going to a public forum.

=item arguments

Optional. This should be an anonymous array of values, which will be
passed to your C<run> routine. Bear in mind that this is not
intelligent - it will blindly spew arguments at C<run> in the order
that you specify them, and it is the responsibility of your C<run>
routine to pick them up and make sense of them.

=back

=head2 C<say>

Say something to someone. Takes a list of key/value pairs as arguments.
You should pass the following arguments:

=over 4

=item who

The nick of who you are saying this to (optional inside a channel.)

=item channel

Where you want to say it to them in.  This may be the special channel
"msg" if you want to speak to them directly

=item body

The body of the message.  I.e. what you want to say.

=item address

Optional.  Setting this to a true value causes the person to be
addressed (i.e. to have "Nick: " prepended to the front of the message
text if this message is going to a pulbic forum.

=back

You can also make non-OO calls to C<say>, which will be interpreted as
coming from a process spawned by C<forkit>. The routine will serialise
any data it is sent, and throw it to STDOUT, where L<POE::Wheel::Run> can
pass it on to a handler.

=head2 C<emote>

C<emote> will return data to channel, but emoted (as if you'd said "/me
writes a spiffy new bot" in most clients). It takes the same arguments
as C<say>, listed above.

=head2 C<notice>

C<notice> will send a IRC notice to the channel. This is typically used by
bots to not break the IRC conversations flow. The message will appear as:

    -nick- message here

It takes the same arguments as C<say>, listed above. Example:

    $bot->notice(
        channel => '#bot_basicbot_test',
        body => 'This is a notice'
    );

=head2 C<reply>

Takes two arguments, a hashref containing information about an incoming
message, and a reply message. It will reply in a privmsg if the incoming
one was a privmsg, in channel if not, and with prefixes if the incoming
one was prefixed. Mostly a shortcut method - it's roughly equivalent to

 $mess->{body} = $body;
 $self->say($mess);

=head2 C<pocoirc>

Takes no arguments. Returns the underlying
L<POE::Component::IRC::State|POE::Component::IRC::State> object used by
Bot::BasicBot. Useful for accessing various state methods and for posting
commands to the component. For example:

 # get the list of nicks in the channel #someplace
 my @nicks = $bot->pocoirc->channel_list("#someplace");

 # join the channel #otherplace
 $bot->pocoirc->yield('join', '#otherplace');

=head2 C<channel_data>

Takes a channel names as a parameter, and returns a hash of hashes. The
keys are the nicknames in the channel, the values are hashes containing
the keys "voice" and "op", indicating whether these users are voiced or
opped in the channel. This method is only here for backwards compatability.
You'll probably get more use out of
L<POE::Component::IRC::State|POE::Component::IRC::State>'s methods (which
this method is merely a wrapper for). You can access the
POE::Component::IRC::State object through Bot::BasicBot's C<pocoirc>
method.

=head1 ATTRIBUTES

Get or set methods.  Changing most of these values when connected
won't cause sideffects.  e.g. changing the server will not
cause a disconnect and a reconnect to another server.

Attributes that accept multiple values always return lists and
either accept an arrayref or a complete list as an argument.

The usual way of calling these is as keys to the hash passed to the
'new' method.

=head2 C<server>

The server we're going to connect to.  Defaults to
"irc.perl.org".

=head2 C<port>

The port we're going to use.  Defaults to "6667"

=head2 C<password>

The server password for the server we're going to connect to.  Defaults to
undef.

=head2 C<ssl>

A boolean to indicate whether or not the server we're going to connect to
is an SSL server.  Defaults to 0.

=head2 C<localaddr>

The local address to use, for multihomed boxes.  Defaults to undef (use whatever
source IP address the system deigns is appropriate).

=head2 C<useipv6>

A boolean to indicate whether IPv6 should be used.  Defaults to undef (use
IPv4).

=head2 C<nick>

The nick we're going to use.  Defaults to five random letters
and numbers followed by the word "bot"

=head2 C<alt_nicks>

Alternate nicks that this bot will be known by.  These are not nicks
that the bot will try if it's main nick is taken, but rather other
nicks that the bot will recognise if it is addressed in a public
channel as the nick.  This is useful for bots that are replacements
for other bots...e.g, your bot can answer to the name "infobot: "
even though it isn't really.

=head2 C<username>

The username we'll claim to have at our ip/domain.  By default this
will be the same as our nick.

=head2 C<name>

The name that the bot will identify itself as.  Defaults to
"$nick bot" where $nick is the nick that the bot uses.

=head2 C<channels>

The channels we're going to connect to.

=head2 C<quit_message>

The quit message.  Defaults to "Bye".

=head2 C<ignore_list>

The list of irc nicks to ignore B<public> messages from (normally
other bots.)  Useful for stopping bot cascades.

=head2 C<charset>

IRC has no defined character set for putting high-bit chars into channel.
This attribute sets the encoding to be used for outgoing messages. Defaults
to 'utf8'.

=head2 C<flood>

Set to '1' to disable the built-in flood protection of POE::Compoent::IRC

=head2 C<no_run>

Tells Bot::BasicBot to B<not> run the L<POE kernel|POE::Kernel> at the end
of L<C<run>|/run>, in case you want to do that yourself.

=head1 OTHER METHODS

=head2 C<AUTOLOAD>

Bot::BasicBot implements AUTOLOAD for sending arbitrary states to the
underlying L<POE::Component::IRC|POE::Component::IRC> component. So for a
C<$bot> object, sending

    $bot->foo("bar");

is equivalent to

    $poe_kernel->post(BASICBOT_ALIAS, "foo", "bar");

=head2 C<log>

Logs the message. This method merely prints to STDERR - If you want smarter
logging, override this method - it will have simple text strings passed in
@_.

=head2 C<ignore_nick>

Takes a nick name as an argument. Return true if this nick should be
ignored. Ignores anything in the ignore list

=head2 C<nick_strip>

Takes a nick and hostname (of the form "nick!hostname") and
returns just the nick

=head2 C<charset_decode>

Converts a string of bytes from IRC (uses
L<C<decode_irc>|IRC::Utils/decode_irc> from L<IRC::Utils|IRC::Utils>
internally) and returns a Perl string.

It can also takes a list (or arrayref or hashref) of strings, and return
a list of strings

=head2 C<charset_encode>

Converts a list of perl strings into a list of byte sequences, using
the bot's charset. See L<C<charset_decode>|/charset_decode>.

=head1 HELP AND SUPPORT

If you have any questions or issues, you can drop by in #poe or
#bot-basicbot @ irc.perl.org, where I (Hinrik) am usually around.

=head1 AUTHOR

Tom Insam E<lt>tom@jerakeen.orgE<gt>

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 CREDITS

The initial version of Bot::BasicBot was written by Mark Fowler,
and many thanks are due to him.

Nice code for dealing with emotes thanks to Jo Walsh.

Various patches from Tom Insam, including much improved rejoining,
AUTOLOAD stuff, better interactive help, and a few API tidies.

Maintainership for a while was in the hands of Simon Kent
E<lt>simon@hitherto.netE<gt>. Don't know what he did. :-)

I (Tom Insam) recieved patches for tracking joins and parts from Silver,
sat on them for two months, and have finally applied them. Thanks, dude.
He also sent me changes for the tick event API, which made sense.

In November 2010, maintainership moved to Hinrik E<Ouml>rn
SigurE<eth>sson (L<hinrik.sig@gmail.com>).

In April 2017, maintainership moved to David Precious
(L<davidp@preshweb.co.uk>).

=head1 SEE ALSO

L<POE>, L<POE::Component::IRC>

Possibly Infobot, at http://www.infobot.org

=cut
