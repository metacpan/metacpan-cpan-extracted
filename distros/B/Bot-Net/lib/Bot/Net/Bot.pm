use strict;
use warnings;

package Bot::Net::Bot;

use Bot::Net::Mixin;

use Bot::Net::Message;
use Scalar::Util qw/ reftype /;

require Exporter;
push our @ISA, 'Exporter';

our @EXPORT = (
    # Re-export POE::Session constants
    qw/ OBJECT SESSION KERNEL HEAP STATE SENDER CALLER_FILE CALLER_LINE
        CALLER_STATE ARG0 ARG1 ARG2 ARG3 ARG4 ARG5 ARG6 ARG7 ARG8 ARG9 /,

    # Re-export POE::Declarative
    @POE::Declarative::EXPORT, 
    
    # Re-export Data::Remember
    qw/ remember remember_these recall recall_and_update 
        forget forget_when brain /,

    # Add in our own subs
    qw/ bot setup /,
);

=head1 NAME

Bot::Net::Bot - the base class for all Bot::Net bots

=head1 SYNOPSIS

  # An example for building an Eliza-based chatbot
  use strict;
  use warnings;

  use Bot::Net::Bot;
  use Bot::Net::Mixin::Bot::IRC;
  use Chatbot::Eliza; # available separately on CPAN

  on bot startup => run {
      remember eliza => Chatbot::Eliza->new;
  };

  on bot message_to_me => run {
      my $message = get ARG0;

      my $reply = recall('eliza')->transform( $message->text );
      yield reply_to_sender, $message, $reply;
  };

  1;

=head1 DESCRIPTION

This is the primary mixin-class for all L<Bot::Net> bots. You "inherit" all the features of this mixin by using the class:

  use Bot::Net::Bot; # This is a bot class now

Some things to know about how L<Bot::Net> bots work:

=over

=item *

There is a one-to-one relationship between packages and bot instances. If you want two bots that do the same thing, you will need two different packages. Fortunately, it's easy to clone a bot:

  package MyBotNet::Bot::Chatbot;
  use Bot::Net::Bot;

  # define some state handlers...
  
  package MyBotNet::Bot::Chatbot::Larry;
  use MyBotNet::Bot::Chatbot;

  package MyBotNet::Bot::Chatbot::Bob;
  use MyBotNet::Bot::Chatbot;

This defines three bots that all do the same thing--in this case, we probably only intend to invoke Larry and Bob, but you can do whatever you like.

=item *

TODO FIXME XXX Implement these things...

Make sure you use the C<botnet> command to help you out in this process.

  bin/botnet bot create Chatbot
  bin/botnet bot create Chatbot::Larry Chatbot
  bin/botnet bot create Chatbot::Bob Chatbot

This will create the scaffolding required to setup the classes mentioned in the previous bullet. You can then configure them to run:

  bin/botnet bot host Chatbot::Larry ServerA
  bin/botnet bot host Chatbot::Bob ServerB

=back

=head1 METHODS

=head2 import

Custom exporter for this mixin.

=cut

sub import {
    my $class = shift;

    $class->export_to_level(1, undef);
    $class->export_poe_declarative_to_level;

    my $package = caller;
    no strict 'refs';
    push @{ $package . '::ISA' }, qw/ Bot::Net::Object /;
}

=head2 bot

This is a helper for L<POE::Declarative>. That lets you prefix "bot_" to your POE states. For example:

  on bot message_to_me => run { ... };

is the same as:

  on bot_message_to_me => run { ... };

It can also be used to yield messages:

  yield bot 'startup';

You may choose to use it or not.

=cut

sub bot($) { 'bot_'.shift }

=head1 setup

This method is called to tell the bot to startup. It finds all the mixins that have been added into the class and calls the L</setup> method for each.

=cut

