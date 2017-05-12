# vim: ts=4:sw=4:et:ai:sts=4
#
# KGB - an IRC bot helping collaboration
# Copyright © 2013 Damyan Ivanov
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
package App::KGB::Commit::Tag;

use strict;
use warnings;

our $VERSION = 1.28;

use base 'App::KGB::Commit';

=head1 NAME

App::KGB::Commit::Tag - a helper class for describing tags

=head1 SYNOPSIS

    my $c = App::KGB::Commit::Tag->new(
        {   id       => 4536,
            changes  => ["(M)/there"],
            log      => "fixed /there",
            author   => "My Self <mself@here.at>",
            branch   => "trunk",
            module   => "test",
            tag_name => 'release-1.0',
        }
    );

=head1 DESCRIPTION

B<App::KGB::Commit::Tag> is a special sub-class of L<App:KGB::Commit>,
used to describe simple (not annotated tags). It only add a new field,
B<tag_name>.

=head1 FIELDS

=over

=item B<tag_name>

The name of the tag, e.g. C<release-1.0>.

=back

=cut

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors( qw( tag_name ) );


1;
