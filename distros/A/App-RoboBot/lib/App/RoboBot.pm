package App::RoboBot;
$App::RoboBot::VERSION = '4.004';
# ABSTRACT: Extensible multi-protocol S-Expression chatbot.

=head1 NAME

App::Robobot - Extensible multi-protocol S-Expression chatbot

=head1 SYNOPSIS

    use AnyEvent;
    use App::RoboBot;
    App::RoboBot->new()->run;

=head1 DESCRIPTION

App::RoboBot provides an event-driven, multi-protocol, multi-network,
user-programmable, plugin-based, S-Expression chatbot. Any text-based chat
service could be supported, with plugins currently for IRC, Slack, and
Mattermost included.

Major features include:

=over 4

=item * S-Expression Syntax

Chatbot commands are issued via an S-Expression syntax (spiritual guidance from
Clojure on some of the sugar for non-list structures). This language, while no
match for a full-blown, general purpose programming environment, is flexible
enough when combined with the macro and plugin support to allow users on your
chat service of choice to dynamically extend the functionality of the bot on
the fly.

=item * Multi-protocol

App::RoboBot currently includes support for IRC, Slack, and Mattermost out of
the box. Additional service plugins would be easy to add, as long as there is
an AnyEvent compatible library for them on CPAN or you are willing to write
one. Network protocol plugins need only implement a small number of methods
for core actions like connection/disconnecting from a network service, parsing
incoming messages, and sending messages.

=item * Multi-network

Bot instances created with App::RoboBot may connect to multiple networks
simultaneously (critical for some plugins like ChannelLink which let you create
your own bridges between disparate networks), even across different protocols.
The only practical limits are memory and bandwidth for the host running your
bot.

=item * Macros

User-defined macros are core to App::RoboBot's operation and allow authorized
users on your chat services to define new functionality for the bot on the fly
using a Lisp-like (emphasis on the "like") language. Macros can invoke
functions, other macros, and even create more macros. Macros use the exact same
S-Expression language as everything else in the bot, and have access to the
full functionality.

=item * Plugins

Nearly all App::RoboBot functionality is provided through the plugin system.
The distribution ships with many plugins already included, from interfaces to
external programs like fortune and filters, all the way through to HTTP clients
and XML parsing and XPath queries. New plugins may be submitted to the core
App::RoboBot project, or distributed separately.

=back

=head1 SEE ALSO

The full documentation for App::RoboBot is available at the following site:

    https://robobot.automatomatromaton.com/

Instructions for installing, configuring, and operating bots with this module
are provided.

=head1 AUTHOR

Jon Sime <jonsime@gmail.com>

=head1 CONTRIBUTORS

=over 4

=item * Lukas Eklund

=item * Mohammad S. Anwar

=item * Shawn Delysse

=back

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2016 by Jon Sime.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

use v5.18;

use namespace::autoclean;

use Moose;
use MooseX::ClassAttribute;
use MooseX::SetOnce;

use AnyEvent;
use Data::Dumper;
use File::ShareDir qw( dist_dir );
use Log::Log4perl;
use Module::Pluggable::Object;

use App::RoboBot::Config;
use App::RoboBot::Message;
use App::RoboBot::Plugin;

use App::RoboBot::Doc;

has 'config_paths' => (
    is        => 'ro',
    isa       => 'ArrayRef[Str]',
    predicate => 'has_config_paths',
);

has 'do_migrations' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 'config' => (
    is        => 'rw',
    isa       => 'App::RoboBot::Config',
    traits    => [qw( SetOnce )],
    predicate => 'has_config',
);

has 'raw_config' => (
    is        => 'ro',
    isa       => 'HashRef',
    predicate => 'has_raw_config',
);

has 'plugins' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has 'doc' => (
    is     => 'rw',
    isa    => 'App::RoboBot::Doc',
    traits => [qw( SetOnce )],
);

has 'before_hooks' => (
    is        => 'rw',
    isa       => 'ArrayRef',
    predicate => 'run_before_hooks',
    default   => sub { [] },
);

