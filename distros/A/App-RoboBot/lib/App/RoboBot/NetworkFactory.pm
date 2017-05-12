package App::RoboBot::NetworkFactory;
$App::RoboBot::NetworkFactory::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;

use Module::Loaded;

use App::RoboBot::Nick;
use App::RoboBot::Network::IRC;
use App::RoboBot::Network::Mattermost;
use App::RoboBot::Network::Slack;

has 'bot' => (
    is       => 'ro',
    isa      => 'App::RoboBot',
    required => 1,
);

has 'config' => (
    is       => 'ro',
    isa      => 'App::RoboBot::Config',
    required => 1,
);

has 'nick' => (
    is       => 'ro',
    isa      => 'App::RoboBot::Nick',
    required => 1,
);

has 'log' => (
    is        => 'rw',
    predicate => 'has_logger',
);

sub BUILD {
    my ($self) = @_;

    $self->log($self->bot->logger('core.network.factory')) unless $self->has_logger;
}

sub create {
    my ($self, $name, $net_cfg) = @_;

    $self->log->debug('Preparing to create new network object.');

    die $self->log->fatal('Network name not provided.') unless defined $name && $name =~ m{^[a-z0-9_-]+$}oi;
    die $self->log->fatal('Configuration invalid.') unless defined $net_cfg && ref($net_cfg) eq 'HASH';
    die $self->log->fatal('Missing network type.') unless exists $net_cfg->{'type'};

    # Check for network-specific nick (and create object for it if present) or
    # fall back to the NetworkFactory default nick.
    if (exists $net_cfg->{'nick'}) {
        $self->log->debug(sprintf('Network %s has a custom nick (%s). Overriding global nick for this network.', $name, $net_cfg->{'nick'}));

        $net_cfg->{'nick'} = App::RoboBot::Nick->new(
            config => $self->config,
            name   => $net_cfg->{'nick'},
        );
    } else {
        $net_cfg->{'nick'} = $self->nick;
    }

    return $self->create_irc($name, $net_cfg) if $net_cfg->{'type'} eq 'irc';
    return $self->create_mattermost($name, $net_cfg) if $net_cfg->{'type'} eq 'mattermost';
    return $self->create_slack($name, $net_cfg) if $net_cfg->{'type'} eq 'slack';

    die $self->log->fatal(sprintf('Invalid network type (%s).', ($net_cfg->{'type'} // '-')));
}

sub create_irc {
    my ($self, $name, $net_cfg) = @_;

    $self->log->debug(sprintf('IRC network creation for %s.', $name));

    return App::RoboBot::Network::IRC->new(
        %{$net_cfg},
        bot    => $self->bot,
        name   => $name,
        config => $self->config,
    );
}

sub create_mattermost {
    my ($self, $name, $net_cfg) = @_;

    $self->log->debug(sprintf('Mattermost network creation for %s.', $name));

    return App::RoboBot::Network::Mattermost->new(
        %{$net_cfg},
        bot    => $self->bot,
        name   => $name,
        config => $self->config,
    );
}

sub create_slack {
    my ($self, $name, $net_cfg) = @_;

    $self->log->debug(sprintf('Slack network creation for %s.', $name));

    return App::RoboBot::Network::Slack->new(
        %{$net_cfg},
        bot    => $self->bot,
        name   => $name,
        config => $self->config,
    );
}

__PACKAGE__->meta->make_immutable;

1;
