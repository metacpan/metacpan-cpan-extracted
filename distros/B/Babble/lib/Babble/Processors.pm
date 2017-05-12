## Babble/Processors.pm
## Copyright (C) 2004 Gergely Nagy <algernon@bonehunter.rulez.org>
##
## This file is part of Babble.
##
## Babble is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; version 2 dated June, 1991.
##
## Babble is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
## FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
## for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

package Babble::Processors;

use strict;
use Date::Manip;

=pod

=head1 NAME

Babble::Processors - Processor collection for Babble

=head1 DESCRIPTION

C<Babble::Processors> is a collection of processors for Babble. All of
the processors herein are run by default, and cannot be turned off,
unless one fiddles with a Babble objects internals.

However, the processors are documented here, so that if one does turn
them off, may he be able to re-use any of these.

=head1 METHODS

=over 4

=item master()

Adds a B<master> key to the I<item>: the B<id> key of the
I<channel>.

This is useful when one wants to link back to the original channel
from each and every item.

=cut

sub master {
	my ($item, $channel) = @_;

	$$item->{master} = $$channel->{id};
}

=pod

=item image()

Adds an B<image> key to the I<item>: the feed image of the I<channel>.

=cut

sub image {
	my ($item, $channel) = @_;

	$$item->{image} = $$channel->{image};
}

=pod

=item creator()

Sets the author of the item to the I<source>'s B<-id> field, if the
item does not have an author yet.

=cut

sub creator {
	my ($item, undef, $source) = @_;

	$$item->{author} = $$source->{-id} unless $$item->{author};
}

=pod

=pod

=item default()

This processor runs all of the others, in the specified order, after
each other.

=cut

sub default {
	master (@_);
	creator (@_);
	image (@_);
}

=pod

=back

=head1 AUTHOR

Gergely Nagy, algernon@bonehunter.rulez.org

Bugs should be reported at L<http://bugs.bonehunter.rulez.org/babble>.

=head1 SEE ALSO

Babble

=cut

1;

# arch-tag: 83496c69-815a-4f12-8465-a569c67d5609
