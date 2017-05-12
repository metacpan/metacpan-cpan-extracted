package App::RoboBot::Network;
$App::RoboBot::Network::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

has 'type' => (
    is      => 'ro',
    isa     => 'Str',
    default => '',
);

has 'id' => (
    is     => 'rw',
    isa    => 'Num',
    traits => [qw( SetOnce )],
);

has 'config' => (
    is       => 'ro',
    isa      => 'App::RoboBot::Config',
    required => 1,
);

has 'bot' => (
    is       => 'ro',
    isa      => 'App::RoboBot',
    required => 1,
);

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'nick' => (
    is       => 'ro',
    isa      => 'App::RoboBot::Nick',
    required => 1,
);

has 'channels' => (
    is      => 'rw',
    isa     => 'ArrayRef[App::RoboBot::Channel]',
    default => sub { [] },
);

has 'passive' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 'disabled_plugins' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has 'log' => (
    is        => 'rw',
    predicate => 'has_logger',
);

sub BUILD {
    my ($self, $args) = @_;

    $self->log($self->bot->logger('network.' . lc($self->type) . '.' . lc($self->name))) unless $self->has_logger;

    $self->log->debug('Attempting to retrieve network record.');

    my $res = $self->config->db->do(q{
        select id, name
        from networks
        where lower(name) = lower(?)
    }, $self->name);

    if ($res && $res->next) {
        $self->log->debug(sprintf('Located record for ID %d.', $res->{'id'}));

        $self->id($res->{'id'});
    } else {
        $self->log->debug('No existing record. Creating new network record.');

        $res = $self->config->db->do(q{
            insert into networks ??? returning id
        }, { name => $self->name });

        if ($res && $res->next) {
            $self->log->debug(sprintf('New network record (ID %d) created.', $res->{'id'}));

            $self->id($res->{'id'});
        } else {
            die $self->log->fatal('Could not generate a new network ID.');
        }
    }

    # downcase all disabled plugin names for easier matching during message processing
    if (scalar(keys(%{$self->disabled_plugins})) > 0) {
        $self->log->debug(sprintf('Network %s has disabled plugins. Normalizing names for easier lookup later.', $self->name));

        $self->disabled_plugins({
            map { lc($_) => 1 }
            grep { $self->disabled_plugins->{$_} =~ m{(yes|on|true|1|disabled)}i }
            keys %{$self->disabled_plugins}
        });
    }
}

__PACKAGE__->meta->make_immutable;

1;
