package App::RoboBot::Channel;
$App::RoboBot::Channel::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::ClassAttribute;
use MooseX::SetOnce;

use JSON;

has 'id' => (
    is        => 'rw',
    isa       => 'Int',
    traits    => [qw( SetOnce )],
    predicate => 'has_id',
);

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    predicate => 'has_name' # TODO: this is pointless, but something is still calling it and that needs to be fixed
);

has 'extradata' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has 'log_enabled' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);

has 'network' => (
    is        => 'ro',
    isa       => 'App::RoboBot::Network',
    required  => 1,
    predicate => 'has_network' # TODO: this is pointless, but something is still calling it and that needs to be fixed
);

has 'config' => (
    is       => 'ro',
    isa      => 'App::RoboBot::Config',
    required => 1,
);

class_has 'log' => (
    is        => 'rw',
    predicate => 'has_logger',
);

sub find_by_id {
    my ($class, $bot, $id) = @_;

    my $logger = $bot->logger('core.channel');

    $logger->debug(sprintf('Attempting to locate channel by ID %d.', $id));

    my $res = $bot->config->db->do(q{
        select c.id, c.name, c.extradata, c.log_enabled, n.name as network
        from channels c
            join networks n on (n.id = c.network_id)
        where c.id = ?
    }, $id);

    return unless $res && $res->next;

    $logger->debug(sprintf('Found channel %s on network %s (ID %d).', $res->{'name'}, $res->{'network'}, $res->{'id'}));

    return $class->new(
        id          => $res->{'id'},
        name        => $res->{'name'},
        extradata   => decode_json($res->{'extradata'}),
        log_enabled => $res->{'log_enabled'},
        network     => (grep { $_->name eq $res->{'network'} } @{$bot->networks})[0],
        config      => $bot->config,
    );
}

sub BUILD {
    my ($self) = @_;

    $self->log($self->config->bot->logger('core.channel')) unless $self->has_logger;

    $self->log->debug('Building new channel object.');

    unless ($self->has_id) {
        $self->log->debug('Channel object does not already have ID. Preparing to store new channel record.');
        die "Invalid channel creation" unless $self->has_name && $self->has_network;

        my $res = $self->config->db->do(q{
            select id, log_enabled
            from channels
            where network_id = ? and lower(name) = lower(?)
        }, $self->network->id, $self->name);

        if ($res && $res->next) {
            $self->log->debug(sprintf('Located existing record (ID %d).', $res->{'id'}));

            $self->id($res->{'id'});
            $self->log_enabled($res->{'log_enabled'});
        } else {
            $self->log->debug('Creating new channel record.');

            $res = $self->config->db->do(q{
                insert into channels ??? returning id
            }, {
                network_id  => $self->network->id,
                name        => $self->name,
                log_enabled => $self->log_enabled,
            });

            if ($res && $res->next) {
                $self->log->debug(sprintf('Channel %s has received new ID %d.', $self->name, $res->{'id'}));

                $self->id($res->{'id'});
            }
        }

        die "Could not generate channel ID" unless $self->has_id;
    }

    $self->log->debug('Finished building new channel object.');
}

sub join {
    my ($self) = @_;

    $self->log->debug(sprintf('Channel join request for %s on network %s.', $self->name, $self->network->name));

    $self->network->join_channel($self);
}

sub part {
    my ($self, $irc) = @_;

    $self->log->debug(sprintf('Channel part request for %s on network %s.', $self->name, $self->network->name));

    # TODO switch to AnyEvent and perform part appropriate to network's type
}

sub disable_logging {
    my ($self) = @_;

    $self->log->debug(sprintf('Channel logging disable for %s on network %s.', $self->name, $self->network->name));

    return 1 unless $self->log_enabled;

    my $res = $self->config->db->do(q{
        update channels
        set log_enabled = false
        where id = ?
    }, $self->id);

    return 0 unless $res;

    $self->log_enabled(0);
    return 1;
}

sub enable_logging {
    my ($self) = @_;

    $self->log->debug(sprintf('Channel logging enable for %s on network %s.', $self->name, $self->network->name));

    return 1 if $self->log_enabled;

    my $res = $self->config->db->do(q{
        update channels
        set log_enabled = true
        where id = ?
    }, $self->id);

    return 0 unless $res;

    $self->log_enabled(1);
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
