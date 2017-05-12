package Adam;
BEGIN {
  $Adam::VERSION = '0.91';
}
# ABSTRACT: The patriarch of IRC Bots
# Dist::Zilla: +PodWeaver
use MooseX::POE;
use namespace::autoclean;

use POE::Component::IRC::Common qw( :ALL );
use POE qw(
  Component::IRC::State
  Component::IRC::Plugin::PlugMan
  Component::IRC::Plugin::Connector
  Component::IRC::Plugin::ISupport
  Component::IRC::Plugin::NickReclaim
  Component::IRC::Plugin::BotAddressed
  Component::IRC::Plugin::AutoJoin
);

use MooseX::Aliases;
use Adam::Logger::Default;

with qw(
  MooseX::SimpleConfig
  MooseX::Getopt
);

has logger => (
    does       => 'Adam::Logger::API',
    is         => 'ro',
    traits     => ['NoGetopt'],
    lazy_build => 1,
    handles    => 'Adam::Logger::API',
);

sub _build_logger { Adam::Logger::Default->new() }

has nickname => (
    isa      => 'Str',
    reader   => 'get_nickname',
    alias    => 'nick',
    traits   => ['Getopt'],
    cmd_flag => 'nickname',
    required => 1,
    builder  => 'default_nickname',
);

sub default_nickname { $_[0]->meta->name }

has server => (
    isa      => 'Str',
    reader   => 'get_server',
    traits   => ['Getopt'],
    cmd_flag => 'server',
    required => 1,
    builder  => 'default_server',
);

sub default_server { 'irc.perl.org' }

has port => (
    isa      => 'Int',
    reader   => 'get_port',
    traits   => ['Getopt'],
    cmd_flag => 'port',
    required => 1,
    builder  => 'default_port',
);

sub default_port { 6667 }

has channels => (
    isa        => 'ArrayRef',
    reader     => 'get_channels',
    traits     => ['Getopt'],
    cmd_flag   => 'channels',
    builder    => 'default_channels',
    auto_deref => 1,
);

sub default_channels { [] }

has owner => (
    isa      => 'Str',
    accessor => 'get_owner',
    traits   => ['Getopt'],
    cmd_flag => 'owner',
    builder  => 'default_owner',
);

sub default_owner { 'perigrin!~perigrin@217.168.150.167' }

has username => (
    isa      => 'Str',
    accessor => 'get_username',
    traits   => ['Getopt'],
    cmd_flag => 'username',
    builder  => 'default_username',
);

sub default_username { 'adam' }

has password => (
    isa      => 'Str',
    accessor => 'get_password',
    traits   => ['Getopt'],
    cmd_flag => 'password',
    builder  => 'default_password',
);

sub default_password { '' }

has flood => (
    isa      => 'Bool',
    reader   => 'can_flood',
    traits   => ['Getopt'],
    cmd_flag => 'flood',
    builder  => 'default_flood',
);

sub default_flood { 0 }

has plugins => (
    isa        => 'HashRef',
    traits     => [ 'Hash', 'NoGetopt' ],
    lazy       => 1,
    auto_deref => 1,
    builder    => 'default_plugins',
    handles    => {
        plugin_names => 'keys',
        get_plugin   => 'get',
        has_plugins  => 'count'
    }
);

sub core_plugins {
    return {
        'Core_Connector'    => 'POE::Component::IRC::Plugin::Connector',
        'Core_BotAddressed' => 'POE::Component::IRC::Plugin::BotAddressed',
        'Core_AutoJoin'     => POE::Component::IRC::Plugin::AutoJoin->new(
            Channels => { map { $_ => '' } @{ $_[0]->get_channels } },
        ),
        'Core_NickReclaim' =>
          POE::Component::IRC::Plugin::NickReclaim->new( poll => 30 ),
    };
}

sub custom_plugins { {} }

sub default_plugins {
    return { %{ $_[0]->core_plugins }, %{ $_[0]->custom_plugins } };
}

