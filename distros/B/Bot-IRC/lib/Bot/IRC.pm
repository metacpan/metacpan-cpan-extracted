package Bot::IRC;
# ABSTRACT: Yet Another IRC Bot

use 5.014;
use strict;
use warnings;

use Carp 'croak';
use Daemon::Device;
use IO::Socket;
use IO::Socket::SSL;
use Time::Crontab;
use Date::Format 'time2str';
use Encode 'encode';
use Try::Tiny;

our $VERSION = '1.25'; # VERSION

sub new {
    my $class = shift;
    my $self  = bless( {@_}, $class );

    croak('Odd number of elements passed to new()') if ( @_ % 2 );
    croak('connect/server not provided to new()')
        unless ( ref $self->{connect} eq 'HASH' and $self->{connect}{server} );

    $self->{spawn} ||= 2;

    $self->{connect}{nick} //= 'bot';
    $self->{connect}{name} //= 'Yet Another IRC Bot';
    $self->{connect}{port} ||= 6667;

    $self->{daemon}           //= {};
    $self->{daemon}{name}     //= $self->{connect}{nick};
    $self->{daemon}{pid_file} //= $self->{daemon}{name} . '.pid';

    $self->{nick} = $self->{connect}{nick};

    $self->{hooks}  = [];
    $self->{ticks}  = [];
    $self->{helps}  = {};
    $self->{loaded} = {};

    $self->{send_user_nick} ||= 'on_parent';
    croak('"send_user_nick" optional value set to invalid value') if (
        $self->{send_user_nick} ne 'on_connect' and
        $self->{send_user_nick} ne 'on_parent' and
        $self->{send_user_nick} ne 'on_reply'
    );

    $self->load(
        ( ref $self->{plugins} eq 'ARRAY' ) ? @{ $self->{plugins} } : $self->{plugins}
    ) if ( $self->{plugins} );

    return $self;
}

sub run {
    my $self     = shift;
    my $commands = \@_;

    $self->{socket} = ( ( $self->{connect}{ssl} ) ? 'IO::Socket::SSL' : 'IO::Socket::INET' )->new(
        PeerAddr        => $self->{connect}{server},
        PeerPort        => $self->{connect}{port},
        Proto           => 'tcp',
        Type            => SOCK_STREAM,
        SSL_verify_mode => SSL_VERIFY_NONE,
    ) or die $!;

    if ( $self->{send_user_nick} eq 'on_connect' ) {
        $self->{socket}->print("USER $self->{nick} 0 * :$self->{connect}{name}\r\n");
        $self->{socket}->print("NICK $self->{nick}\r\n");
    }

    try {
        $self->{device} = Daemon::Device->new(
            parent     => \&_parent,
            child      => \&_child,
            on_message => \&_on_message,
            spawn      => $self->{spawn},
            daemon     => $self->{daemon},
            data       => {
                self     => $self,
                commands => $commands,
                passwd   => $self->{passwd},
            },
        );
    }
    catch {
        croak("Daemon device instantiation failure: $_");
    };

    $self->{device}->run;
}

sub note {
    my ( $self, $msg, $err ) = @_;
    chomp($msg);
    $msg = '[' . time2str( '%d/%b/%Y:%H:%M:%S %z', time() ) . '] ' . encode( 'utf-8' => $msg ) . "\n";

    if ($err) {
        die $msg if ( $err eq 'die' );
        warn $msg;
    }
    else {
        print $msg;
    }

    return;
}

