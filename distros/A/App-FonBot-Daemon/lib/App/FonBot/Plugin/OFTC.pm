package App::FonBot::Plugin::OFTC;

our $VERSION = '0.001';

use v5.14;
use strict;
use warnings;

use parent qw/App::FonBot::Plugin::IRC/;

use POE;
use POE::Component::IRC::Plugin::AutoJoin;
use POE::Component::IRC::Plugin::Connector;
use POE::Component::IRC::Plugin::NickServID;

use App::FonBot::Plugin::Config qw/$oftc_enabled $oftc_nick @oftc_channels $oftc_nickserv_password/;

##################################################

sub _start{
	return unless $oftc_enabled;
	my $self=$_[OBJECT];

	$self->{irc} = POE::Component::IRC->spawn(
		Nick => $oftc_nick,
		Username => $oftc_nick,
		Ircname => 'FonBot OFTC Transport',
		Server => 'irc.oftc.net',
		Port => 6697,
		UseSSL => 1,
	);
	$self->{irc}->yield(register => qw/msg/);
	$self->{irc}->yield(connect => {});

	$self->{irc}->plugin_add(Connector => POE::Component::IRC::Plugin::Connector->new);
	$self->{irc}->plugin_add(AutoJoin => POE::Component::IRC::Plugin::AutoJoin->new(
		Channels => \@oftc_channels
	));

	$self->{irc}->plugin_add(NickServID => POE::Component::IRC::Plugin::NickServID->new(
		Password => $oftc_nickserv_password
	));

	$_[KERNEL]->alias_set('OFTC');
}

1;

__END__

=head1 NAME

App::FonBot::Plugin::OFTC - FonBot pluginthat provides the OFTC user interface

=head1 SYNOPSIS

    use App::FonBot::Plugin::OFTC;
    App::FonBot::Plugin::OFTC->init;

    END {App::FonBot::Plugin::OFTC->fini};

=head1 DESCRIPTION

This is one of the two implementations of C<App::FonBot::Plugin::IRC>. It connects to OFTC, joins C<$oftc_channel>, identifies with NickServ using the C<$oftc_nickserv_password> password, and processes received commands.

=head1 CONFIGURATION VARIABLES

These are the L<App::FonBot::Plugin::Config> configuration variables used in this module

=over

=item C<$oftc_enabled>

If false, the OFTC plugin is disabled.

=item C<$oftc_nick>

IRC nickname.

=item C<@oftc_channels>

List of channels to join.

=item C<$oftc_nickserv_password>

Password to identify to NickServ with.

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

