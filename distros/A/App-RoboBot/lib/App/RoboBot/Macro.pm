package App::RoboBot::Macro;
$App::RoboBot::Macro::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::ClassAttribute;
use MooseX::SetOnce;

use App::RoboBot::Nick;
use App::RoboBot::Parser;

use Clone qw( clone );
use Data::Dumper;
use DateTime;
use DateTime::Format::Pg;
use JSON;
use Scalar::Util qw( blessed );

has 'bot' => (
    is       => 'ro',
    isa      => 'App::RoboBot',
    required => 1,
);

has 'id' => (
    is        => 'rw',
    isa       => 'Num',
    traits    => [qw( SetOnce )],
    predicate => 'has_id',
);

has 'network' => (
    is       => 'rw',
    isa      => 'App::RoboBot::Network',
    required => 1,
);

has 'name' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'arguments' => (
    is       => 'rw',
    isa      => 'HashRef',
    default  => sub { { has_optional => 0, positional => [], keyed => {}, rest => undef } },
    required => 1,
);

has 'definition' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'definer' => (
    is        => 'rw',
    isa       => 'App::RoboBot::Nick',
    predicate => 'has_definer',
);

has 'timestamp' => (
    is       => 'rw',
    isa      => 'DateTime',
    traits   => [qw( SetOnce )],
    default  => sub { DateTime->now() },
    required => 1,
);

has 'is_locked' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has 'valid' => (
    is     => 'ro',
    isa    => 'Bool',
    writer => '_set_valid',
);

has 'error' => (
    is     => 'ro',
    isa    => 'Str',
    writer => '_set_error',
);

has 'expression' => (
    is     => 'ro',
    isa    => 'Object',
    writer => '_set_expression',
);

class_has 'log' => (
    is        => 'rw',
    predicate => 'has_logger',
);

sub BUILD {
    my ($self) = @_;

    $self->log($self->bot->logger('core.macro')) unless $self->has_logger;

    $self->log->debug(sprintf('Creating new macro object for %s on network %s.', $self->name, $self->network->name));

    $self->_generate_expression($self->definition) if defined $self->definition;

    $self->log->debug(sprintf('Macro expression generated from definition for %s.', $self->name));
}

around 'definition' => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig() unless @_;

    my $def = shift;

    $self->log->debug(sprintf('Macro definition updating for %s on network %s.', $self->name, $self->network->name));

    $self->_generate_expression($def);
    return $self->$orig($def);
};

sub _generate_expression {
    my ($self, $def) = @_;

    $self->log->debug(sprintf('Generating expression from %s macro definition.', $self->name));

    unless (defined $def) {
        $self->log->debug('No definition body available. Setting empty expression.');

        $self->_set_expression([]);
        return;
    }

    $self->log->debug('Creating expression parser.');

    my $parser = App::RoboBot::Parser->new( bot => $self->bot );
    my $expr = $parser->parse($def);

    $self->log->debug('Macro definition body parsed.');

    unless (defined $expr && blessed($expr) =~ m{^App::RoboBot::Type}) {
        $self->log->debug('Parse results yielded invalid expression. Marking macro as invalid.');

        $self->_set_valid(0);
        $self->_set_error("Macro definition body must be a valid expression or list.");
        return;
    }

    $self->log->debug('Valid expression generated. Marking macro valid and setting internal expression.');

    $self->_set_valid(1);
    $self->_set_expression($expr);
};

sub load_all {
    my ($class, $bot) = @_;

    my $logger = $bot->logger('core.macro');

    $logger->debug('Macro load_all() request.');

    my $res = $bot->config->db->do(q{
        select m.macro_id, m.network_id, m.name, m.arguments, m.definition,
            n.name as nick, m.defined_at, m.is_locked
        from macros m
            join nicks n on (n.id = m.defined_by)
    });

    return unless $res;

    my %macros;

    while ($res->next) {
        my $network = $bot->network_by_id($res->{'network_id'});
        next unless defined $network;

        $logger->debug(sprintf('Loading macro %s for network %s.', $res->{'name'}, $network->name));

        $macros{$network->id} = {} unless exists $macros{$network->id};

        $macros{$network->id}{$res->{'name'}} = $class->new(
            bot        => $bot,
            id         => $res->{'macro_id'},
            network    => $network,
            name       => $res->{'name'},
            arguments  => decode_json($res->{'arguments'}),
            definition => $res->{'definition'},
            definer    => App::RoboBot::Nick->new( config => $bot->config, name => $res->{'nick'} ),
            timestamp  => DateTime::Format::Pg->parse_datetime($res->{'defined_at'}),
            is_locked  => $res->{'is_locked'},
        );
    }

    $logger->debug('All macros loaded. Returning collection.');

    return %macros;
}

