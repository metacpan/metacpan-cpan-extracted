package App::FonBot::Plugin::BitlBee;

our $VERSION = '0.001';

use v5.14;
use strict;
use warnings;

use parent qw/App::FonBot::Plugin::IRC/;

use POE;
use POE::Component::IRC::Plugin::Connector;

use App::FonBot::Plugin::Config qw/$bitlbee_enabled $bitlbee_nick $bitlbee_server $bitlbee_port $bitlbee_password/;

##################################################

sub _start{
	return unless $bitlbee_enabled;
	my $self=$_[OBJECT];

	$self->{irc} = POE::Component::IRC->spawn(
		Flood => 1,
		Nick => $bitlbee_nick,
		Username => $bitlbee_nick,
		Ircname => 'FonBot',
		Server => $bitlbee_server,
		Port => $bitlbee_port,
	);
	$self->{irc}->yield(register => qw/msg public/);
	$self->{irc}->yield(connect => {});
	$self->{irc}->plugin_add(Connector => POE::Component::IRC::Plugin::Connector->new);

	$_[KERNEL]->alias_set('BITLBEE')
}

sub irc_public{
	my ($self, $msg)=@_[OBJECT, ARG2];
	$self->{irc}->yield(privmsg => '&bitlbee', "identify $bitlbee_password") if $msg =~ /^Welcome to the BitlBee gateway!$/;
	$self->{irc}->yield(privmsg => '&bitlbee', 'yes') if $msg =~ /New request:/;
}

1;
__END__

=encoding utf-8

=head1 NAME

App::FonBot::Plugin::BitlBee - FonBot plugin that provides the BitlBee user interface

=head1 SYNOPSIS

    use App::FonBot::Plugin::BitlBee;
    App::FonBot::Plugin::BitlBee->init;

    END { App::FonBot::Plugin::BitlBee->fini }

=head1 DESCRIPTION

This is one of the two implementations of C<App::FonBot::Plugin::IRC>. It identifies with a bitlbee server, accepts all buddy requests and processes received commands.

=head1 CONFIGURATION VARIABLES

These are the L<App::FonBot::Plugin::Config> configuration variables used in this module

=over

=item C<$bitlbee_enabled>

If false, the BitlBee plugin is disabled.

=item C<$bitlbee_nick>

BitlBee nickname

=item C<$bilbee_server>

BitlBee server hostname

=item C<$bitlbee_port>

BitlBee server port

=item C<$bitlbee_password>

BitlBee identify password

=back

=head1 AUTHOR

Marius Gavrilescu C<< <marius@ieval.ro> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2013-2015 Marius Gavrilescu

This file is part of fonbotd.

fonbotd is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

fonbotd is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with fonbotd.  If not, see <http://www.gnu.org/licenses/>


=cut