has 'after_hooks' => (
    is        => 'rw',
    isa       => 'ArrayRef',
    predicate => 'run_after_hooks',
    default   => sub { [] },
);

has 'networks' => (
    is      => 'rw',
    isa     => 'ArrayRef[App::RoboBot::Network]',
    default => sub { [] },
);

class_has 'commands' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

class_has 'macros' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

sub BUILD {
    my ($self) = @_;

    $self->doc(App::RoboBot::Doc->new( bot => $self ));

    if ($self->has_raw_config) {
        $self->config(App::RoboBot::Config->new( bot => $self, config => $self->raw_config ));
    } else {
        if ($self->has_config_paths) {
            $self->config(App::RoboBot::Config->new( bot => $self, config_paths => $self->config_paths ));
        } else {
            $self->config(App::RoboBot::Config->new( bot => $self ));
        }
    }

    $self->config->load_config;

    my $logger = $self->logger('core.init');
    $logger->info('Configuration loaded.');

    # Gather list of supported plugin commands (naming conflicts are considered
    # warnable offenses, not fatal errors).
    $logger->info('Loading plugins.');
    my $finder = Module::Pluggable::Object->new( search_path => 'App::RoboBot::Plugin', instantiate => 'new' );

    foreach my $plugin ($finder->plugins) {
        $logger->debug(sprintf('Loading %s plugin.', $plugin->name));
        push(@{$self->plugins}, $plugin);
        $plugin->bot($self);
        $plugin->init($self);
        $logger->debug(sprintf('Initialized %s plugin.', $plugin->name));

        foreach my $command (keys %{$plugin->commands}) {
            $logger->warn(sprintf('Command name collision: %s/%s superseded by %s/%s',
                                    $self->commands->{$command}->ns, $command,
                                    $plugin->ns, $command))
                if exists $self->commands->{$command};
            $logger->debug(sprintf('Plugin command %s loaded.', $command));

            # Offer both plain and namespaced access to individual functions
            $self->commands->{$command} = $plugin;
            $self->commands->{sprintf('%s/%s', $plugin->ns, $command)} = $plugin;
        }

        # Gather list of plugins which have before/after hooks.
        push(@{$self->before_hooks}, $plugin) if $plugin->has_before_hook;
        push(@{$self->after_hooks}, $plugin) if $plugin->has_after_hook;
    }

    # Two-phase plugin initialization's second phase now called, so that plugins
    # which require knowledge of the existence of commands/macros/etc. can see
    # that (it having been done already in the first phase). This is critical
    # for plugins which use things like App::RoboBot::Parser to parse stored
    # expressions.
    foreach my $plugin (@{$self->plugins}) {
        $plugin->post_init($self);
    }

    $logger->debug('Plugin post-initialization hooks finished.');

    # Pre-load all saved macros
    $self->macros({ App::RoboBot::Macro->load_all($self) });
    # TODO: This is an awful hack around the fact that nested macros get parsed incorrectly
    #       the first time around, depending on their load order out of the database. The
    #       Parser module doesn't know about their name yet, so it parses them as a String
    #       instead of a Macro object. That should get fixed in a cleaner way, but for now
    #       we can just load them a second time. All their names will be available for the
    #       Parser and we'll just overwrite their definitions with the correct versions.
    $self->macros({ App::RoboBot::Macro->load_all($self) });

    $logger->debug('Macro initializations finished.');
}

sub run {
    my ($self) = @_;

    my $logger = $self->logger('core.run');

    $logger->info('Bot starting.');

    my $c = AnyEvent->condvar;
    $_->connect for @{$self->networks};
    $c->recv;
    $_->disconnect for @{$self->networks};

    $logger->info('Bot disconnected from all networks and preparing to stop.');
}

sub version {
    my ($self) = @_;

    use vars qw( $VERSION );

    return $VERSION // "*-devel";
}

sub logger {
    my ($self, $category) = @_;

    $category = defined $category ? lc($category) : 'core';

    return Log::Log4perl::get_logger($category);
}

