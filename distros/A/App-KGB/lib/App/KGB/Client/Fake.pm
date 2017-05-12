package App::KGB::Client::Fake;
use utf8;

use strict;
use warnings;

our $VERSION = 1.17;

# vim: ts=4:sw=4:et:ai:sts=4
#
# KGB - an IRC bot helping collaboration -- Fake client
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

App::KGB::Client::Fake - Fake KGB client

=head1 SYNOPSIS

    use App::KGB::Client::Fake;
    my $client = App::KGB::Client::Fake(
        # common App::KGB::Client parameters
        repo_id => 'my-repo',
        ...
    );
    $client->process;

=head1 DESCRIPTION

B<App::KGB::Client::Fake> generates a fake commit. It is useful when
testing client-server communication separately from SCM setup. See
L<kgb-client(1)>'s C<--fake> option.

=head1 CONSTRUCTOR

=head2 B<new> ()

Standard constructor. Accepts no arguments.

=head1 FIELDS

None.

=head1 METHODS

=over

=item describe_commit

The first time this method is called, it returns an instance of
L<App::KGB::Commit> containing random information.

All subsequential invocations return B<undef>.

=back

=cut

require v5.10.0;
use base 'App::KGB::Client';
use App::KGB::Change;
use App::KGB::Commit;
use Carp qw(confess);
use Digest::SHA qw(sha1_hex);
__PACKAGE__->mk_accessors(qw( _called ));

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->_called(0);

    return $self;
}

sub describe_commit {
    my ($self) = @_;

    return undef if $self->_called;

    my @changes;
    push @changes,
        App::KGB::Change->new(
        {   action => 'A',
            path   => 'added/file',
        }
        );
    push @changes,
        App::KGB::Change->new(
        {   action => 'M',
            path   => 'file/modified',
        }
        );
    push @changes,
        App::KGB::Change->new(
        {   action => 'D',
            path   => 'file/deleted',
        }
        );

    $self->_called(1);

    return App::KGB::Commit->new(
        {   id      => substr(sha1_hex(time), 0, 7),
            changes => \@changes,
            author  => 'user',
            log     => 'This is a test commit message',
            module  => 'module'
        }
    );
}

1;
