package Bot::Backbone;
$Bot::Backbone::VERSION = '0.161950';
use v5.10;
use Moose();
use Bot::Backbone::DispatchSugar();
use Moose::Exporter;
use Class::Load;

use Bot::Backbone::Meta::Class::Bot;
use Bot::Backbone::Dispatcher;

# ABSTRACT: Extensible framework for building bots


Moose::Exporter->setup_import_methods(
    with_meta => [ qw( dispatcher service send_policy ) ],
    also      => [ qw( Moose Bot::Backbone::DispatchSugar ) ],
);


sub init_meta {
    shift;
    return Moose->init_meta(@_,
        base_class => 'Bot::Backbone::Bot',
        metaclass  => 'Bot::Backbone::Meta::Class::Bot',
    );
}


sub _resolve_class_name {
    my ($meta, $section, $class_name) = @_;

    if ($class_name =~ s/^\.//) {
        $class_name = join '::', $meta->name, $section, $class_name;
    }
    elsif ($class_name =~ s/^=//) {
        # do nothing, we now have the exact name
    }
    else {
        $class_name = join '::', 'Bot::Backbone', $section, $class_name;
    }

    Class::Load::load_class($class_name);
    return $class_name;
}

sub send_policy($%) {
    my ($meta, $name, @config) = @_;

    my @final_config;
    while (my ($class_name, $policy_config) = splice @config, 0, 2) {
        $class_name = _resolve_class_name($meta, 'SendPolicy', $class_name);
        push @final_config, [ $class_name, $policy_config ];
    }

    $meta->add_send_policy($name, \@final_config);
}


sub service($%) {
    my ($meta, $name, %config) = @_;

    my $class_name = _resolve_class_name($meta, 'Service', $config{service});
    $config{service} = $class_name;

    $meta->add_service($name, \%config);

    if (my $service_meta = Moose::Util::find_meta($class_name)) {
        Moose::Util::ensure_all_roles($meta, $service_meta->all_bot_roles)
            if $service_meta->isa('Bot::Backbone::Meta::Class::Service')
           and $service_meta->has_bot_roles;
    }
}


