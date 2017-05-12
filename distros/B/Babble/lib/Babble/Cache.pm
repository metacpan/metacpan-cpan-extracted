## Babble/Cache.pm
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

package Babble::Cache;

use strict;
use Carp;

=pod

=head1 NAME

Babble::Cache - Caching infrastructure for Babble

=head1 DESCRIPTION

This module implements the base Babble::Cache class, one that all
other cache modules are based upon. It provides all the methods every
module must support. Some of these will only I<carp> - these need to
be implemented in subclasses -, some won't have to be touched at all.

=head1 METHODS

Babble::Cache provides the following methods:

=head2 Constructor

=over 4

=item new (%params)

Creates a new Babble::Cache object. All parameters passed to it, will
be saved for future use. However, the following parameters are
recognised by Babble::Cache itself, and are used by the module itself:

=over 4

=item -cache_fn

The filename of the cache. This is required for proper operation,
provided one is using a cache that is loaded from file.

=back

=cut

sub new {
	my $type = shift;
	my %params = @_;
	my $self = {
		%params,

		cachedb => {},
	};

	bless $self, $type;
}

=pod

=back

=cut

=pod

=head2 Methods that need subclass implementation

The following methods need to be implemented in subclasses, as they
are not generic:

=over 4

=item load ()

This just carps, as loading is not supported by the base class.

=cut

sub load () {
	my $self = shift;

	carp "$self does not support load";
}

=pod

=item dump ()

This carps, as saving is not supported by the base class.

=cut

sub dump () {
	my $self = shift;

	carp "$self does not support dump";
}

=pod

=item get ($category, $id[, $key])

This carps, therefore must be implemented by subclasses.

=cut

sub get ($$;$) {
	my $self = shift;

	carp "$self does not support get";
}

=pod

=item set ($category, $id, $key, $value)

This carps, therefore must be implemented by subclasses.

=cut

sub set ($$$$) {
	my $self = shift;

	carp "$self does not support set";
}

=pod

=back

=cut

=pod

=head2 Generic methods

=over 4

=item frob ($category, $id, $data [, $keys])

Frobnicate stuff in the cache. This is a quite complex method, which
does a few interesting things. First, it looks up if an entry named
B<$id> exists under the B<$category> in the cache. If it does, all the
keys listed in the B<$keys> arrayref will be copied over from the
cache. If the cache does not have the key yet, it will be updated. If
the entry is not found in the cache, the keys listed in B<$keys> will
be stored in it. If B<$keys> is not defined, all keys of B<$data> will
be used.

=cut

sub frob ($$$;$) {
	my ($self, $cat, $id, $data, $keys) = @_;
	@$keys = keys %$data unless $keys;

	if ($self->get ($cat, $id)) {
		foreach my $key (@$keys) {
			if (defined $self->get ($cat, $id, $key)) {
				$$data->{$key} = $self->get ($cat, $id, $key);
			} else {
				$self->set ($cat, $id, $key, $$data->{$key});
			}
		}
	} else {
		foreach my $key (@$keys) {
			$self->set ($cat, $id, $key, $$data->{$key});
		}
	}
}

=pod

=item update ($category, $id, $data, $key)

Update the cache with the values of B<$data> when its B<$key> key is
defined. Otherwise, return the contents of the appropriate entry of
the cache.

=cut

sub update ($$$$) {
	my ($self, $cat, $id, $data, $key) = @_;

	if ($data->{$key}) {
		foreach my $dkey (keys %$data) {
			$self->set ($cat, $id, $dkey, $data->{$dkey});
		}
		return $data->{$key}
	} else {
		return $self->get ($cat, $id, $key);
	}
}

=pod

=item cache_fn ([$fn])

Get or set the cache file name.

=cut

sub cache_fn (;$) {
	my ($self, $new_fn) = @_;

	$self->{-cache_fn} = $new_fn if $new_fn;
	return $self->{-cache_fn};
}

=pod

=back

=head1 AUTHOR

Gergely Nagy, algernon@bonehunter.rulez.org

Bugs should be reported at L<http://bugs.bonehunter.rulez.org/babble>.

=head1 SEE ALSO

Babble, Babble::Cache::Class::Hash, Babble::Cache::Dumper,
Babble::Cache::Storable

=cut

1;

# arch-tag: 0398d7e3-5725-4de8-ae74-fc3a277fb97d
