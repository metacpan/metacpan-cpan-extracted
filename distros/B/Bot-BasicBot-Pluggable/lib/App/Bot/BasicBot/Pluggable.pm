package App::Bot::BasicBot::Pluggable;
$App::Bot::BasicBot::Pluggable::VERSION = '1.30';
use Moose;
use Config::Find;
use Bot::BasicBot::Pluggable;
use Bot::BasicBot::Pluggable::Store;
use Moose::Util::TypeConstraints;
use List::MoreUtils qw(any uniq);
use Try::Tiny;
use Log::Log4perl;

with 'MooseX::Getopt::Dashes';
with 'MooseX::SimpleConfig';

use Module::Pluggable
  sub_name    => '_available_stores',
  search_path => 'Bot::BasicBot::Pluggable::Store';

subtype 'App::Bot::BasicBot::Pluggable::Channels'
	=> as 'ArrayRef'
	## Either it's an empty ArrayRef or all channels start with #
	=> where { @{$_} ? any { /^#/ } @{$_} : 1 };

coerce 'App::Bot::BasicBot::Pluggable::Channels'
	=> from 'ArrayRef'
	=> via { [ map { /^#/ ? $_ : "#$_" } @{$_} ] };

subtype 'App::Bot::BasicBot::Pluggable::Store'
	=> as 'Bot::BasicBot::Pluggable::Store';

MooseX::Getopt::OptionTypeMap->add_option_type_to_map(
    'App::Bot::BasicBot::Pluggable::Store' => '=s%'
);

coerce 'App::Bot::BasicBot::Pluggable::Store'
	=> from 'Str'
	=> via { Bot::BasicBot::Pluggable::Store->new_from_hashref({ type => 'Str' }) };

coerce 'App::Bot::BasicBot::Pluggable::Store'
	=> from 'HashRef'
	=> via { Bot::BasicBot::Pluggable::Store->new_from_hashref( shift ) };

has server  => ( is => 'rw', isa => 'Str', default => 'localhost' );
has nick    => ( is => 'rw', isa => 'Str', default => 'basicbot' );
has charset => ( is => 'rw', isa => 'Str', default => 'utf8' );
has channel => (
    is      => 'rw',
    isa     => 'App::Bot::BasicBot::Pluggable::Channels',
    coerce  => 1,
    default => sub { [] }
);
has password => ( is => 'rw', isa => 'Str' );
has port => ( is => 'rw', isa => 'Int', default => 6667 );
has useipv6  => ( is => 'rw', isa => 'Bool', default => 1 );
has localaddr => ( is => 'rw', isa => 'Str' );
has bot_class =>
  ( is => 'rw', isa => 'Str', default => 'Bot::BasicBot::Pluggable' );

has list_modules => ( is => 'rw', isa => 'Bool', default => 0 );
has list_stores  => ( is => 'rw', isa => 'Bool', default => 0 );

has store => (
    is      => 'rw',
    isa     => 'App::Bot::BasicBot::Pluggable::Store',
    coerce  => 1,
    builder => '_create_store'
);
has settings => (
    metaclass => 'NoGetopt',
    is        => 'rw',
    isa       => 'HashRef',
    default   => sub { {} }
);

has loglevel => ( is => 'rw', isa => 'Str', default => 'warn' );
has logconfig => ( is => 'rw', isa => 'Str' );

has configfile => (
    is      => 'rw',
    isa     => 'Str|Undef',
    default => Config::Find->find( name => 'bot-basicbot-pluggable.yaml' ),
);

has bot => (
    metaclass => 'NoGetopt',
    is        => 'rw',
    isa       => 'Bot::BasicBot::Pluggable',
    builder   => '_create_bot',
    lazy      => 1,
);

has module => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { return [qw( Auth Loader )] }
);

sub BUILD {
    my ($self) = @_;

    if ( $self->password() ) {
        $self->module( [ uniq @{ $self->module }, 'Auth' ] );
    }
    $self->_load_modules();
}

sub _load_modules {
    my ($self)   = @_;
    my %settings = %{ $self->settings() };
    my $logger   = Log::Log4perl->get_logger( ref $self );

    # Implicit loading of modules via $self->settings
    my @modules = uniq @{ $self->module() }, keys %settings;
    $self->module( [@modules] );

    for my $module_name (@modules) {
        my $module = try {
            $self->bot->load($module_name);
        }
        catch {
            $logger->error("$_");
        };
        next if !$module;
        if ( exists( $settings{$module_name} ) ) {
            for my $key ( keys %{ $settings{$module_name} } ) {
                $module->set( $key, $settings{$module_name}->{$key} );
            }
        }
        if ( $module_name eq 'Auth' and $self->password() ) {
            $module->set( 'password_admin', $self->password() );
        }
    }
}

sub _create_store {
    return Bot::BasicBot::Pluggable::Store->new_from_hashref(
        { type => 'Memory' } );
}

sub _create_bot {
    my ($self) = @_;
    my $class = $self->bot_class();
    return $class->new(
        channels  => $self->channel(),
        server    => $self->server(),
        nick      => $self->nick(),
        charset   => $self->charset(),
        port      => $self->port(),
        useipv6   => $self->useipv6(),
        localaddr => $self->localaddr(),
        store     => $self->store(),
        loglevel  => $self->loglevel(),
        logconfig => $self->logconfig(),
    );
}

sub run {
    my ($self) = @_;

    if ( $self->list_modules() ) {
        print "$_\n" for $self->bot->available_modules;
        exit 0;
    }

    if ( $self->list_stores() ) {
        for ( $self->_available_stores ) {
            s/Bot::BasicBot::Pluggable::Store:://;
            print "$_\n";
        }
        exit 0;
    }
    $self->bot->run();
}

1;

__END__

=head1 NAME 

App::Bot::BasicBot::Pluggable - Base class for bot applications

=head1 VERSION

version 1.30

=head1 SYNOPSIS

  my bot = App::Bot::BasicBot::Pluggable( modules => [ 'Karma' ] )
  $bot->run();

=head1 DESCRIPTION

This module is basically intended as base class for
L<Bot::BasicBot::Pluggable> frontends. It's attributes can be set
by command line options or a configuration file.

=head1 ATTRIBUTES

All subsequently listed attributes are documented in the manpage
of L<bot-basicbot-pluggable>. Just replace all dashes with underscores.

=over 4

=item server

=item nick

=item charset

=item password

=item port

=item list_modules

=item list_stores

=item loglevel

=item logconfig

=item configfile

=item module

=back

=head1 METHODS

=head2 run

If list_modules or list_stores are set to a true value, the according
list is printed to stdout. Otherwise the run method of the bot
specified by the bot_class method is called.

=head1 AUTHOR

Mario Domgoergen <mdom@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself
