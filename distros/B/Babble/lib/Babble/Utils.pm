## Babble/Utils.pm
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

package Babble::Utils;

use strict;

=pod

=head1 NAME

Babble::Utils - Non-essential Babble extensions and utility methods

=head1 SYNOPSIS

 use Babble::Utils;

 my $babble = Babble->new (
	-cache => {
		-cache_fn => 'cache.db',
		-cache_fields => ['id', 'date'],
	},
 );

 ...
 $babble->collect_feeds ();
 $babble->cache ()
 ...

=head1 DESCRIPTION

C<Babble::Utils> provides non-essential extensions to a Babble
object. All methods herein fall under the Babble namespace, and are
available with every Babble instance one makes, when this module is in
use.

=head1 METHODS

Babble::Utils provides the following methods:

=over 4

=item I<cache>(B<%params>)

This function does item caching. It goes over all the items in the
Babble object, and stores them in a cache, if they're not present. If
they are already present in there, the keys specified in the
I<-cache_fields> parameter will be used instead of the items
respective keys (ie, the items keys will be replaced from values from
the cache). This can be used to cache the approximate date of items
which didn't come with a date field by default.

This is just a wrapper around Babble::Cache, really.

=cut

sub Babble::cache (%) {
	my ($self, %params) = @_;
	my $cache_fields = $params{-cache_fields} ||
		$self->Cache->{-cache_fields};

	foreach my $item ($self->all) {
		$self->Cache->frob ('Items', $item->{id}, \$item,
				    $cache_fields);
	}
}

=pod

=back

=head1 AUTHOR

Gergely Nagy, algernon@bonehunter.rulez.org

Bugs should be reported at L<http://bugs.bonehunter.rulez.org/babble>.

=head1 SEE ALSO

Babble, Babble::Cache

=cut

1;

# arch-tag: 10f0e287-88a5-4c94-8e4d-439f9d7fcc40
