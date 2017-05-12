package Bot::BasicBot::Pluggable::Module::Puppet;
{
  $Bot::BasicBot::Pluggable::Module::Puppet::VERSION = '1.01';
}

use strict;
use warnings;

=head1 NAME

Bot::BasicBot::Pluggable::Module::Puppet - Ventriloquy via POE-flavored YAML over TCP

=head1 DESCRIPTION

Bot::BasicBot::Pluggable::Module::Puppet enables talking in channels as
the bot by sending commands to it over a TCP socket.

=head1 SYNOPSIS

You will need to load the module into your instance:

 $bot->load('Puppet');

The bot will listen on the address and port specified in the store via
the keys C<addr> and C<port>.  If not specified, the bind address and
port will default to C<127.0.0.1> and C<28800>, respectively.

=cut

use POE;
use POE::Component::Server::TCP;

use base 'Bot::BasicBot::Pluggable::Module';

=head1 METHODS

=over 4

=item init

This method is an initialization method called by the constructor
inherited from Bot::BasicBot::Pluggable::Module.  The plugin object
itself is instantiated by the load method in Bot::BasicBot::Pluggable.

The initialization comprises the entire functionality of this plugin.
The real work is done by the POE pieces and the ClientInput callback.

We instantiate a new POE::Component::Server::TCP object that utilizes a
YAML serializer via POE::Filter::Reference.  The TCP server expects to
receive a hashref that is passed directly to the bot's say method.

=cut

sub init
{
	my $self = shift;

	my $addr = $self->get('addr') || '127.0.0.1';
	my $port = $self->get('port') || 28800;

	new POE::Component::Server::TCP
		Address			=> $addr,
		Port			=> $port,
		ClientFilter	=> [ 'POE::Filter::Reference', 'YAML', 0 ],
		ClientInput		=> sub { $self->say(%{ $_[ARG0] }) }
}

=back

=head1 BUGS

This plugin offers absolutely no access control, so be aware of
how/where you deploy it.

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=cut

1;
