use strict;
use warnings;

package Bot::Net::Test;
use base qw/ Bot::Net::Object Test::More Class::Data::Inheritable /;

use Bot::Net;
use Bot::Net::Mixin;

use Config;
use File::Spec;
use FindBin;
use Hash::Merge ();
use POE qw/ Wheel::Run /;

__PACKAGE__->mk_classdata('servers' => {});
__PACKAGE__->mk_classdata('bots'    => {});
__PACKAGE__->mk_classdata('waiting' => {});

=head1 NAME

Bot::Net::Test - helper for building Bot::Net tests

=head1 SYNOPSIS

  use strict;
  use warnings;

  # Make this test script a bot
  use Bot::Net::Bot;
  use Bot::Net::Mixin::Bot::IRC;

  use Bot::Net::Test tests => 20;

  # Start the server in class MyBotNet::Server::Main
  Bot::Net::Test->start_server('Main');

  # Connect the bot in class MyBotNet::Bot::Count
  Bot::Net::Test->start_bot('Count');

  on bot connected => run {
      for ( 1 .. 10 ) {
          yield send_to => count => 'something';
      }
  };

  on bot message_to_me => run {
      my $event = get ARG0;
      my $count_expected = (recall('count') || 0) + 1;
      remember count => $count_expected;

      is($event->sender_nick, 'count');
      is($event->message, $count_expected);

      if ($count_expected == 10) {
          yield irc => quit => 'Test finished.';
      }
  };

  # Startup this bot
  Bot::Net::Test->run_test;

=head1 DESCRIPTION

Provides some tools to make testing your bots and servers a little easier. The typical pattern for using this class is to make your test script into a bot or server by implementing whichever set of mixins you need. 

You can start orther servers or bots using L</start_bot> or L</start_server>. You can define any states you need to handle for testing. Then, you start that server or bot using L</run_test>.

Make sure that you tell your bot to shutdown when you're finished with your tests. (For example, for an IRC bot, you can issue a C<quit> or C<disconnect> state to the IRC POE component as showin the L</SYNOPSIS>.)

=head1 METHODS

=head2 import_extra

Builds a test configuration for your test file.

=cut

sub import_extra {
    my $class = shift;
    my $package = caller;

    no strict 'refs';
    ${ $package . '::CONFIG' } ||= {};

    Test::More->export_to_level(2);
    $class->export_poe_declarative_to_level(2);
}

=head2 start_server SERVER

Starts the named server. This server will shutdown when the test bot quits or when L</stop_server> is called.

=cut

sub start_server {
    my $class  = shift;
    my $server = shift;

    $class->servers->{ $server } = undef;
}

=head2 stop_server SERVER

Stops the named server.

=cut

sub stop_server {
    my $class  = shift;
    my $server = shift;

    my $wheel = delete $class->servers->{ $server }{ 'wheel' };
    if ($wheel) {
        Bot::Net::Test->log->info("Terminating server $server (pid:@{[$wheel->PID]})");
        $class->waiting->{ $wheel->PID } = 1;
        $wheel->kill;
    }
}

=head2 start_bot BOT

Starts the named bot. This bot will shutdown when the test bot quits or when L</stop_bot> is called.

=cut

sub start_bot {
    my $class = shift;
    my $bot   = shift;

    $class->bots->{ $bot } = undef;
}

=head2 stop_bot BOT

Stops the named bot.

=cut

sub stop_bot {
    my $class = shift;
    my $bot   = shift;

    my $wheel = delete $class->bots->{ $bot }{ 'wheel' };
    if ($wheel) {
        Bot::Net::Test->log->info("Terminating bot $bot (pid:@{[$wheel->PID]})");
        $class->waiting->{ $wheel->PID } = 1;
        $wheel->kill;
    }
}

=head2 run_test

Tells the test to setup the bot or server and tell the L<POE> kernel to start the event loop.

=cut

sub run_test {
    my $class = shift;
    my $test  = caller;

    my @configs;
    for my $mixin (@{ Bot::Net::Mixin::_mixins_for_package($test) }) {
        push @configs, $mixin->default_configuration($test)
            if $mixin->can('default_configuration');
    }

    my $config = Hash::Merge::merge( @configs );

    # XXX This is a hack, I need to find a better way...
    $config->{auto_connect} = 0;

    {
        no strict 'refs';
        ${ $test . '::CONFIG' } = $config;
    }

    Bot::Net::Test->log->info("Starting test");

    $test->setup;
    POE::Kernel->run;
}