sub _parent {
    my ($device) = @_;
    my $self     = $device->data('self');
    my $session  = { start => time };
    my $delegate = sub {
        my ($random_child) =
            map { $_->[0] }
            sort { $a->[1] <=> $b->[1] }
            map { [ $_, rand() ] }
            @{ $device->children };

        $device->message( $random_child, @_ );
    };

    local $SIG{ALRM} = sub {
        alarm 1;
        my $time = time;

        for (
            grep {
                ref $_->{timing} and ( $time % 60 == 0 ) and $_->{timing}->match($time) or
                not ref $_->{timing} and ( ( $time - $session->{start} ) % $_->{timing} == 0 )
            } @{ $self->{ticks} }
        ) {
            try {
                $_->{code}->($self);
            }
            catch {
                warn "Tick execution failure: $_\n";
            };
        }
    };

    local $SIG{__WARN__} = sub { note( undef, $_[0], 'warn' ) };
    local $SIG{__DIE__}  = sub { note( undef, $_[0], 'die'  ) };

    srand();
    my @lines;

    try {
        if ( $self->{send_user_nick} eq 'on_parent' ) {
            $self->say("USER $self->{nick} 0 * :$self->{connect}{name}");
            $self->say("NICK $self->{nick}");
        }

        while ( my $line = $self->{socket}->getline ) {
            $line =~ s/\003\d{2}(?:,\d{2})?//g; # remove IRC color codes
            $line =~ tr/\000-\037//d;           # remove all control characters

            $self->note($line);
            chomp($line);

            if ( not $session->{established} ) {
                if ( $line =~ /^ERROR.+onnect\w+ too fast/ ) {
                    warn "$line\n";
                    warn "Sleeping 20 and retrying...\n";
                    sleep 20;
                    $device->daemon->do_restart;
                }
                elsif ( $line =~ /^ERROR\s/ ) {
                    warn "$line\n";
                    $device->daemon->do_stop;
                }
                elsif ( not $session->{user} ) {
                    if ( $self->{send_user_nick} eq 'on_reply' ) {
                        $self->say("USER $self->{nick} 0 * :$self->{connect}{name}");
                        $self->say("NICK $self->{nick}");
                    }
                    elsif ( $self->{send_user_nick} eq 'on_connect' ) {
                        $self->note("<<< USER $self->{nick} 0 * :$self->{connect}{name}\r\n");
                        $self->note("<<< NICK $self->{nick}\r\n");
                    }
                    $session->{user} = 1;
                }
                elsif ( $line =~ /^:\S+\s433\s/ ) {
                    $self->nick( $self->{nick} . '_' );
                }
                elsif ( $line =~ /^:\S+\s001\s/ ) {
                    $self->say($_) for ( map {
                        my $command = $_;
                        $command =~ s|^/msg |PRIVMSG |;
                        $command =~ s|^/(\w+)|uc($1)|e;
                        $command;
                    } @{ $device->data('commands') } );

                    $self->join;
                    $session->{established} = 1;
                    alarm 1 if ( @{ $self->{ticks} } );
                }
            }

            shift @lines while ( @lines > 10 );
            my $now = time();

            unless ( grep { $_->{line} eq $line and $_->{time} + 1 > $now } @lines ) {
                $delegate->($line);
            }
            else {
                $self->note("### Skipped repeated line: $line");
            }

            push @lines, { line => $line, time => $now };
        }
    }
    catch {
        warn "Daemon parent loop failure: $_\n";
        kill( 'KILL', $_ ) for ( @{ $device->children } );
    };
}

sub _child {
    local $SIG{__WARN__} = sub { note( undef, $_[0], 'warn' ) };
    local $SIG{__DIE__}  = sub { note( undef, $_[0], 'die'  ) };

    srand();
    sleep 1 while (1);
}

