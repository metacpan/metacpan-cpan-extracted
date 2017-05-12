## Babble/Cache/Storable.pm
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

package Babble::Cache::Storable;

use strict;
use Storable;

use Babble::Cache::Class::Hash;
use vars qw(@ISA);

@ISA = qw(Babble::Cache::Class::Hash);

=pod

=head1 NAME

Babble::Cache::Storable - Storable-based cache for Babble

=head1 DESCRIPTION

This module implements a cache for B<Babble> that uses B<Storable> to
store and retrieve the cache. The cache itself is stored in memory in
a hash (thus, this class is a subclass of
B<Babble::Cache::Class::Hash>).

The main advantage is speed, but the stored cache is not human
readable.

=head1 METHODS

=over 4

=item load ()

Load the cache stored in B<Storable> format from the file
specified during object creation.

=cut

sub load () {
	my $self = shift;

	return 1 unless ($self->{-cache_fn} && -e $self->{-cache_fn});
	$self->{cachedb} = Storable::retrieve $self->{-cache_fn};
}

=pod

=item dump ()

Save the cache in B<Storable> format to the file specified during
object creation.

=cut

sub dump () {
	my $self = shift;

	return unless $self->{-cache_fn};

	Storable::store $self->{cachedb}, $self->{-cache_fn};
}

=pod

=back

=head1 AUTHOR

Gergely Nagy, algernon@bonehunter.rulez.org

Bugs should be reported at L<http://bugs.bonehunter.rulez.org/babble>.

=head1 SEE ALSO

Storable, Babble, Babble::Cache, Babble::Cache::Class::Hash

=cut

1;

# arch-tag: bbb35e90-13d8-480c-b700-f6a5603e2680