=head1 POE STATES

=head2 on _start

Sets up a timer which kills the whole test if it doesn't receive any messages within 30 seconds.

If you have a test that may run for longer than 30 seconds, make sure your events yield "something_happened":

  on bot message_to_me => run {
      yield 'something_happened';

      # do whatever else you like...
  };

=cut

sub _run_that {
    my @program = @_;

    sub {
        $ENV{PERL5LIB} = join ':', @INC;
        $ENV{BOT_NET_CONFIG_PATH} = File::Spec->catfile(
            $FindBin::Bin, '..', 't', 'etc'
        );
        exec(@program);
    };
}

on _start => run {
    yield 'spawn_all_servers';
    yield 'spawn_all_bots_after_servers';
    yield 'connect_after_bots';

    delay 'shutdown_unless_something_happened', 30;

    remember something_happened => 0;

    get(KERNEL)->sig(CHLD => 'child_reaper');
};

=head2 on spawn_all_servers

For each server added in the test file, tell those servers to start.

=cut

on spawn_all_servers => run {
    for my $server (keys %{ Bot::Net::Test->servers }) {
        Bot::Net::Test->log->info("Starting server $server");

        my $server_name = $server;
        $server_name =~ s/\W+/_/g;

        my $wheel = POE::Wheel::Run->new(
            Program      => _run_that(
                File::Spec->catfile('bin', 'botnet'),
                qw/ run --server /, $server,
            ),

            StdinEvent   => "server_${server_name}_stdin",
            StdoutEvent  => "server_${server_name}_stdout",
            StderrEvent  => "server_${server_name}_stderr",

            ErrorEvent   => "server_${server_name}_error",
            CloseEvent   => "server_${server_name}_close",
        );

        on "server_${server_name}_stdout" => run {
            local $_ = get ARG0;
            recall('log')->debug("$server - $_");
            return if Bot::Net::Test->servers->{ $server }{ 'ready' } == 1;
            if (my ($status) = /SERVER READY\s*:\s*(.*)$/m) {
                my %status = split /\s+/, $status;
                Bot::Net::Test->servers->{ $server }{ 'ready' }  = 1;
                Bot::Net::Test->servers->{ $server }{ 'status' } = \%status;
            }
        };

        on "server_${server_name}_error" => run {
            my $op    = get ARG0;
            my $errno = get ARG1;
            my $error = get ARG2;
            Test::More::fail("FAILED $server $op ($errno) $error");
            yield 'bot_quit';
        };

        Bot::Net::Test->servers->{ $server }{ 'wheel' } = $wheel;
        Bot::Net::Test->servers->{ $server }{ 'ready' } = 0;
    }
};

=head2 on spawn_all_bots_after_servers

Checks to see if all the servers have reported ready status yet. If they have, this handler will tell all the bots to start. Otherwise, it yields the event again to try again in the next time slice.

=cut

sub _all_servers_are_ready {
    for my $server (keys %{ Bot::Net::Test->servers }) {
        my $status = Bot::Net::Test->servers->{ $server };
        unless (defined $status and $status->{'ready'}) {
            return '';
        }
    }

    return 1;
}

on spawn_all_bots_after_servers => run {
    recall('log')->debug('spawn_all_bots_after_servers');
    unless (_all_servers_are_ready()) {
        delay spawn_all_bots_after_servers => 1;
        return;
    }

    for my $bot (keys %{ Bot::Net::Test->bots }) {
        Bot::Net::Test->log->info("Starting bot $bot");

        my $bot_name = $bot;
        $bot_name =~ s/\W+/_/g;

        my $wheel = POE::Wheel::Run->new(
            Program      => _run_that(
                File::Spec->catfile('bin', 'botnet'),
                qw/ run --bot /, $bot,
            ),

            StdinEvent   => "bot_${bot_name}_stdin",
            StdoutEvent  => "bot_${bot_name}_stdout",
            StderrEvent  => "bot_${bot_name}_stderr",

            ErrorEvent   => "bot_${bot_name}_error",
            CloseEvent   => "bot_${bot_name}_close",
            StderrFilter => POE::Filter::Line->new,
        );

        on "bot_${bot_name}_stdout" => run {
            local $_ = get ARG0;
            recall('log')->debug("$bot - $_");
            return if Bot::Net::Test->bots->{ $bot }{ 'ready' } == 1;
            if (my ($status) = /BOT READY\s*:\s*(.*)$/m) {
                my %status = split /\s+/, $status;
                Bot::Net::Test->bots->{ $bot }{ 'ready' }  = 1;
                Bot::Net::Test->bots->{ $bot }{ 'status' } = \%status;
            }
        };

        on "bot_${bot_name}_error" => run {
            my $op    = get ARG0;
            my $errno = get ARG1;
            my $error = get ARG2;
            Test::More::fail("FAILED $bot $op ($errno) $error");
            yield 'bot_quit';
        };

        Bot::Net::Test->bots->{ $bot }{ 'wheel' } = $wheel;
        Bot::Net::Test->bots->{ $bot }{ 'ready' } = 0;
    }
};

