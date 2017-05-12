package App::RoboBot::Message;
$App::RoboBot::Message::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::ClassAttribute;
use MooseX::SetOnce;

use DateTime;

use App::RoboBot::Parser;
use App::RoboBot::Response;

has 'raw' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'expression' => (
    is        => 'rw',
    isa       => 'Object',
    predicate => 'has_expression',
);

has 'sender' => (
    is       => 'rw',
    isa      => 'App::RoboBot::Nick',
    traits   => [qw( SetOnce )],
    required => 1,
);

has 'channel' => (
    is        => 'rw',
    isa       => 'App::RoboBot::Channel',
    traits    => [qw( SetOnce )],
    predicate => 'has_channel',
    trigger   => \&update_response_channel,
);

has 'network' => (
    is       => 'rw',
    isa      => 'Object',
    traits   => [qw( SetOnce )],
    required => 1,
);

has 'timestamp' => (
    is       => 'ro',
    isa      => 'DateTime',
    default  => sub { DateTime->now },
    required => 1,
);

has 'response' => (
    is        => 'rw',
    isa       => 'App::RoboBot::Response',
    predicate => 'has_response',
);

has 'vars' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has 'bot' => (
    is       => 'ro',
    isa      => 'App::RoboBot',
    required => 1,
);

class_has 'log' => (
    is          => 'rw',
    predicate   => 'has_logger',
);

sub BUILD {
    my ($self) = @_;

    $self->log($self->bot->logger('core.message')) unless $self->has_logger;

    $self->log->debug(sprintf('Constructing new message object on network %s.', $self->network->name));

    $self->response(App::RoboBot::Response->new(
        bot     => $self->bot,
        network => $self->network,
        nick    => $self->sender,
    ));

    $self->log->debug('Empty response for message initialized.');

    $self->response->channel($self->channel) if $self->has_channel;

    # Short circuit if there's no actual message. This is not an error condition
    # though, since internal/dummy Message objects get created in some plugins
    # where expression evaluations are performed outside the context of a normal
    # user-generated message.
    return if length($self->raw) < 1;

    $self->log->debug(sprintf('Message length greater than 0 (%d). Proceeded with message processing.', length($self->raw)));

    # If the message is nothing but "help" or "!help" then convert it to "(help)"
    if ($self->raw =~ m{^\s*\!?help\s*$}oi) {
        $self->raw("(help)");
    }

    # If the very first character is an exclamation point, check the following
    # non-whitespace characters to see if they match a known command. If they
    # do, convert the incoming message to a simple expression to allow people
    # to interact with the bot using the older "!command arg arg arg" syntax.
    if (substr($self->raw, 0, 1) eq '!') {
        if ($self->raw =~ m{^\!+((\S+).*)}) {
            $self->log->debug(sprintf('Legacy bang syntax detected in message on network %s. Rewriting as an expression.', $self->network->name));

            my ($no_excl, $maybe_cmd) = ($1, $2);

            # If there is at least one pipe character followed by what looks to
            # be possibly another command, treat the incoming message as if it
            # is the old-style piped command chain, and convert to nested
            # expressions.
            if ($no_excl =~ m{\|\s+\!\S+}) {
                my @chained = split(/\|/, $no_excl);

                $no_excl = '';
                foreach my $command (@chained) {
                    $command =~ s{(^\s*\!?|\s*$)}{}gs;
                    $no_excl = sprintf('(%s%s)', $command, (length($no_excl) > 0 ? ' ' . $no_excl : ''));
                }
            } else {
                $no_excl = '(' . $no_excl . ')';
            }

            $self->raw($no_excl)
                if exists $self->bot->commands->{lc($maybe_cmd)}
                || exists $self->bot->macros->{$self->network->id}{lc($maybe_cmd)};
        }
    } elsif ($self->raw =~ m{ ^ $self->bot->nick->name : \s* (.+) }ixs) {
        $self->log->debug(sprintf('Incoming message on network %s was addressed to the bot. Stripping bot name and treating as expression.', $self->network->name));

        # It looks like someone said something to us directly, so strip off our
        # nick from the front, and treat the reast as if it were a command.
        $self->raw('('.$1.')');
    }

    if ($self->raw =~ m{^\s*\(\S+}o) {
        $self->log->debug(sprintf('Incoming message on network %s looks like an expression. Attempting to parse.', $self->network->name));

        my $parser = App::RoboBot::Parser->new( bot => $self->bot );
        my $expr;

        eval {
            $expr = $parser->parse($self->raw);
        };

        if ($@) {
            $self->log->warn(sprintf('Parsing resulted in a suppressable error: %s', $@));
            return;
        }

        if (defined $expr && ref($expr) =~ m{^App::RoboBot::Type::}) {
            $self->log->debug('Message expression parsed successfully. Storing for later evaluation.');

            # To prevent unnecessary echoing of parenthetical remarks, make sure
            # that the top-level form is either an Expression or a List with its
            # own first member being an Expression.
            if ($expr->type eq 'Expression') {
                $self->expression($expr);
            } elsif ($expr->type eq 'List' && defined $expr->value->[0] && $expr->value->[0]->type eq 'Expression') {
                $self->log->debug('Parse resulted in outer layer as List with an Expression as the first element. Stripping outer List.');

                $self->expression($expr);
            }
        }
    }
}

sub process {
    my ($self) = @_;

    $self->log->debug(sprintf('Preparing to process incoming message on network %s.', $self->network->name));

    # Process any before-hooks first
    if ($self->bot->run_before_hooks) {
        $self->log->debug('Processing before_hooks.');

        foreach my $plugin (@{$self->bot->before_hooks}) {
            $self->log->debug(sprintf('Hook from plugin %s being processed.', $plugin->name));

            # Skip hook if plugin is disabled for the current network.
            next if exists $self->network->disabled_plugins->{lc($plugin->name)};

            $plugin->hook_before($self);
        }
    }

    # Process the message itself (unless the network on which it was received is
    # marked as "passive" - only hooks will run, not functions or macros).
    if ($self->has_expression && ! $self->network->passive) {
        $self->log->debug(sprintf('Preparing to evaluate expression (Network %s is non-passive).', $self->network->name));

        my @r = $self->expression->evaluate($self);

        # TODO: Restore pre-type functionality of only adding the implicit
        #       (print ...) call if the last function evaluated wasn't already
        #       an explicit print call.
        if (@r && @r > 0) {
            $self->log->debug('Adding implicit (print) call, as data was returned by outermost expression.');

            $self->bot->commands->{'print'}->process($self, 'print', {}, @r);
        }
    }

    # Process any after-hooks before sending response
    if ($self->bot->run_after_hooks) {
        $self->log->debug('Processing after_hooks.');

        foreach my $plugin (@{$self->bot->after_hooks}) {
            $self->log->debug(sprintf('Hook from plugin %s being processed.', $plugin->name));

            # Skip hook if plugin is disabled for the current network.
            next if exists $self->network->disabled_plugins->{lc($plugin->name)};

            $plugin->hook_after($self);
        }
    }

    # Deliver the response
    $self->log->debug('Issuing response send.');
    $self->response->send;
}

sub update_response_channel {
    my ($self, $new_channel, $old_channel) = @_;

    if ($self->has_response && $self->has_channel) {
        $self->response->channel($new_channel);
    }
}

__PACKAGE__->meta->make_immutable;

1;
