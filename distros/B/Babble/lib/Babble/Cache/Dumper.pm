## Babble/Cache/Dumper.pm
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

package Babble::Cache::Dumper;

use strict;
use Carp;
use Babble::Cache::Class::Hash;
use Data::Dumper;
use vars qw(@ISA);

@ISA = qw(Babble::Cache::Class::Hash);

=pod

=head1 NAME

Babble::Cache::Dumper - Data::Dumper based cache for Babble

=head1 DESCRIPTION

This module implements a cache for B<Babble> that uses B<Data::Dumper>
to store and retrieve the cache. The cache itself is stored in memory
in a hash (thus, this class is a subclass of
B<Babble::Cache::Class::Hash>).

The main advantage is human readability, but the stored cache is slow
to load and save.

=head1 METHODS

=over 4

=item load ()

Load the cache stored in B<Data::Dumper> format from the file
specified during object creation.

=cut

sub load () {
	my $self = shift;

	return 1 unless ($self->{-cache_fn} && -e $self->{-cache_fn});

	$self->{cachedb} = do $self->{-cache_fn};
	if ($@) {
		carp $@;
		return undef;
	}
	return 1;
}

=pod

=item dump ()

Save the cache in B<Data::Dumper> format to the file specified during
object creation.

=cut

sub dump () {
	my $self = shift;

	return unless $self->{cache_fn};

	$Data::Dumper::Terse = 1;

	unless (open (OUTF, '>' . $self->{-cache_fn})) {
		carp 'Error dumping cache to `' . $self->{-cache_fn} .
			'\': ' . $1;
		return;
	}
	print OUTF "# Automatically generated file. Edit carefully!\n";
	print OUTF Dumper ($self->{cachedb}) . ";\n";
	close OUTF;
}

=pod

=back

=head1 AUTHOR

Gergely Nagy, algernon@bonehunter.rulez.org

Bugs should be reported at L<http://bugs.bonehunter.rulez.org/babble>.

=head1 SEE ALSO

Data::Dumper, Babble, Babble::Cache, Babble::Cache::Class::Hash

=cut

1;

# arch-tag: b974429f-b379-4277-9126-2c29cc3dde22