=head2 on connect_after_bots

Checks to see if all the bots have spawned yet. If they have, then this emits C<bot connect> to connect the test bot (assuming the test is a test bot). If all the bots have not yet connected, then this will re-emit L</on connect_after_bots> to try again in another time slice.

=cut

sub _all_bots_are_ready() {
    for my $bot (keys %{ Bot::Net::Test->bots }) {
        my $status = Bot::Net::Test->bots->{ $bot };
        unless (defined $status and $status->{'ready'}) {
            return '';
        }
    }

    return 1;
}

on connect_after_bots => run {
    recall('log')->debug('connect_after_bots');
    unless (_all_servers_are_ready() and _all_bots_are_ready()) {
        delay connect_after_bots => 1;
        return;
    }

    yield 'bot_connect';
};

=head2 on child_reaper

Reaps the child bot and server processes.

=cut

on child_reaper => run {
    my $pid = get ARG1;
    my $err = get ARG2;

    delete Bot::Net::Test->waiting->{ $pid };

    my $return = $err >> 8;
    my $signal = $err & 127;
    my $dump   = $err & 128;

    if (defined $Config{sig_name}) {
        my $i = 0;
        my @signame;
        for my $name (split / /, $Config{sig_name}) {
            $signame[$i] = $name;
            $i++;
        }

        $signal = $signame[ $signal ] if defined $signame[ $signal ];
    }

    my $log = recall 'log';

    my $message = "Process $pid exited with return $return";
    $message   .= " (signal $signal)" if $signal;
    $message   .= " (core dumped)"    if $dump;

    recall('log')->info($message);
};

=head2 on shutdown_unless_something_happened

Clears the "soemthing_happened" flag if set. If not set, it tells the bot and/or server to quit.

=cut

on shutdown_unless_something_happened => run {
    if (recall 'something_happened') {
        remember something_happened => 0;
        delay shutdown_unless_something_happened => 30;
    }

    else {
        yield 'server_quit';
        yield 'bot_quit';
    }
};

=head2 on something_happened

Sets the "something_happened" flag.

=cut

on something_happened => run {
    my $something_happened = recall 'something_happened';
    remember something_happened => $something_happened + 1;
};

=head2 on [ bot quit, server quit ]

Shutdown any bots and servers that haven't yet been stopped.

=cut

on [ qw/ bot_quit server_quit / ] => run {
    Bot::Net::Test->log->warn("Quitting the test.");

    # Don't have these delayed events anymore
    delay 'shutdown_unless_something_happened';
    delay 'spawn_all_bots_after_servers';
    delay 'connect_after_bots';

    # Shutdown all bots
    for my $bot (keys %{ Bot::Net::Test->bots || {} }) {
        Bot::Net::Test->stop_bot($bot);
    }

    # Shutdown all servers
    for my $server (keys %{ Bot::Net::Test->servers || {} }) {
        Bot::Net::Test->stop_server($server);
    }

    yield 'wait_for_stop';
};

=head2 on wait_for_stop

Called at C<on bot quit> to wait for all the processes to shutdown. It will wait 10 seconds for this before giving. Unless your OS is doing something wonky, that should never happen... if it does, let me know.

=cut

my $max_wait = 100;
on wait_for_stop => run {
    my $waiting = scalar keys %{ Bot::Net::Test->waiting };
    delay wait_for_stop => 0.1 if $waiting and $max_wait-- > 0;
};

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
