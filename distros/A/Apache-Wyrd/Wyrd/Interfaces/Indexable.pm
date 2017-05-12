package Apache::Wyrd::Interfaces::Indexable;
use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);
our $VERSION = '0.98';
use Digest::SHA qw(sha1_hex);

=pod

=head1 NAME

Apache::Wyrd::Interfaces::Indexable - Pass metadata to Wyrd Index service

=head1 SYNOPSIS

NONE

=head1 DESCRIPTION

Indexable provides the minimum methods required by an object to be indexed using
the Apache::Wyrd::Services::Index object.  An indexable object can be inserted
into the index via the C<update_entry> method of the index.

=head1 HTML ATTRIBUTES

name

=over

=item keyword_weight

How much more, relative to an instance of the word in the body (_data),
a keyword is worth.  Defaults to 5.

=back

=head1 PERL METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (scalar) C<no_index> (void)

Returns true if the item should not be indexed.  Traditionally supplied via the
B<noindex> flag attribute of a Wyrd.

=cut

sub no_index {
	my ($self) = @_;
	return $self->_flags->noindex;
}

=pod

=item (scalar) C<force_update> (void)

Tells the index to ignore timestamp and digest arguments, and always update the
entry for this object even if there is no apparent change.  This may be helpful
in debugging index problems.

=cut

sub force_update {
	return 0;
}

=pod

=item (scalar) C<index_foo> (void)

Where B<foo> is at a minimum of name, timestamp, digest, data, title, keywords, and
description.  Any attributes specified in the B<attributes> option of the
Apache::Wyrd::Services::Index object will also need to be implemented in an
indexable object.  If the attribute is a map, it needs only to return a string
of tokens separated by whitespace, punctuation optional.

Because the assumption is that the indexable item will probably be a web page,
the path to the file from the server root is the traditional "name" of the item.
As such, when the results of a search are returned by the Index, the B<href>
attribute of a link to the page is created from the B<name> attribute.

Also in this tradition, the default map for searching uses the tokens provided
by C<index_data> as the basis for the index' C<word_search>.

=cut

sub index_digest {
	my ($self, $extra) = @_;
	#note that index_data also returns title and description.  Name is the index key,
	#so unneeded. Timestamp is only used as another indicator of file change by
	#Apache::Wyrd::Services::Index objects.
	return sha1_hex(
			  $self->index_data
			. $extra
	);
}

sub index_name {
	my ($self) = @_;
	return $self->dbl->self_path;
}

sub index_timestamp {
	my ($self) = @_;
	return $self->dbl->mtime;
}

sub index_data {
	my ($self) = @_;
	my $weight = ($self->{keyword_weight} || 5);
	my $keywords = $self->{'keywords'} . ' ';
	$keywords = $keywords x $weight;
	return $self->{'title'} . ' ' . $self->{'description'} . ' ' . $keywords . $self->{'_data'};
}

sub index_title {
	my ($self) = @_;
	return $self->{'title'};
}

sub index_keywords {
	my ($self) = @_;
	return $self->{'keywords'};
}

sub index_description {
	my ($self) = @_;
	return $self->{'description'};
}

=pod

=back

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=item Apache::Wyrd::Services::Index

=item Apache::Wyrd::Services::MySQLIndex

=item Apache::Wyrd::Site::Index

=item Apache::Wyrd::Site::MySQLIndex

Various index objects for site organization.

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;