sub save {
    my ($self) = @_;

    $self->log->debug(sprintf('Save request for macro %s on network %s.', $self->name, $self->network->name));

    my $res;

    if ($self->has_id) {
        $self->log->debug(sprintf('Macro %s already has ID (%d). Updating existing record.', $self->name, $self->id));

        $res = $self->bot->config->db->do(q{
            update macros set ??? where macro_id = ?
        }, {
            name       => $self->name,
            arguments  => encode_json($self->arguments),
            definition => $self->definition,
            is_locked  => $self->is_locked,
        }, $self->id);

        return 1 if $res;
    } else {
        $self->log->debug(sprintf('Macro %s does not have ID. Creating new record.', $self->name));

        unless ($self->has_definer) {
            $self->log->error(sprintf('Attempted to save macro %s on network %s without a definer attribute.', $self->name, $self->network->name));
            return 0;
        }

        $res = $self->bot->config->db->do(q{
            insert into macros ??? returning macro_id
        }, {
            name       => $self->name,
            network_id => $self->network->id,
            arguments  => encode_json($self->arguments),
            definition => $self->definition,
            defined_by => $self->definer->id,
            defined_at => $self->timestamp,
            is_locked  => $self->is_locked,
        });

        if ($res && $res->next) {
            $self->log->debug(sprintf('New macro record created for %s on network %s (ID %d).', $self->name, $self->network->name, $res->{'macro_id'}));

            $self->id($res->{'macro_id'});
            return 1;
        }
    }

    $self->log->error(sprintf('Save for macro %s on network %s failed.', $self->name, $self->network->name));
    return 0;
}

sub delete {
    my ($self) = @_;

    $self->log->debug(sprintf('Macro delete request for %s on network %s.', $self->name, $self->network->name));

    return 0 unless $self->has_id;

    $self->log->debug(sprintf('Removing macro record for ID %d.', $self->id));

    my $res = $self->bot->config->db->do(q{
        delete from macros where macro_id = ?
    }, $self->id);

    return 0 unless $res;

    $self->log->debug('Record deletion successful.');
    return 1;
}

sub lock {
    my ($self) = @_;

    $self->log->debug(sprintf('Macro lock request for %s on network %s.', $self->name, $self->network->name));

    return 0 if $self->is_locked;

    $self->is_locked(1);
    return $self->save;
}

sub unlock {
    my ($self) = @_;

    $self->log->debug(sprintf('Macro unlock request for %s on network %s.', $self->name, $self->network->name));

    return 0 if ! $self->is_locked;

    $self->is_locked(0);
    return $self->save;
}

sub expand {
    my ($self, $message, $rpl, @args) = @_;

    $self->log->debug(sprintf('Macro expansion for %s on network %s (%d arguments).', $self->name, $self->network->name, scalar(@args)));

    my $expr = clone($self->expression);

    $self->log->debug('Macro expression cloned.');

    my $req_count = scalar( grep { $_->{'optional'} != 1 } @{$self->arguments->{'positional'}} ) // 0;
    if ($req_count > 0 && scalar(@args) < $req_count) {
        $self->log->error(sprintf('Macro expansion received incorrect number of arguments (expected %d, got %d).', $req_count, scalar(@args)));

        $message->response->raise('Macro %s expects at least %d arguments, but you provided %d.', $self->name, $req_count, scalar(@args));
        return;
    }

    # TODO: Add a first pass to collect any &key'ed arguments first, before
    #       processing the simple positional ones. Possibly needs to be done
    #       even before the argument count check above is performed.
    foreach my $arg (@{$self->arguments->{'positional'}}) {
        # No need to care whether argument is required or not at this point.
        # We would have already errored out above if there was a mismatch. Just
        # set the optional ones without values to undefined.
        $rpl->{$arg->{'name'}} = @args ? shift(@args) : undef;
    }
    # If anything is left in the arguments list passed to the macro invocation,
    # then it belongs in &rest, should the macro care to make use of them.
    if ($self->arguments->{'rest'} && @args) {
        # TODO: Array support in variables still needs work. For now, join all
        #       remaining values from &rest into a single space-delim string.
        $rpl->{ $self->arguments->{'rest'} } = join(' ', @args);
    }

    $self->log->debug('Macro arguments constructed. Preparing to evaluate.');

    return $expr->evaluate($message, $rpl);
}

sub signature {
    my ($self) = @_;

    $self->log->debug(sprintf('Generating macro signature for %s on network %s.', $self->name, $self->network->name));

    my @arg_list = ();

    if (scalar(@{$self->arguments->{'positional'}}) > 0) {
        my $opt_shown = 0;

        foreach my $arg (@{$self->arguments->{'positional'}}) {
            if (!$opt_shown && $arg->{'optional'}) {
                # TODO: Before listing optional positional arguments, list out
                # any required &key'ed arguments. (And then follow up with the
                # optional &key'ed arguments after listing the optional
                # positionals.)
                push(@arg_list, '&optional');
                $opt_shown = 1;
            }

            push(@arg_list, $arg->{'name'});
        }
    }

    if ($self->arguments->{'rest'}) {
        push(@arg_list, '&rest', $self->arguments->{'rest'});
    }

    return join(' ', @arg_list);
}

__PACKAGE__->meta->make_immutable;

1;
