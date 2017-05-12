package App::KGB::Client::RelayMsg;
use utf8;

use strict;
use warnings;

our $VERSION = 1.27;

# vim: ts=4:sw=4:et:ai:sts=4
#
# KGB - an IRC bot helping collaboration -- Simple message relay
# Copyright © 2012 Damyan Ivanov
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 51
# Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

=head1 NAME

App::KGB::Client::RelayMsg - Simple message relay KGB client

=head1 SYNOPSIS

    use App::KGB::Client::RelayMsg;
    my $client = App::KGB::Client::RelayMsg->new(
        # common App::KGB::Client parameters
        repo_id => 'my-repo',
        ...
        relay_message => "It's alive!",
    );
    $client->process;

=head1 DESCRIPTION

B<App::KGB::Client::RelayMsg> passes a simple text message to the bot to put
on IRC. It is useful for notifications not connected with a source
repository like bug submission etc.

See also L<kgb-client(1)>'s C<--relay-msg> option.

=head1 CONSTRUCTOR

=head2 B<new> ()

Standard constructor. Accepts no arguments.

=head1 FIELDS

=over

=item B<relay_message> I<message> (B<mandatory>)

The message to relay.

=back

=head1 METHODS

=over

=item process

Overrides L<App::KGB::Client>'s process method.

=back

=cut

require v5.10.0;
use base 'App::KGB::Client';
use Carp qw(confess);
__PACKAGE__->mk_accessors(qw( relay_message));

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    defined( $self->relay_message ) or confess "relay_message is mandatory";

    return $self;
}

sub process {
    my $self = shift;

    my @servers = $self->shuffle_servers;

    # try all servers in turn until someone succeeds
    my $failure;
    for my $srv (@servers) {
        $failure = eval {
            $srv->relay_message( $self, $self->relay_message,
                { use_irc_notices => $self->use_irc_notices } );
            $self->_last_server($srv);

            $self->note_last_server($srv);
            0;
        } // 1;

        warn $@ if $failure;

        last unless $failure;
    }

    die "Unable to complete notification. All servers failed\n"
        if $failure;
}

1;