has plugin_manager => (
    isa        => 'POE::Component::IRC::Plugin::PlugMan',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_plugin_manager {
    POE::Component::IRC::Plugin::PlugMan->new(
        botowner => $_[0]->get_owner,
        debug    => 1
    );
}

before 'START' => sub {
    my ($self) = @_;
    $self->plugin_add( 'PlugMan' => $self->plugin_manager );
};

has poco_irc_args => (
    isa      => 'HashRef',
    accessor => 'get_poco_irc_args',
    traits   => [ 'Hash', 'Getopt' ],
    cmd_flag => 'extra_args',
    builder  => 'default_poco_irc_args',
);

sub default_poco_irc_args {
    {};
}

has poco_irc_options => (
    isa      => 'HashRef',
    accessor => 'get_poco_irc_options',
    traits   => [ 'Hash', 'Getopt' ],
    cmd_flag => 'extra_args',
    builder  => 'default_poco_irc_options',
);

sub default_poco_irc_options { { trace => 0 } }

has _irc => (
    isa        => 'POE::Component::IRC',
    accessor   => 'irc',
    lazy_build => 1,
    handles    => {
        irc_session_id => 'session_id',
        server_name    => 'server_name',
        plugin_add     => 'plugin_add',
    }
);

sub _build__irc {
	my $self = shift;
    POE::Component::IRC::State->spawn(
        Nick     => $self->get_nickname,
        Server   => $self->get_server,
        Port     => $self->get_port,
        Ircname  => $self->get_nickname,
        Options  => $self->get_poco_irc_options,
        Flood    => $self->can_flood,
        Username => $self->get_username,
        Password => $self->get_password,
		%{ $self->get_poco_irc_args },
    );
}

sub privmsg {
    my $self = shift;
    POE::Kernel->post( $self->irc_session_id => privmsg => @_ );
}

sub START {
    my ( $self, $heap ) = @_[ OBJECT, HEAP ];
    $poe_kernel->post( $self->irc_session_id => register => 'all' );
    $poe_kernel->post( $self->irc_session_id => connect  => {} );
    $self->info( 'connecting to ' . $self->get_server . ':' . $self->get_port );
    return;
}

sub load_plugin {
    my ( $self, $name, $plugin ) = @_;
    $self->plugin_manager->load( $name => $plugin, bot => $self );
}

event irc_plugin_add => sub {
    my ( $self, $desc, $plugin ) = @_[ OBJECT, ARG0, ARG1 ];
    $self->info("loaded plugin: $desc");
    if ( $desc eq 'PlugMan' ) {
        $self->debug("loading other plugins");
        for my $name ( sort $self->plugin_names ) {
            $self->debug("loading $name");
            $plugin = $self->get_plugin($name);
            $self->load_plugin( $name => $plugin );
        }
    }
};

event irc_connected => sub {
    my ( $self, $sender ) = @_[ OBJECT, SENDER ];
    $self->info( "connected to " . $self->get_server . ':' . $self->get_port );
    return;
};

# We registered for all events, this will produce some debug info.
sub DEFAULT {
    my ( $self, $event, $args ) = @_[ OBJECT, ARG0 .. $#_ ];
    my @output = ("$event: ");

    foreach my $arg (@$args) {
        if ( ref($arg) eq ' ARRAY ' ) {
            push( @output, "[" . join( " ,", @$arg ) . "]" );
        }
        else {
            push( @output, "'$arg' " );
        }
    }
    $self->debug( join ' ', @output );
    return 0;
}

sub run {
    $_[0]->new_with_options unless blessed $_[0];
    POE::Kernel->run;
}

1;    # Magic true value required at end of module



=pod

=head1 NAME

Adam - The patriarch of IRC Bots

=head1 VERSION

version 0.91

=head1 SYNOPSIS

See the Synopsis in L<Moses|Moses>. Adam is not meant to be used directly.

=head1 DESCRIPTION

The Adam class implements a basic L<POE::Component::IRC|POE::Component::IRC>
bot based on L<Moose|Moose> and L<MooseX::POE|MooseX::POE>.

=head1 ATTRIBUTES

=head2 nickname (Str)

The IRC nickname for the bot, it will default to the package name.

=head2 server (Str)

The IRC server to connect to.

=head2 port (Int)

The port for the IRC server, defaults to 6667

=head2 username(Str)

The username which we should use

=head2 password(Str)

The server password which we shoulduse

=head2 channels (ArrayRef[Str])

IRC channels to connect to.

=head2 owner (Str)

The hostmask of the ower of the bot. The owner can control the bot's plugins
through IRC using the <POE::Component::IRC::Plugin::Plugman|Plugman>
interface.

=head2 flood (Bool)

Disable flood protection. Defaults to False.

=head2 plugins (HashRef)

A list of plugins associated with the IRC bot. See L<Moses::Plugin> for more
details.

=head2 extra_args (HashRef)

A list of extra arguments to pass to the irc constructor.

=head1 METHODS

=head2 privmsg (Str $who, Str $what)

Send message C<$what> as a private message to C<$who>, a channel or nick.

=head2 run ()

Start the IRC bot. This method also works as a Class Method and will
instanciate the bot if called as such.

=head1 DEPENDENCIES

L<MooseX::POE|MooseX::POE>, L<namespace::autoclean|namespace::autoclean>,
L<MooseX::Alias|MooseX::Alias>, L<POE::Component::IRC|POE::Component::IRC>,
L<MooseX::Getopt|MooseX::Getopt>,
L<MooseX::SimpleConfig|MooseX::SimpleConfig>,
L<MooseX::LogDispatch|MooseX::LogDispatch>

=head1 BUGS AND LIMITATIONS

None known currently, please report bugs to L<https://rt.cpan.org/Ticket/Create.html?Queue=Adam>

=head1 AUTHORS

=over 4

=item *

Chris Prather <chris@prather.org>

=item *

Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Chris Prather, Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