sub dispatcher($$) {
    my ($meta, $name, $code) = @_;

    my $dispatcher = Bot::Backbone::Dispatcher->new;
    {
        $meta->building_dispatcher($dispatcher);
        $code->();
        $meta->no_longer_building_dispatcher;
    }

    $meta->add_dispatcher($name, $dispatcher);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone - Extensible framework for building bots

=head1 VERSION

version 0.161950

=head1 SYNOPSIS

  package MyBot;
  use v5.14; # because newer Perl is cooler than older Perl
  use Bot::Backbone;

  use DateTime;
  use AI::MegaHAL;
  use WWW::Wikipedia;

  service chat_bot => (
      service  => 'JabberChat',
      jid      => 'mybot@example.com',
      password => 'secret',
      host     => 'example.com',
  );

  service group_foo => (
      service    => 'GroupChat',
      group      => 'foo',
      chat       => 'chat_bot',
      dispatcher => 'group_chat', # defined below
  );

  # This would invoke a service named MyBot::Service::Pastebin
  service pastebin => (
      service  => '.Pastebin',
      chats    => [ 'group_foo' ],
      host     => 'localhost',
      port     => 5000,
  );

  has megahal => (
      is         => 'ro',
      isa        => 'AI::MegaHAL',
      default    => sub { AI::MegaHAL->new },
  );

  has wikipedia => (
      is         => 'ro',
      isa        => 'WWW::Wikipedia',
      default    => sub { WWW::Wikipedia->new },
  );

  dispatcher group_chat => as {
      # Report the bot's time
      command '!time' => respond { DateTime->now->format_cldr('ddd, MMM d, yyyy @ hh:mm:ss') };

      # Basic echo command, with arguments
      command '!echo' => given_parameters {
          parameter echo_this => ( matching => qr/.*/ );
      } respond {
          my ($self, $message) = @_;
          $message->arguments->{echo_this};
      };

      # Include the pastebin commands (whatever they may be)
      redispatch_to 'pastebin';

      # Look for wikiwords in a comment and report the summaries for each
      also not_to_me respond {
          my ($self, $message) = @_;

          my (@wikiwords) = $message->text =~ /\[\[(\w+)\]\]/g;

           map { "$_->[0]: " . $_->[1] }
          grep { defined $_->[1] }
           map { [ $_, $self->wikipedia->search($_) }
              @wikiwords;
      };

      # Return an AI::MegaHAL resopnse for any message address to the bot
      to_me respond {
          my ($self, $message) = @_;
          $self->megahal->do_response($message->text);
      };

      # Finally:
      #  - also: match even if something else already responded
      #  - not_command: but not if a command matched
      #  - not_to_me: but not if addressed to me
      #  - run: run this code, but do not respond
      also not_command not_to_me run_this {
          my ($self, $message) = @_;
          $self->megahal->learn($message->text);
      };
  };

  my $bot = MyBot->new;
  $bot->run;

=head1 DESCRIPTION

Bots should be easy to build. Also a bot framework does not need to be tied to a
particular protocol (e.g., IRC, Jabber, Slack, etc.). However, most bot tools
fail at either of these. Finally, it should be possible to create generic
services that a bot can consume or share with other bots. This framework aims at
solving all of these.

This framework provides the following tools to this end.

=head2 Services

A service is a generic sub-application that runs within your bot, possibly
independent of the rest. Here are some examples of possible services:

=over

=item Chat Service

Each chat server connects to a chat service. This might be a Jabber server or an
IRC server or Slack or even just a local REPL for running commands on the
console. A single bot may have multiple connections to these servers by running
more than one chat service.

See L<Bot::Backbone::Service::JabberChat> and
L<Bot::Backbone::Service::ConsoleChat> for examples.

See L<Bot::Backbone::Service::Role::Chat> for responsibilities.

=item Group Service

These will ask a chat service to join a particular room or channel.

See L<Bot::Backbone::Service::GroupChat>.

=item Direct Message Service

These services are similar to Channel services, but are used to connect to
another individual account or a list of other accounts.

See L<Bot::Backbone::Service::DirectChat>.

=item Dispatched Service

A dispatched service may provide a group of common commands to the dispatcher.

See L<Bot::Backbone::Service> for help on building such a service and see
L<Bot::Backbone::Service::Role::ChatConsumer> for responsibilities.

=item Other Services

These could do anything you could imagine: search the web or your wiki, check
your email, notify you of new messages, monitor server logs, run RiveScript, run
a Markov Chain-based conversation, manage a pastebin, play Russian Roulette, or
whatever.

I have written a few of these services and may publish someday in separate
projects in the future.

=back

Basically, services are the place for any kind of tool the bot might need.
Simple services might be embedded into the bot itself, but it's recommended for
simplicity that the large dispatcher above not be emulated. Instead separate
each sub-application in your bot into a service to make them easier to maintain
separately.

=head2 Dispatcher

A dispatcher is a collection of predicates paired with run modes. A dispatcher
may be applied to a chat, channel, or direct message service to handle incoming
messages. When a message comes in from the service, each predicate is checked
against that message. The run mode of the first matching predicate is executed
(as well as any C<also> predicates.

Dispatchers are extensible, allowing for new predicates and run mode operations
to be defined as needed.

=head1 SUBROUTINES

=head2 init_meta

Setup the bot package with L<Bot::Backbone::Meta::Class> as the meta class and L<Bot::Backbone::Bot> as the base class.

=head1 SETUP ROUTINES

=head2 send_policy

  send_policy $name => ( ... );

Add a new send policy configuration.

=head2 service

  service $name => ( ... );

Add a new service configuration.

=head2 dispatcher

  dispatcher $name => ...;

This predicate is provided at the top level and is usually paired with the
L</as> run mode operation, though it could be paired with any of them. This
declares a named dispatcher that can be referred to as the C<dispatcher>
attribute on services that support dispatching.

=head1 DISPATCHER PREDICATES

=head2 redispatch_to

  redispatch_to 'service_name';

Given a service name for a service implementing L<Bot::Backbone::Service::Role::Dispatch>, we will ask the dispatcher on that object (if any) to perform dispatch.

=head2 command

  command $name => ...;

A command predicate matches the very first word found in the incoming message
text. It only matches an exact string and only messages not preceded by
whitespace (unless the message is addressed to the bot, in which case whitespace
is allowed).

=head2 not_command

  not_command ...;

This is not useful unless paired with the L</also> predicate. This only matches
if no command has been matched so far for the current message.

=head2 given_parameters

  given_parameters { parameter $name => %config; ... } ...

This is used in conjunction with C<parameter> to define arguments expected to
come next.

If the C<given_parameters> predicate matches completely, the message will have
each of the named parameters set on the C<parameters> hash inside the nested
L</run_this> or L</respond>.

The C<%config> may contain the following keys:

=over

=item match

This is a string a regular expression that will be used to match against the
next part of the input, as if it were a command-line. The string or expression
must match the entire next chunk (or provide a default) or the dispatcher will
move on to the next dispatch predicate.

=item match_original

Rather than matching the next command-line split chunk of the input, this
matches some next portion of the string. If it matches or there is a default
provided, success.

=item default

This sets the default. If this is set, the parameter match will always succeed
and gain this default value if the match itself fails.

=back

You must provide either C<match> or C<match_original> in each parameter.
Parameters my interleave C<match> and C<match_original> style matches as well
and Backbone should do the right thing.

=head2 to_me

  to_me ...

Matches messages that are considered directed toward the bot. This may be a
direct message or a channel message prefixed by the bot's name.

=head2 not_to_me

  not_to_me ...

This is the opposite of L</to_me>. It matches any message not sent directly to
the bot.

=head2 shouted

  shouted ...

Matches messages that are received from outside the current chat, such as a system message or administrator alert sent to all channels.

head2 spoken

  spoken ...

Matches messages that are stated within the channel to all participants. This is the usual volume level.

=head2 whispered

  whispered ...

Matches messages that are stated within the channel to only a subset of the listeners, such as a private message within a channel.

=head2 also

  also ...;

In general, only the run mode operation for the first matching predicate will be
executed. The C<also> predicate, however, tells the dispatcher to try and match
against it even if the dispatcher has already responded.

=head1 RUN MODE OPERATIONS

=head2 as

  as { ... }

This nests another set of dispatchers inside a predicate. Each set of predicates
defined within will be executed in turn if this run mode oepration is reached.

=head2 respond

  respond { ... }

If a C<response> is executed, the code ref given will be executed with three
arguments. The first will be a reference to the bot's main object. The second
will be a message object describing the incoming message. The third is the
service that sent the message.

The return value of the executed code ref will be used to respond to the user.
It will be called in list context and all the values returned will be sent to
the user. If an empty list or C<undef> is returned, then no message will be sent
to the user and dispatching will continue as if the predicate had not matched.

=head2 respond_with_method

  respond_with_method 'method_name'

Given the name of a method defined on the current bot package, that method will be called if all the dispatch predicates in front of it match.

It is called and used exactly as described under L</respond>.

=head2 respond_with_service_method

  respond_with_service_method 'method_name'

This directive should only be used with dispatchers created in the bot class and then assigned to the service using the L<Bot::Backbone::Service::Role::Dispatch/dispatcher> attribute. This allows the bot to define dispatchers on behalf of a service, which still calls the services methods.

=head2 run_this

  run_this { ... }

This will execute the given code ref, passing it the reference to the bot, the
message, and the service as arguments. The return value is ignored.

=head2 run_this_method

  run_this_method 'method_name'

This will execute the named method on the bot class. It will be called and used in exactly the same way as L</run_this>.

=head2 run_this_service_method

  run_this_service_method 'method_name'

This dispatch directive should only be used on dispatchers that are assigned to a service using the L<Bot::Backbone::Service::Role::Dispatch/dispatcher> argument. It allows the bot to specify a custom dispatcher for that service that still calls that service's methods.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