sub _on_message {
    my $device = shift;
    my $self   = $device->data('self');
    my $passwd = $device->data('passwd');

    for my $line (@_) {
        if ( $line =~ /^>>>\sNICK\s(.*)/ ) {
            $self->{nick} = $1;
            next;
        }
        elsif ( $line =~ /^:\S+\s433\s/ ) {
            $self->nick( $self->{nick} . '_' );
            next;
        }

        $self->{in} = { map { $_ => '' } qw( line source nick user server command forum text ) };
        $self->{in}{$_} = 0 for ( qw( private to_me ) );
        $self->{in}{line} = $line;

        if ( $line =~ /^(ERROR)\s/ ) {
            warn $line . "\n";
        }
        elsif ( $line =~ /^:(\S+?)!~?(\S+?)@(\S+?)\s(\S+)\s(\S+)\s:(.*)/ ) {
            @{ $self->{in} }{ qw( nick user server command forum text ) } = ( $1, $2, $3, $4, $5, $6 );
            $self->{in}{full_text} = $self->{in}{text};
        }
        elsif ( $line =~ /^:(\S+?)!~?(\S+?)@(\S+?)\s(\S+)\s:(.*)/ ) {
            @{ $self->{in} }{ qw( nick user server command text ) } = ( $1, $2, $3, $4, $5 );
            ( $self->{in}{forum} = $self->{in}{text} ) =~ s/^://
                if ( $self->{in}{command} eq 'JOIN' or $self->{in}{command} eq 'PART' );
        }
        elsif ( $line =~ /^:(\S+?)!~?(\S+?)@(\S+?)\s(\S+)\s(\S+)\s(.*)/ ) {
            @{ $self->{in} }{ qw( nick user server command forum text ) } = ( $1, $2, $3, $4, $5, $6 );
        }
        elsif ( $line =~ /^:(\S+?)!~?(\S+?)@(\S+?)\s(\S+)\s(\S+)/ ) {
            @{ $self->{in} }{ qw( nick user server command forum ) } = ( $1, $2, $3, $4, $5, $6 );
        }
        elsif ( $line =~ /^(PING)\s(.+)/ ) {
            @{ $self->{in} }{ qw( command text ) } = ( $1, $2 );
            $self->say( 'PONG ' . $self->{in}{text} );
            next;
        }
        elsif ( $line =~ /^:(\S+)\s([A-Z]+|\d+)\s(\S+)\s(.*)/ ) {
            @{ $self->{in} }{ qw( source command forum text ) } = ( $1, $2, $3, $4 );
        }
        else {
            warn 'Unparsed line (probably a bug in Bot::IRC; please report it): ', $line . "\n";
        }

        next unless ( $self->{in}{nick} ne $self->{nick} );

        if ( $self->{in}{command} eq 'PRIVMSG' ) {
            $self->{in}{private} = 1 if ( $self->{in}{forum} and $self->{in}{forum} eq $self->{nick} );
            $self->{in}{to_me}   = 1 if (
                $self->{in}{text} =~ s/^\s*\b$self->{nick}\b[\s\W]*//i or
                $self->{in}{text} =~ s/[\s\W]*\b$self->{nick}\b[\s\W]*$//i or
                $self->{in}{private}
            );
        }

        if ( $self->{in}{to_me} ) {
            if ( $self->{in}{text} =~ /^\s*help\W*$/i ) {
                $self->reply_to(
                    'Ask me for help with "help topic" where the topic is one of the following: ' .
                    $self->list( ', ', 'and', sort keys %{ $self->{helps} } ) . '.'
                );
                next;
            }
            elsif ( $self->{in}{text} =~ /^\s*help\s+(.+?)\W*$/i ) {
                $self->reply_to(
                    ( $self->{helps}{$1} || "Couldn't find the help topic: $1." )
                );
                next;
            }
            elsif ( $self->{in}{text} =~ /Sorry. I don't understand./ ) {
                next;
            }
        }

        hook: for my $hook (
            @{ $self->{hooks} },

            {
                when => {
                    to_me => 1,
                    text  => qr/^\s*cmd\s+(?<passwd>\S+)\s+(?<cmd>.+)$/i,
                },
                code => sub {
                    my ( $bot, $in, $m ) = @_;

                    if ( $m->{passwd} and $passwd and $m->{passwd} eq $passwd ) {
                        $bot->say($_) for (
                            map {
                                my $command = $_;
                                $command =~ s|^/msg |PRIVMSG |;
                                $command =~ s|^/(\w+)|uc($1)|e;
                                $command;
                            } split( /\s*;\s*/, $m->{cmd} )
                        );
                    }

                    return 1;
                },
            },

            {
                when => {
                    full_text => qr/^\s*$self->{nick}\s*[!\?]\W*$/i,
                },
                code => sub {
                    my ($bot) = @_;
                    $bot->reply_to('Yes?');
                },
            },

            {
                when => {
                    to_me => 1,
                    text  => qr/^(?<word>hello|greetings|hi|good\s+\w+)\W*$/i,
                },
                code => sub {
                    my ( $bot, $in, $m ) = @_;
                    $bot->reply_to( ucfirst( lc( $m->{word} ) ) . '.' );
                },
            },

            ( map {
                {
                    when => $_,
                    code => sub {
                        my ($bot) = @_;
                        $bot->reply_to(qq{Sorry. I don't understand. (Try "$self->{nick} help" for help.)});
                    },
                },
            } (
                {
                    private   => 0,
                    full_text => qr/^\s*$self->{nick}\s*[,:\->~=]/i,
                },
                {
                    private => 1,
                },
            ) ),

        ) {
            my $captured_matches = {};

            for my $type ( keys %{ $hook->{when} } ) {
                next hook unless (
                    ref( $hook->{when}{$type} ) eq 'Regexp' and
                        $self->{in}{$type} and $self->{in}{$type} =~ $hook->{when}{$type} or
                    ref( $hook->{when}{$type} ) eq 'CODE' and $hook->{when}{$type}->(
                        $self,
                        $self->{in}{$type},
                        { %{ $self->{in} } },
                    ) or
                    (
                        defined $self->{in}{$type} and defined $hook->{when}{$type} and
                        $self->{in}{$type} eq $hook->{when}{$type}
                    )
                );

                $captured_matches = { %$captured_matches, %+ } if ( keys %+ );
            }

            my $rv;
            try {
                $rv = $hook->{code}->(
                    $self,
                    { %{ $self->{in} } },
                    $captured_matches,
                );
            }
            catch {
                warn "Plugin hook execution failure: $_\n";
            };

            last if ($rv);
        }
    }
}

sub load {
    my $self = shift;

    for my $plugin (@_) {
        unless ( ref $plugin ) {
            if ( $plugin =~ /^:core$/i ) {
                $self->load(
                    'Ping',
                    'Join',
                    'Seen',
                    'Greeting',
                    'Infobot',
                    'Functions',
                    'Convert',
                    'Karma',
                    'Math',
                    'History',
                );
                next;
            }

            my $namespace;
            for (
                $plugin,
                __PACKAGE__ . "::Y::$plugin",
                __PACKAGE__ . "::X::$plugin",
                __PACKAGE__ . "::$plugin",
            ) {
                ( my $path = $_ ) =~ s|::|/|g;

                eval "require $_";
                unless ($@) {
                    $namespace = $_;
                    last;
                }
                else {
                    croak("Plugin load failure: $@") unless ( $@ =~ /^Can't locate $path/ );
                }
            }
            croak("Unable to find or properly load $plugin") unless ($namespace);

            next if ( $self->{loaded}{$namespace} );

            $namespace->import if ( $namespace->can('import') );
            croak("$namespace does not implement init()") unless ( $namespace->can('init') );

            eval "${namespace}::init(\$self)";
            die("Plugin init failure: $@\n") if ($@);

            $self->{loaded}{$namespace} = time;
        }
        else {
            $self->$_( @{ $plugin->{$_} } ) for ( qw( hooks ticks ) );
            $self->$_( $plugin->{$_} ) for ( qw( helps subs ) );
        }
    }

    return $self;
}

sub reload {
    my $self = shift;
    delete $self->{loaded}{$_} for (@_);
    return $self->load(@_);
}

sub hook {
    my ( $self, $when, $code, $attr ) = @_;

    push(
        @{ $self->{hooks} },
        {
            when => $when,
            code => $code,
            attr => ( $attr // {} ),
        },
    );

    $self->subs(  %{ $attr->{subs}  } ) if ( ref $attr->{subs}  eq 'HASH' );
    $self->helps( %{ $attr->{helps} } ) if ( ref $attr->{helps} eq 'HASH' );

    return $self;
}

sub hooks {
    my $self = shift;
    $self->hook(@$_) for (@_);
    return $self;
}

sub helps {
    my ( $self, @input ) = @_;

    try {
        $self->{helps} = { %{ $self->{helps} }, @input };
    }
    catch {
        $self->note('Plugin helps called but not properly implemented');
    };

    return $self;
}

sub tick {
    my ( $self, $timing, $code ) = @_;

    push( @{ $self->{ticks} }, {
        timing => ( $timing =~ /^\d+$/ ) ? $timing : Time::Crontab->new($timing),
        code   => $code,
    } );
    return $self;
}

sub ticks {
    my $self = shift;
    $self->tick(@$_) for (@_);
    return $self;
}

sub subs {
    my $self = shift;

    if ( @_ % 2 ) {
        $self->note('Plugin helps called but not properly implemented');
        return $self;
    }

    my $subs = {@_};

    for my $name ( keys %$subs ) {
        no strict 'refs';
        no warnings 'redefine';
        *{ __PACKAGE__ . '::' . $name } = $subs->{$name};
    }

    return $self;
}

sub register {
    my $self = shift;
    $self->{loaded}{$_} = time for (@_);
    return $self;
}

sub vars {
    my ( $self, $name ) = @_;
    ( $name = lc( substr( ( caller() )[0], length(__PACKAGE__) + 2 ) ) ) =~ s/::/\-/g unless ($name);
    return ( defined $self->{vars}{$name} ) ? $self->{vars}{$name} : {};
}

sub settings {
    my ( $self, $name ) = @_;
    return ( defined $name ) ? $self->{$name} : { %$self };
}

sub reply {
    my ( $self, $message ) = @_;

    if ( $self->{in}{forum} ) {
        $self->msg(
            ( ( $self->{in}{forum} eq $self->{nick} ) ? $self->{in}{nick} : $self->{in}{forum} ),
            $message,
        );
    }
    else {
        warn "Didn't have a target to send reply to.\n";
    }
    return $self;
}

sub reply_to {
    my ( $self, $message ) = @_;
    return $self->reply( ( ( not $self->{in}{private} ) ? "$self->{in}{nick}: " : '' ) . $message );
}

sub msg {
    my ( $self, $target, $message ) = @_;
    $self->say("PRIVMSG $target :$message");
    return $self;
}

sub say {
    my $self = shift;

    for (@_) {
        my $string = encode( 'utf-8' => $_ );
        $self->{socket}->print( $string . "\r\n" );
        $self->note("<<< $string");
    }
    return $self;
}

sub nick {
    my ( $self, $nick ) = @_;

    if ($nick) {
        $self->{nick} = $nick;
        $self->{device}->message( $_, ">>> NICK $self->{nick}" )
            for ( grep { $_ != $$ } $self->{device}->ppid, @{ $self->{device}->children } );
        $self->say("NICK $self->{nick}");
    }
    return $self->{nick};
}

sub join {
    my $self = shift;

    $self->say("JOIN $_") for (
        ( not @_ and $self->{connect}{join} )
            ? (
                ( ref $self->{connect}{join} eq 'ARRAY' )
                    ? @{ $self->{connect}{join} }
                    : $self->{connect}{join}
            )
            : @_
    );

    return $self;
}

sub part {
    my $self = shift;
    $self->say("PART $_") for (@_);
    return $self;
}

sub list {
    my ( $self, $separator, $conjunction ) = ( shift, shift, shift );
    my @list = @_;

    if ( @list > 2 ) {
        return CORE::join( $separator, @list[ 0 .. @list - 2 ], $conjunction . ' ' . $list[-1] );
    }
    elsif ( @list > 1 ) {
        return $list[0] . ' ' . $conjunction . ' ' . $list[1];
    }
    else {
        return $list[0];
    }
}

sub health {
    my ($self) = @_;

    return {
        nick    => $self->{nick},
        server  => $self->{connect}{server},
        port    => $self->{connect}{port},
        ssl     => $self->{connect}{ssl},
        spawn   => $self->{spawn},
        hooks   => scalar( @{ $self->{hooks} } ),
        ticks   => scalar( @{ $self->{ticks} } ),
        plugins => scalar( keys %{ $self->{loaded} } ),
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::IRC - Yet Another IRC Bot

=head1 VERSION

version 1.25

=for markdown [![Build Status](https://travis-ci.org/gryphonshafer/Bot-IRC.svg)](https://travis-ci.org/gryphonshafer/Bot-IRC)
[![Coverage Status](https://coveralls.io/repos/gryphonshafer/Bot-IRC/badge.png)](https://coveralls.io/r/gryphonshafer/Bot-IRC)

=head1 SYNOPSIS

    use Bot::IRC;

    # minimal bot instance that does basically nothing except join a channel
    Bot::IRC->new(
        connect => {
            server => 'irc.perl.org',
            join   => '#test',
        },
    )->run;

    # illustrative example of most settings and various ways to get at them
    my $bot = Bot::IRC->new(
        spawn  => 2,
        daemon => {
            name        => 'bot',
            lsb_sdesc   => 'Yet Another IRC Bot',
            pid_file    => 'bot.pid',
            stderr_file => 'bot.err',
            stdout_file => 'bot.log',
        },
        connect => {
            server => 'irc.perl.org',
            port   => '6667',
            nick   => 'yabot',
            name   => 'Yet Another IRC Bot',
            join   => [ '#test', '#perl' ],
            ssl    => 0,
        },
        plugins => [
            ':core',
        ],
        vars => {
            store => 'bot.yaml',
        },
        send_user_nick => 'on_parent', # or 'on_connect' or 'on_reply'
    );

    $bot->load( 'Infobot', 'Karma' );

    ## Example inline plugin structure
    # $bot->load({
    #     hooks => [ [ {}, sub {}, {} ] ],
    #     helps => { name => 'String' },
    #     subs  => { name => sub {} },
    #     ticks => [ [ '0 * * * *', sub {} ] ],
    # });

    $bot->run;

=head1 DESCRIPTION

Yet another IRC bot. Why? There are so many good bots and bot frameworks to
select from, but I wanted a bot framework that worked like a Unix service
out-of-the-box, operated in a pre-fork way to serve multiple concurrent
requests, and has a dirt-simple and highly extendable plugin mechanism. I also
wanted to keep the direct dependencies and core bot minimalistic, allowing as
much functionality as possible to be defined as optional plugins.

=head2 Minimal Bot

You can have a running IRC bot with as little as:

    use Bot::IRC;

    Bot::IRC->new(
        connect => {
            server => 'irc.perl.org',
        },
    )->run;

This won't actually do much apart from connecting to the server and responding
to pings, but it's useful to understand how this works. Let's say you place the
above code into a "bot.pl" file. You start the bot with:

    ./bot.pl start

This will startup the bot. Command-line commands include: start, stop, restart,
reload, status, help, and so on. (See L<Daemon::Control> for more details.)

=head2 Pre-Forking Device

When the bot is started, the parent process will fork or spawn a given number
of children workers. You can control their number along with setting locations
for things like PID file, log files, and so on.

    Bot::IRC->new(
        spawn  => 2,
        daemon => {
            name        => 'bot',
            lsb_sdesc   => 'Yet Another IRC Bot',
            pid_file    => 'bot.pid',
            stderr_file => 'bot.err',
            stdout_file => 'bot.log',
        },
    )->run;

(See L<Daemon::Device> for more details.)

=head1 MAIN METHODS

The following are the main or primary available methods from this class.

=head2 new

This method instantiates a bot object that's potentially ready to start running.
All bot settings can be specified to the C<new()> constructor, but some can be
set or added to through other methods off the instantiated object.

    Bot::IRC->new(
        spawn  => 2,
        daemon => {},
        connect => {
            server => 'irc.perl.org',
            port   => '6667',
            nick   => 'yabot',
            name   => 'Yet Another IRC Bot',
            join   => [ '#test', '#perl' ],
            ssl    => 0,
        },
        plugins => [],
        vars    => {},
    )->run;

C<spawn> will default to 2. Under C<connect>, C<port> will default to 6667.
C<join> can be either a string or an arrayref of strings representing channels
to join after connnecting. C<ssl> is a true/false setting for whether to
connect to the server over SSL.

Read more about plugins below for more information about C<plugins> and C<vars>.
Consult L<Daemon::Device> and L<Daemon::Control> for more details about C<spawn>
and C<daemon>.

There's also an optional C<send_user_nick> parameter, which you probably won't
need to use, which defines when the bot will send the C<USER> and initial
C<NICK> commands to the IRC server. There are 3 options: C<on_connect>,
C<on_parent> (the default), and C<on_reply>. C<on_connect> sends the C<USER>
and initial C<NICK> immediately upon establishing a connection to the IRC
server, prior to the parent runtime loop and prior to children creation.
C<on_parent> (the default) sends the 2 commands within the parent runtime loop
prior to any responses from the IRC server. C<on_reply> (the only option in
versions <= 1.23 of this module) sends the 2 commands after the IRC server
replies with some sort of content after connection.

=head2 run

This should be the last call you make, which will cause your program to operate
like a Unix service from the command-line. (See L<Daemon::Control> for
additional details.)

C<run> can optionally be passed a list of strings that will be executed after
connection to the IRC server. These should be string commands similar to what
you'd type in an IRC client. For example:

    Bot::IRC->new( connect => { server => 'irc.perl.org' } )->run(
        '/msg nickserv identify bot_password',
        '/msg operserv identify bot_password',
        '/oper bot_username bot_password',
        '/msg chanserv identify #bot_talk bot_password',
        '/join #bot_talk',
        '/msg chanserv op #bot_talk',
    );

=head1 PLUGINS

To do anything useful with a bot, you have to load plugins. You can do this
either by specifying a list of plugins with the C<plugins> key passed to
C<new()> or by calling C<load()>.

Plugins are just simple packages (or optionally a hashref, but more on that
later). The only requirement for plugins is that they provide an C<init()>
method. This will get called by the bot prior to forking its worker children.
It will be passed the bot object. Within C<init()>, you can call any number of
plugin methods (see the list of methods below) to setup desired functionality.

    package Your::Plugin;
    use strict;
    use warnings;

    sub init {
        my ($bot) = @_;

        $bot->hook(
            {
                to_me => 1,
                text  => qr/\b(?<word>w00t|[l1][e3]{2}[t7])\b/i,
            },
            sub {
                my ( $bot, $in, $m ) = @_;
                $bot->reply("$in->{nick}, don't use the word: $m->{word}.");
            },
        );
    }

    1;

When you load plugins, you can specify their packages a few different ways. When
attempting to load a plugin, the bot will start by looking for the name you
provided as a sub-class of itself. Then it will look for the plugin under the
assumption you provided it's full name.

    plugins => [
        'Store',           # matches "Bot::IRC::Store"
        'Random',          # matches "Bot::IRC::X::Random"
        'Thing',           # matches "Bot::IRC::Y::Thing"
        'My::Own::Plugin', # matches "My::Own::Plugin"
    ],

An unenforced convention for public/shared plugins is to have non-core plugins
(all plugins not provided directly by this CPAN library) subclasses of
"Bot::IRC::X". For private/unshared plugins, you can specify whatever name you
want, but maybe consider something like "Bot::IRC::Y". Plugins set in the X or
Y subclass namespaces will get matched just like core plugins. "Y" plugins will
have precedence over "X" which in turn will have precedence over core.

If you need to allow for variables to get passed to your plugins, an unenforced
convention is to do so via the C<vars> key to C<new()>.

=head2 Core Plugins

If you specify ":core" as a plugin name, it will be expanded to load all the
core plugins. Core plugins are all the plugins that are bundled and
distributed with L<Bot::IRC>.

=over 4

=item *

L<Bot::IRC::Ping>

=item *

L<Bot::IRC::Join>

=item *

L<Bot::IRC::Seen>

=item *

L<Bot::IRC::Greeting>

=item *

L<Bot::IRC::Infobot>

=item *

L<Bot::IRC::Functions>

=item *

L<Bot::IRC::Convert>

=item *

L<Bot::IRC::Karma>

=item *

L<Bot::IRC::Math>

=item *

L<Bot::IRC::History>

=back

Some core plugins require a storage plugin. If you don't specify one in your
plugins list, then the default L<Bot::IRC::Store> will be used, which is
probably not what you want (for performance reasons). Try
L<Bot::IRC::Store::SQLite> instead.

    plugins => [
        'Store::SQLite',
        ':core',
    ],

=head1 PLUGIN METHODS

The following are methods available from this class related to plugins.

=head2 load

This method loads plugins. It is the exact equivalent of passing strings to the
C<plugins> key in C<new()>. If a plugin has already been loaded, it'll get
skipped.

    my $bot = Bot::IRC->new(
        connect => { server => 'irc.perl.org' },
        plugins => [ 'Store', 'Infobot', 'Karma' ],
    );

    $bot->load( 'Infobot', 'Seen' );

From within your plugins, you can call C<load()> to specify plugin dependencies
in your plugins.

    sub init {
        my ($bot) = @_;
        $bot->load('Dependency');
    }

=head2 reload

If you need to actually reload a plugin, call C<reload>. It operates in the same
was as C<load>, only it won't skip already-loaded plugins.

=head2 hook

This is the method you'll call to add a hook, which is basically a message
response handler. A hook includes a conditions trigger, some code to run
when the trigger fires, and an optional additional attributes hashref.

    $bot->hook(
        {
            to_me => 1,
            text  => qr/\b(?<word>w00t|[l1][e3]{2}[t7])\b/i,
        },
        sub {
            my ( $bot, $in, $m ) = @_;
            $bot->reply("$in->{nick}, don't use the word: $m->{word}.");
        },
        {
            subs  => [],
            helps => [],
        },
    );

The conditions trigger is a hashref of key-value pairs where the key is a
component of the message and the value is either a value to exact match or a
regular expression to match.

The code block will receive a copy of the bot, a hashref of key-value pairs
representing the message the hook is responding to, and an optionally-available
hashref of any named matches from the regexes in the trigger.

The hashref representing the message the hook will have the following keys:

=over 4

=item *

C<text>: text component of the message

=item *

C<command>: IRC "command" like PRIVMSG, MODE, etc.

=item *

C<forum>: origin location like #channel or the nick who privately messaged

=item *

C<private>: 1 or 0 representing if the message is private or in a channel

=item *

C<to_me>: 1 or 0 representing if the message is addressing the bot or not

=item *

C<nick>: nick of the sender of the message

=item *

C<source>: the source server's label/name

=item *

C<user>: username of the sender of the message

=item *

C<server>: server of the sender of the message

=item *

C<line>: full message line/text

=item *

C<full_text>: text component of the message with nick included

=back

B<The return value from the code block is important.> If you return a positive
value, all additional hooks are skipped because it will be assumed that this
hook properly responded to the message and no additional work needs to be done.
If the code block returns a false value, additional hooks will be checked as if
this hook's trigger caused the code block to be skipped.

The optional additional attributes hashref supports a handful of keys.
You can specify C<subs> and C<helps>, which are exactly equivalent to
calling C<subs()> and C<helps()>. (See below.)

=head2 hooks

This method accepts a list of arrayrefs, each containing a trigger, code, and
attribute value and calls C<hook> for each set.

    ## Example hooks call structure
    # $bot->hooks(
    #     [ {}, sub {}, {} ],
    #     [ {}, sub {}, {} ],
    # );

=head2 helps

This method is how you'd setup any help text you'd like the bot to provide to
users. It expects some number of key-value pairs where the key is the topic
title of the set of functionality and the value is the string of instructions.

    $bot->helps(
        seen => 'Tracks when and where people were seen. Usage: seen <nick>, hide, unhide.',
        join => 'Join and leave channels. Usage: join <channel>, leave <channel>, channels.',
    );

In the example above, let's say your bot had the nick of "bot" and you were in
the same channel as your bot and you typed "bot, help" in your IRC channel. The
bot would respond with a list of available  topics. Then if you typed "bot, help
seen" in the channel, the bot would reply with the "seen" string of
instructions. If typing directly to the bot (in a private message directly to
the bot), you don't need to specify the bot's name.

=head2 tick

Sometimes you'll want the bot to do something at a specific time or at some sort
of interval. You can cause this to happen by filing ticks. A tick is similar to
a hook in that it's a bit of code that gets called, but not based on a message
but based on time. C<tick()> expects two values. The first is either an integer
representing the number of seconds of interval between calls to the code or a
crontab-like time expression. The second value is the code to call, which will
receive a copy of the bot object.

    $bot->tick(
        10,
        sub {
            my ($bot) = @_;
            $bot->msg( '#test', '10-second interval.' );
        },
    );

    $bot->tick(
        '0 0 * * *',
        sub {
            my ($bot) = @_;
            $bot->msg( '#test', "It's midnight!" );
        },
    );

=head2 ticks

This method accepts a list of arrayrefs, each containing a time value and code
block and calls C<tick> for each set.

    $bot->ticks(
        [ 10,          sub {} ],
        [ '0 0 * * *', sub {} ],
    );

=head2 subs

A plugin can also provide functionality to the bot for use in other plugins.
It can also override core methods of the bot. You do this with the C<subs()>
method.

    $bot->subs(
        incr => sub {
            my ( $bot, $int ) = @_;
            return ++$int;
        },
    );

    my $value = $bot->incr(42); # value is 43

=head2 register

There are rare cases when you're writing your plugin where you want to claim
that your plugin satisfies the requirements for a different plugin. In other
words, you want to prevent the future loading of a specific plugin or plugins.
You can do this by calling C<register()> with the list of plugins (by full
namespace) that you want to skip.

    $bot->register('Bot::IRC::Storage');

Note that this will not block the reloading of plugins with C<reload()>.

=head2 vars

When you are within a plugin, you can call C<vars()> to get the variables for
the plugin by it's lower-case "simplified" name, which is the plugin's class
name all lower-case, without the preceding "Bot::IRC::" bit, and with "::"s
replaced with dashes. For example, let's say you were writing a
"Bot::IRC::X::Something" plugin. You would have users set variables in their
instantiation like so:

    Bot::IRC->new
        plugins => ['Something'],
        vars    => { x-something => { answer => 42 } },
    )->run;

Then from within the "Bot::IRC::X::Something" plugin, you would access these
variables like so:

    my $my_vars = $bot->vars;
    say 'The answer to life, the universe, and everything is ' . $my_vars->{answer};

If you want to access the variables for a different namespace, pass into
C<vars()> the "simplified" name you want to access.

    my $my_other_vars = $bot->vars('x-something-else');

=head2 settings

If you need access to the bot's settings, you can do so with C<settings()>.
Supply the setting name/key to get that setting, or provide no name/key to get
all settings as a hashref.

    my $connection_settings_hashref = $bot->settings('connect');

=head1 INLINE PLUGINS

You can optionally inject inline plugins by providing them as hashref. This
works both with C<load()> and the C<plugins> key.

    ## Example inline plugin structure
    # $bot->load(
    #     {
    #         hooks => [ [ {}, sub {}, {} ], [ {}, sub {}, {} ] ],
    #         ticks => [ [ 10, sub {} ], [ '0 0 * * *', sub {} ] ],
    #         helps => { title => 'Description.' },
    #         subs  => { name => sub {} },
    #     },
    #     {
    #         hooks => [ [ {}, sub {}, {} ], [ {}, sub {}, {} ] ],
    #         ticks => [ [ 10, sub {} ], [ '0 0 * * *', sub {} ] ],
    #         helps => { title => 'Description.' },
    #         subs  => { name => sub {} },
    #     },
    # );

=head1 OPERATIONAL METHODS

The following are operational methods available from this class, expected to be
used inside various code blocks passed to plugin methds.

=head2 reply

If you're inside a hook, you can usually respond to most messages with the
C<reply()> method, which accepts the text the bot should reply with. The method
returns the bot object.

    $bot->reply('This is a reply. Impressive, huh?');

If you want to emote something back or use any other IRC command, type it just
as you would in your IRC client.

    $bot->reply('/me feels something, which for a bot is rather impressive.');

=head2 reply_to

C<reply_to> is exactly like C<reply> except that if the forum for the reply is
a channel instead of to a specific person, the bot will prepend the message
by addressing the nick who was the source of the response the bot is responding
to.

=head2 msg

Use C<msg()> when you don't have a forum to reply to or want to reply in a
different forum (i.e. to a different user or channel). The method accepts the
forum for the message and the message text.

    $bot->msg( '#test', 'This is a message for everybody in #test.');

=head2 say

Use C<say()> to write low-level lines to the IRC server. The method expects a
string that's a properly IRC message.

    $bot->say('JOIN #help');
    $bot->say('PRIVMSG #help :I need some help.');

=head2 nick

Use C<nick> to change the bot's nick. If the nick is already in use, the bot
will try appending "_" to it until it finds an open nick.

=head2 join

Use C<join()> to join channels.

    $bot->join('#help');

If some sort of persistent storage plugin is loaded, the bot will remember the
channels it has joined or parted and use that as it's initial join on restart.

=head2 part

Use C<part()> to part channels.

    $bot->part('#help');

If some sort of persistent storage plugin is loaded, the bot will remember the
channels it has joined or parted and use that as it's initial join on restart.

=head1 RANDOM HELPFUL METHODS

The following are random additional methods that might be helpful in your
plugins.

=head2 list

This method is a simple string method that takes a list and crafts it for
readability. It expects a separator string, a final item conjunction string,
and a list of items.

    $bot->list( ', ', 'and', 'Alpha', 'Beta', 'Delta', 'Gamma' );
    # returns "Alpha, Beta, Delta, and Gamma"

    $bot->list( ', ', 'and', 'Alpha', 'Beta' );
    # returns "Alpha and Beta"

=head2 health

This method returns a hashref of simple key value pairs for different "health"
aspects (or current state) of the bot. It includes things like server and port
connection, number of children, and so on.

=head2 note

While in theory you shouldn't ever need to use it, there is a method called
"note" which is a handler for writing to the log and error files. If you
C<warn> or C<die>, this handler steps in automatically. If you'd like to
C<print> to STDOUT, which you really shouldn't need to do, then it's best to
call this method instead. The reason being is that the log file is designed to
be parsed in a specific way. If you write whatever you want to it, it will
corrupt the log file. That said, if you really, really want to, here's how you
use C<note>:

    $bot->note('Message');           # writes a message to the log file
    $bot->note( 'Message', 'warn' ); # writes a message to the error file
    $bot->note( 'Message', 'die' );  # writes a message to the error file the dies

=head1 SEE ALSO

You can look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/Bot-IRC>

=item *

L<CPAN|http://search.cpan.org/dist/Bot-IRC>

=item *

L<MetaCPAN|https://metacpan.org/pod/Bot::IRC>

=item *

L<AnnoCPAN|http://annocpan.org/dist/Bot-IRC>

=item *

L<Travis CI|https://travis-ci.org/gryphonshafer/Bot-IRC>

=item *

L<Coveralls|https://coveralls.io/r/gryphonshafer/Bot-IRC>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Bot-IRC>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/T/Bot-IRC.html>

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Gryphon Shafer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
