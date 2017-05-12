## Babble/Document/Collection.pm
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

package Babble::Document::Collection;

use strict;
use Babble::Document;

=pod

=head1 NAME

Babble::Document::Collection - Babble document collector class

=head1 DESCRIPTION

Babble::Document::Collection is a meta-class. One, that's sole purpose
is to collect Babble::Document objects, and group them together with a
little meta-info about them.

=head1 PROPERTIES

=over 4

=item author

The author of this collection

=item subject

The subject of the collection.

=item title

The title of the collection.

=item id

A unique ID for the collection, usually a hyperlink to the source
homepage.

=item link

A link to the source of this collection (for example, to an RSS feed).

=item date

The creation date of this version of the collection.

=item content

A brief description of the collection

=item name

The name of the collection. Usually used for subscription lists in the
templates. This does not come from the feed, as the others. It must be
specified at object creation time. Defaults to I<author>'s value if
undefined, or I<title>'s, if I<author> is undefined too.

=item image

The image associated with the collection. It is stored as a HASH
reference, containing the following keys:

=over 4

=item url

The URL to the image. (Mandatory)

=item title

Title of the image (to be used in ALT attributes or the like)

=item link

An image link - where the image points to. (Mandatory)

=item width

Width of the image.

=item height

Height of the image.

=back

=back

=head1 METHODS

=over 4

=item new()

Creates a new, empty Babble::Document::Collection object. All the
properties mentioned above are recognised as paramaters.

To add documents to the collection, simply push them to
C<@{$collection-E<gt>{documents}}>.

=cut

sub new {
	my ($type, %params) = @_;

	my $self = bless {
		author => $params{author},
		subject => $params{subject},
		title => $params{title},
		id => $params{id},
		link => $params{link},
		date => $params{date},
		content => $params{content},
		name => $params{name} || $params{author} || $params{title},
		image => $params{image} || {},

		documents => []
	}, $type;

	return $self;
}

=pod

=item search($filters[, $params])

Given a list of filters (see Babble::Document::search for a
specification of filters) in an arrayref, returns all the documents
that match the specified criteria. If no matches are found, returns an
empty array.

=cut

sub search ($;$) {
	my ($self, $filters, $params) = @_;
	my @results;

	foreach my $doc (@{$self->{documents}}) {
		my @subres = $doc->search ($filters);
		push (@results, @subres) if @subres;
	}

	return @results;
}

=pod

=item all()

Return all entries (the lowest level entries) as an array.

=cut

sub all () {
	my ($self) = @_;
	my @all;

	foreach my $doc (@{$self->{documents}}) {
		push (@all, $doc->all ());
	}

	return @all;
}


=pod

=item sort($params)

Sort all the elements in an aggregation by date, and return the sorted
array of items.

=cut

sub sort (;$) {
	my ($self, $params) = @_;

	my @sorted = sort { $b->date_iso cmp $a->date_iso }
		$self->all ();

	return @sorted;
}

=pod

=back

=head1 AUTHOR

Gergely Nagy, algernon@bonehunter.rulez.org

Bugs should be reported at L<http://bugs.bonehunter.rulez.org/babble>.

=head1 SEE ALSO

Babble, Babble::Document

=cut

1;

# arch-tag: 5ac2ff9a-3c8b-4fa7-9b40-33b7e5270eff