sub setup {
    my $class = shift;
    my $self = bless {}, $class;

    my $name = Bot::Net->short_name_for_bot($class);
    my $config_file = Bot::Net->config->bot_file($name);

    my $config;
    { 
        no strict 'refs';
        $config = ${ $class . '::CONFIG' } || $config_file;
    }

    my $brain = brain->new_heap( Hybrid => [] => 'Memory' );

    # Configuration is defined in the package itself (mostly for testing)
    if (ref $config) {
        $brain->remember( [ 'config' ] => $config );
    }

    # Use the YAML config file
    else {
        -f $config_file
            or die qq{Bot startup failed, }
                .qq{no configuration found for $name: $config_file};

        $brain->register_brain(
            config => [ YAML => file => $config_file ]
        );
    }

    if (my $state_file = $brain->recall([ config => 'state_file' ])) {
        $brain->register_brain(
            state => [ DBM => file => $state_file ]
        );
    }

    $brain->remember([ 'name' ] => $name);
    $brain->remember([ 'log'  ] => $self->log);

    # Setup any mixins
    my $mixins = Bot::Net::Mixin::_mixins_for_package($class);
    for my $mixin (@$mixins) {
        
        # Don't setup this one
        next if $mixin->isa('Bot::Net::Bot');

        if (my $method = $mixin->can('setup')) {
            $method->($self, $brain);
        }
    }

    POE::Declarative->setup($self, $brain);
}

=head2 default_configuration PACKAGE

Returns a base configuration appropriate for all bots.

=cut

sub default_configuration {
    my $class   = shift;
    my $package = shift;

    my $filename = join '/', split /::/,
        Bot::Net->short_name_for_bot($package);

    return {
        state_file => 'var/bot/'.$filename.'.db',
    };
}

=head1 BOT STATES

=head2 on bot startup

Bots should implement this event to perform any startup tasks. This is bot-specific and mixins should not do anything with this event.

=head2 on bot quit MESSAGE

Bots may emit this state to ask the protocol client and all resources attached to the bot to close. The C<MESSAGE> parameter allows you to pass a human readable message that can be passed on as part of the protocol quit or logged or whatever...

If all mixins are implemented correctly, this should very quickly result in the bot entering the L</on _stop> state and L</on bot shutdown>. (If not, the bot may be stuck in a sort of zombie state unable to die.)

=head2 on bot shtudown

This is called (synchronously) during teh L</on _stop> handler immediately before shutdown to handle any last second clean up.

=head1 MIXIN STATES

The base mixin handles the following states.

=head2 on _start

Performs a number of setup tasks. Including:

=over

=item *

Register to receive messages from the IRC component.

=item *

Connect to the IRC server.

=item *

When finished, it fires the L</on bot startup> event.

=back

=cut

on _start => run {
    my $self = get OBJECT;
    my $name = recall 'name';
    my $log  = recall 'log';

    $log->info("Starting bot $name...");

    yield bot 'startup';
};

=head2 on _default

Performs logging of unhandled events. All these logs are put into the DEBUG log, so they won't show up unless DEBUG logging is enabled in your L<Log::Log4perl> configuration.

=cut

on _default => run {
    my $log = recall 'log';
    my ($event, $args) = @_[ ARG0 .. $#_ ];
    my (@output);

    my $arg_number = 0;
    foreach (@$args) {
        SWITCH: {
            if ( ref($_) eq 'ARRAY' ) {
                push ( @output, "[", join ( ", ", @$_ ), "]" );
                last SWITCH;
            }
            if ( ref($_) eq 'HASH' ) {
                push ( @output, "{", join ( ", ", %$_ ), "}" );
                last SWITCH;
            }
            unless ( defined $_ ) {
                $_ = '';
            }
            push ( @output, "'$_'" );
        }
        $arg_number++;
    }
    $log->debug("$event ". join( ' ', @output ));
    return 0;    # Don't handle signals.
};

=head2 on _stop

This calls (synchronously) the L</on bot shutdown> state, to handle any final clean up before quitting.

=cut

on _stop => run {
    call get(SESSION) => bot 'shutdown';
};


=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut
