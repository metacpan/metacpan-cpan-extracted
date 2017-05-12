package App::RoboBot::Config;
$App::RoboBot::Config::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

use Config::Any::Merge;
use DBD::Pg;
use DBIx::DataStore;
use File::HomeDir;
use Log::Log4perl;
use Log::Log4perl::Appender::Screen;
use Try::Tiny;

use App::RoboBot::NetworkFactory;
use App::RoboBot::Channel;
use App::RoboBot::Nick;

has 'bot' => (
    is       => 'ro',
    isa      => 'App::RoboBot',
    required => 1,
);

has 'config_paths' => (
    is        => 'rw',
    isa       => 'ArrayRef[Str]',
    traits    => [qw( SetOnce )],
    predicate => 'has_config_paths',
);

has 'config' => (
    is        => 'rw',
    isa       => 'HashRef',
    predicate => 'has_config',
);

has 'networks' => (
    is  => 'rw',
    isa => 'HashRef',
);

has 'channels' => (
    is  => 'rw',
    isa => 'ArrayRef[App::RoboBot::Channel]',
);

has 'plugins' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has 'db' => (
    is => 'rw',
    isa => 'DBIx::DataStore',
    traits => [qw( SetOnce )],
);

sub load_config {
    my ($self) = @_;

    my ($logger);

    try {
        unless ($self->has_config) {
            $self->locate_config unless $self->has_config_paths;

            if (my $cfg = Config::Any::Merge->load_files({ files => $self->config_paths, use_ext => 1, override => 1 })) {
                $self->config($cfg);
            } else {
                die "Could not load configuration files: " . join(', ', @{$self->config_paths});
            }
        }

        $self->init_logging;

        $logger = $self->bot->logger('core.config');

        $self->validate_database;
        $logger->debug('Database configuration initialized.');

        $self->validate_globals;
        $logger->debug('Global settings initialized.');

        $self->validate_networks;
        $logger->debug('Network configurations initialized.');

        $self->validate_plugins;
        $logger->debug('Plugin configurations initialized.');

        $self->bot->networks([ values %{$self->networks} ]);
    } catch {
        die "Could not load and validate configuration: $_";
    };

    $logger->debug('All configuration data loaded.');
}

sub locate_config {
    my ($self) = @_;

    my $home = File::HomeDir->my_home();
    my @exts = qw( conf yml yaml json xml ini );
    my @bases = ("$home/.lispy/lispy.", "$home/.lispy.", "/etc/lispy.");

    my @configs;

    foreach my $base (@bases) {
        foreach my $ext (@exts) {
            push(@configs, $base . $ext);
        }
    }

    my @found;

    CONFIG_FILE:
    foreach my $path (@configs) {
        if (-f $path && -r _) {
            push(@found, $path);
        }
    }

    $self->config_paths([reverse @found]);

    die "Unable to locate a configuration file!" unless $self->has_config_paths;
}

sub init_logging {
    my ($self) = @_;

    my $log_cfg = $self->config->{'logging'} // {
        'log4j.rootLogger'              => 'INFO, stdout',
        'log4j.appender.stdout'         => 'org.apache.log4j.ConsoleAppender',
        'log4j.appender.stdout.layout'  => 'org.apache.log4j.PatternLayout',
        'log4j.appender.stdout.layout.ConversionPattern' => '%d %5p [%c] %m%n',
    };

    my $config_str = join("\n", map { sprintf('%s=%s', $_, $log_cfg->{$_}) } sort keys %{$log_cfg});

    Log::Log4perl::init( \$config_str );
}

sub validate_globals {
    my ($self) = @_;

    my $logger = $self->bot->logger('core.config.globals');

    my %global = (
        nick => 'lispy',
    );

    $self->config->{'global'} = \%global unless exists $self->config->{'global'};

    foreach my $k (keys %global) {
        $self->config->{'global'}{$k} = $global{$k} unless exists $self->config->{'global'}{$k};
    }

    $logger->debug(sprintf('Global setting %s = %s.', $_, $self->config->{'global'}{$_}))
        for sort keys %{$self->config->{'global'}};

    $self->config->{'global'}{'nick'} = App::RoboBot::Nick->new(
        config => $self,
        name   => $self->config->{'global'}{'nick'}
    );
}

sub validate_database {
    my ($self) = @_;

    my $logger = $self->bot->logger('core.config.database');

    my %database = (
        name => 'robobot',
    );

    $self->config->{'database'} = \%database unless exists $self->config->{'database'};

    foreach my $k (keys %database) {
        $self->config->{'database'}{$k} = $database{$k} unless exists $self->config->{'database'}{$k};
    }

    if (exists $self->config->{'database'}{'primary'} && ref($self->config->{'database'}{'primary'}) eq 'HASH') {
        $logger->debug('Establishing database connection using explicit configuration hash.');
        $self->db(DBIx::DataStore->new({ config => $self->config->{'database'} })) or die "Could not validate explicit database connection!";
    } else {
        $logger->debug('Establishing database connection using named DataStore definition.');
        $self->db(DBIx::DataStore->new($self->config->{'database'}{'name'})) or die "Could not validate named database connection!";
    }

    $self->bot->migrate_database;
}

sub validate_networks {
    my ($self) = @_;

    my $logger = $self->bot->logger('core.config.networks');

    my @networks;
    my @channels;

    $logger->debug('Creating network factory.');

    my $nfactory = App::RoboBot::NetworkFactory->new(
        bot    => $self->bot,
        config => $self,
        nick   => $self->config->{'global'}{'nick'},
    );

    foreach my $network_name (keys %{$self->config->{'network'}}) {
        $logger->debug(sprintf('Getting configuration data for network %s.', $network_name));
        my $net_cfg = $self->config->{'network'}{$network_name};

        # Do not load (and eventually connect to) the network if the 'enabled'
        # property exists and is set to a falsey value.
        next if exists $self->config->{'network'}{$network_name}{'enabled'}
            && !$self->config->{'network'}{$network_name}{'enabled'};

        $logger->debug(sprintf('Using factory to create network entry for %s.', $network_name));
        push(@networks, $nfactory->create($network_name, $net_cfg));

        my @network_channels;

        # Coerce channel list into an arrayref if only a single channel is
        # listed for this network.
        $net_cfg->{'channel'} = [] unless exists $net_cfg->{'channel'};
        $net_cfg->{'channel'} = [$net_cfg->{'channel'}] if ref($net_cfg->{'channel'}) ne 'ARRAY';

        foreach my $chan_name (@{$net_cfg->{'channel'}}) {
            $logger->debug(sprintf('Adding %s to channel list for network %s.', $chan_name, $network_name));
            push(@network_channels, App::RoboBot::Channel->new( config => $self, network => $networks[-1], name => $chan_name));
            push(@channels, $network_channels[-1]);
        }

        $networks[-1]->channels([@network_channels]);
    }

    $logger->debug('Assigning networks list to bot.');
    $self->networks({ map { $_->name => $_ } @networks });
    $self->channels(\@channels);
}

sub validate_plugins {
    my ($self) = @_;

    my $logger = $self->bot->logger('core.config.plugins');

    foreach my $plugin_name (keys %{$self->config->{'plugin'}}) {
        $logger->debug(sprintf('Collecting configuration data for %s plugin.', $plugin_name));
        $self->plugins->{lc($plugin_name)} = $self->config->{'plugin'}{$plugin_name};
    }
}

__PACKAGE__->meta->make_immutable;

1;
