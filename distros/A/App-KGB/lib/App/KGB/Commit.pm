# vim: ts=4:sw=4:et:ai:sts=4
#
# KGB - an IRC bot helping collaboration
# Copyright © 2008 Martín Ferrari
# Copyright © 2009 Damyan Ivanov
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
package App::KGB::Commit;

use strict;
use warnings;

our $VERSION = 1.27;

=head1 NAME

App::KGB::Commit - a single commit

=head1 SYNOPSIS

    my $c = App::KGB::Commit->new(
        {   id      => 4536,
            changes => ["(M)/there"],
            log     => "fixed /there",
            author  => "My Self <mself@here.at>",
            branch  => "trunk",
            module  => "test",
        }
    );

=head1 DESCRIPTION

B<App::KGB::Change> encapsulates a single commit. A commit has several
properties: an ID, a list of changes, an author, a log message, optionally also
a branch and a module.

=head1 FIELDS

=over

=item B<id>

The commit ID that uniquely identifies it in the repository (if applicable).

=item B<changes>

An arrayref of L<App::KGB::Change> instances or other objects that behave as
strings.

=item B<author>

=item B<log>

=item B<branch>

=item B<module>

=back

=cut

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors( qw( id changes log author author_name branch module ) );

use Carp qw(confess);

=head1 CONSTRUCTOR

=head2 new ( { I<initial field values> } )

Standard constructor. Accepts a hashref with field values.

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    not defined( $self->changes )
        or ref( $self->changes ) and ref( $self->changes ) eq 'ARRAY'
        or confess "'changes' must be an arrayref";

    my $log = $self->log;
    utf8::decode($log)
        or $log = "(log message is not valid UTF-8)"
        if defined($log);
    $self->log($log);

    return $self;
}

=head1 OVERLOADS

=over

=item stringify

Returns a text representation of the commit object

=back

=cut

use overload '""' => \&stringify;

sub stringify {
    my $self = shift;

    my @data;
    for my $f (qw(id changes log author author_name branch module)) {
        next unless $self->$f;

        if ( $f eq 'changes' ) {
            push @data, "changes=[" . join( ', ', @{ $self->$f } ) . "]";
        }
        else {
            push @data, "$f=" . $self->$f;
        }
    }

    return ref($self) . '(' . join( ', ', @data ) . ')';
}

1;