sub add_macro {
    my ($self, $network, $nick, $macro_name, $args, $body) = @_;

    my $logger = $self->logger('core.macro');

    $logger->debug(sprintf('Adding macro %s for %s on %s network.', $macro_name, $nick->name, $network->name));

    if (exists $self->macros->{$network->id}{$macro_name}) {
        $logger->debug('Macro already exists. Overwriting definition.');
        $self->macros->{$network->id}{$macro_name}->name($macro_name);
        $self->macros->{$network->id}{$macro_name}->arguments($args);
        $self->macros->{$network->id}{$macro_name}->definition($body);
        $self->macros->{$network->id}{$macro_name}->definer($nick);

        return unless $self->macros->{$network->id}{$macro_name}->save;
    } else {
        $logger->debug('Creating as new macro and saving definition.');
        my $macro = App::RoboBot::Macro->new(
            bot        => $self,
            network    => $network,
            name       => $macro_name,
            arguments  => $args,
            definition => $body,
            definer    => $nick,
        );

        return unless $macro->save;
        $logger->debug('Macro saved successfully. Caching definition for future use.');

        $self->macros->{$network->id} = {} unless exists $self->macros->{$network->id};
        $self->macros->{$network->id}{$macro->name} = $macro;
    }

    return 1;
}

sub remove_macro {
    my ($self, $network, $macro_name) = @_;

    my $logger = $self->logger('core.macro');

    $logger->debug(sprintf('Removing macro %s on %s network.', $macro_name, $network->name));

    return unless exists $self->macros->{$network->id}{$macro_name};

    $self->macros->{$network->id}{$macro_name}->delete;
    delete $self->macros->{$network->id}{$macro_name};

    $logger->debug('Macro successfully removed.');

    return 1;
}

sub network_by_id {
    my ($self, $network_id) = @_;

    return undef unless defined $network_id && $network_id =~ m{^\d+$};
    return (grep { $_->id == $network_id } @{$self->networks})[0] || undef;
}

sub migrate_database {
    my ($self) = @_;

    my $logger = $self->logger('core.migrate');

    $logger->info('Checking database migration status.');

    my $migrations_dir = dist_dir('App-RoboBot') . '/migrations';
    die "Could not locate database migrations (remember to use `dzil run` during development)!"
        unless -d $migrations_dir;

    my $cfg = $self->config->config->{'database'}{'primary'};

    my $db_uri = 'db:pg://';
    $db_uri .= $cfg->{'user'} . '@' if $cfg->{'user'};
    $db_uri .= $cfg->{'host'} if $cfg->{'host'};
    $db_uri .= ':' . $cfg->{'port'} if $cfg->{'port'};
    $db_uri .= '/' . $cfg->{'database'} if $cfg->{'database'};

    $logger->debug(sprintf('Using database URI %s for migration status check.', $db_uri));

    chdir($migrations_dir) or die "Could not chdir() $migrations_dir: $!";

    open(my $status_fh, '-|', 'sqitch', 'status', $db_uri) or die "Could not check database status: $!";
    while (my $l = <$status_fh>) {
        if ($l =~ m{up-to-date}) {
            $logger->info('Database schema up to date. No migrations run.');
            return;
        }
    }
    close($status_fh);

    die "Database schema is out of date, but --migrate was not specified so we cannot upgrade.\n"
        unless $self->do_migrations;

    $logger->info('Migration necessary. Running with verification enabled.');

    open(my $deploy_fh, '-|', 'sqitch', 'deploy', '--verify', $db_uri) or die "Could not begin database migrations: $!";
    while (my $l = <$deploy_fh>) {
        if ($l =~ m{^\s*\+\s*(.+)\s+\.\.\s+(.*)$}) {
            die "Failed during database migration $1.\n" if lc($2) ne 'ok';
        }
    }
    close($deploy_fh);

    $logger->info('Database migration completed successfully.');
}

__PACKAGE__->meta->make_immutable;

1;
