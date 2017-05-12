## Babble/Cache/Class/Hash.pm
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

package Babble::Cache::Class::Hash;

use strict;
use Carp;
use vars qw(@ISA);

use Babble::Cache;

@ISA = qw(Babble::Cache);

=pod

=head1 NAME

Babble::Cache::Class::Hash - In-memory cache storage for Babble::Cache

=head1 DESCRIPTION

This module implements the B<get> and B<set> methods for Babble::Cache
subclasses that store the entire cache in memory, in a hash.

=head1 METHODS

=over 4

=item get ($category, $id[, $key])

Retrieve the value of the B<$key> element in the B<$id> key in the
B<$category> category of the cache.

=cut

sub get ($$;$) {
	my ($self, $cat, $id, $key) = @_;
	if ($key) {
		return $self->{cachedb}->{$cat}->{$id}->{$key};
	} else {
		return $self->{cachedb}->{$cat}->{$id};
	}
}

=pod

=item set ($category, $id, $key, $value)

Set the value of the B<$key> element, in the B<$id> key in the
B<$category> category of the cache, to B<$value>.

=cut

sub set ($$$$) {
	my ($self, $cat, $id, $key, $value) = @_;
	$self->{cachedb}->{$cat}->{$id}->{$key} = $value;
}

=pod

=back

=head1 AUTHOR

Gergely Nagy, algernon@bonehunter.rulez.org

Bugs should be reported at L<http://bugs.bonehunter.rulez.org/babble>.

=head1 SEE ALSO

Babble::Cache

=cut

1;

# arch-tag: fba24dda-b267-4638-b63a-99104097901e
