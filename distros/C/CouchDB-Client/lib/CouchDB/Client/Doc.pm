
package CouchDB::Client::Doc;

use strict;
use warnings;

our $VERSION = $CouchDB::Client::VERSION;

use HTTP::Request   qw();
use URI::Escape     qw(uri_escape_utf8);
use MIME::Base64    qw(encode_base64);
use Carp            qw(confess);

sub new {
	my $class = shift;
	my %opt = @_ == 1 ? %{$_[0]} : @_;

	confess "Doc needs a database" unless $opt{db};

	my %self = (
		id          => $opt{id} || '',
		rev         => $opt{rev} || '',
		attachments => $opt{attachments} || {},
		data        => $opt{data} || {},
		db          => $opt{db},
	);
	return bless \%self, $class;
}

sub id { return $_[0]->{id}; }
sub rev { return $_[0]->{rev}; }

sub data {
	my $self = shift;
	if (@_) {
		my $data = shift;
		$self->{attachments} = delete($data->{_attachments}) || {};
		$self->{data} = $data;
	}
	else {
		return $self->{data};
	}
}
sub attachments { @_ == 2 ? $_[0]->{attachments} = $_[1] : $_[0]->{attachments}; }

sub uriName {
	my $self = shift;
	return undef unless $self->{id};
	return $self->{db}->uriName . '/' . uri_escape_utf8($self->{id});
}

sub create {
	my $self = shift;

	confess("Object already had a revision") if $self->{rev};

	my $content = $self->contentForSubmit;
	my $res;
	if ($self->{id}) {
		$res = $self->{db}->{client}->req('PUT', $self->uriName, $content);
	}
	else {
		$res = $self->{db}->{client}->req('POST', $self->{db}->uriName, $content);
	}
	confess("Storage error: $res->{msg}") unless $res->{success};
	$self->{rev} = $res->{json}->{rev};
	$self->{id} = $res->{json}->{id} unless $self->{id};
	return $self;
}

sub contentForSubmit {
	my $self = shift;
	my $content = $self->{data};
	$content->{_id} = $self->{id} if $self->{id};
	$content->{_rev} = $self->{rev} if $self->{rev};
	$content->{_attachments} = $self->{attachments} if $self->{attachments} and keys %{$self->{attachments}};
	return $content;
}

sub retrieve {
	my $self = shift;

	my $res = $self->{db}->{client}->req('GET', $self->uriName);
	confess("Object not found: $res->{msg}") if $res->{status} == 404;
	confess("Connection error: $res->{msg}") unless $res->{success};
	my $data = $res->{json};
	my %private;
	my @keys = keys %$data; # need to two-step this due to delete()
	for my $k (@keys) {
		if ($k =~ m/^_(.+)/) {
			$private{$1} = delete $data->{$k};
		}
	}
	$self->{data} = $data;
	$self->{id} = $private{id};
	$self->{rev} = $private{rev};
	$self->{attachments} = $private{attachments} if exists $private{attachments};
	return $self;
}

sub retrieveFromRev {
	my $self = shift;
	my $rev = shift;

	my $res = $self->{db}->{client}->req('GET', $self->uriName . '?rev=' . $rev);
	confess("Object not found: $res->{msg}") if $res->{status} == 404;
	confess("Connection error: $res->{msg}") unless $res->{success};
	my $data = $res->{json};
	my %private;
	my @keys = keys %$data; # need to two-step this due to delete()
	for my $k (@keys) {
		if ($k =~ m/^_(.+)/) {
			$private{$1} = delete $data->{$k};
		}
	}
	return ref($self)->new({
		id          => $self->id,
		rev         => $rev,
		attachments => $private{attachments},
		data        => $data,
		db          => $self->{db},
	});
}

sub revisionsInfo {
	my $self = shift;

	my $res = $self->{db}->{client}->req('GET', $self->uriName . '?revs_info=true');
	confess("Object not found: $res->{msg}") if $res->{status} == 404;
	confess("Connection error: $res->{msg}") unless $res->{success};
	return $res->{json}->{_revs_info};
}

sub update {
	my $self = shift;

	confess("Object hasn't been retrieved") unless $self->{id} and $self->{rev};
	my $content = $self->contentForSubmit;
	my $res = $self->{db}->{client}->req('PUT', $self->uriName, $content);
	confess("Storage error: $res->{msg}") unless $res->{success};
	$self->{rev} = $res->{json}->{rev};
	return $self;
}

sub delete {
	my $self = shift;

	confess("Object hasn't been retrieved") unless $self->{id} and $self->{rev};
	my $res = $self->{db}->{client}->req('DELETE', $self->uriName . "?rev=" . $self->rev);
	confess("Object not found: $res->{msg}") if $res->{status} == 404;
	confess("Connection error: $res->{msg}") unless $res->{success};
	$self->{deletion_stub_rev} = $res->{json}->{rev};
	$self->{rev} = '';
	$self->{data} = {};
	$self->{attachments} = {};
	return $self;
}

sub fetchAttachment {
	my $self = shift;
	my $attName = shift;

	confess("No such attachment: '$attName'") unless exists $self->{attachments}->{$attName};
	my $res = $self->{db}->{client}->{ua}->request(
		HTTP::Request->new('GET', $self->{db}->{client}->uriForPath($self->uriName . '/' . uri_escape_utf8($attName)))
	);
	return $res->content if $res->is_success;
	confess("Object not found: $res->{msg}");
}

sub addAttachment {
	my $self = shift;
	my $name = shift;
	my $ctype = shift;
	my $data = shift;

	$self->{attachments}->{$name} = {
		content_type    => $ctype,
		data            => $self->toBase64($data),
	};
	return $self;
}

sub deleteAttachment {
	my $self = shift;
	my $attName = shift;

	confess("No such attachment: '$attName'") unless exists $self->{attachments}->{$attName};
	delete $self->{attachments}->{$attName};
	return $self;
}

sub toBase64 {
	my $self = shift;
	my $data = shift;

	my $ret = encode_base64 $data;
	$ret =~ s/\n//g;
	return $ret;
}

1;

=pod

=head1 NAME

CouchDB::Client::Doc - CouchDB::Client document

=head1 SYNOPSIS

	$doc->data->{foo} = 'new bar';
	$doc->addAttachment('file.xml', 'application/xml', '<foo/>);
	$doc->update;
	$doc->delete;

=head1 DESCRIPTION

This module represents documents in the CouchDB database.

We don't yet deal with a number of options such as retrieving revisions and
revision status.

=head1 METHODS

=over 8

=item new

Constructor. Takes a hash or hashref of options: C<db> which is the parent
C<CouchDB::Client::DB> object and is required; the document's C<id> and C<rev>
if known; a hashref of C<data> being the content; and a hashref of C<attachements>
if present.

The C<id> field must be a valid document name (CouchDB accepts anything, but
things that are not URI safe have not been tested yet).

The C<rev> field must be a valid CouchDB revision, it is recommended that you
only touch it if you know what you're doing.

The C<data> field is a normal Perl hashref that can have nested content. Its
keys must not contain fields that being with an underscore (_) as those are
reserved for CouchDB.

The C<attachments> field must be structured in the manner that CouchDB expects.
It is a hashref with attachment names as its keys and hashrefs as values. The
latter have C<content_type> and C<data> fields which are the MIME media type
of the content, and the data in single-line Base64. It is recommended that you
manipulate this through the helpers instead.

It is not recommended that this constructor be used directly, but rather that
C<<<CouchDB::Client::DB->newDoc>>> be used instead.

=item id

Read-only accessor for the ID.

=item rev

Read-only accessor for the revision.

=item data

Read-write accessor for the content. See above for the constraints on this hasref.
Note that this only changes the data on the client side, you have to create/update
the object for it to be stored.

=item attachments

Read-write accessor for the attachments. See above for the constraints on this hasref.
Note that this only changes the attachments on the client side, you have to create/update
the object for it to be stored.

=item uriName

Returns the path part for this object (if it has an ID, otherwise undef).

=item create

Causes the document to be created in the DB. It will throw an exception if the object already
has a revision (since that would indicate that it's already in the DB) or if the actual
storage operation fails.

If the object has an ID it will PUT it to the URI, otherwise it will POST it and set its ID based
on the result. It returns itself, with the C<rev> field updated.

=item contentForSubmit

A helper that returns a data structure matching that of the JSON that will be submitted as part
of a create/update operation.

=item retrieve

Loads the document from the database, initialising all its fields in the process. Will
throw an exception if the document cannot be found, or for connection issues. It returns
the object.

Note that the attachments field if defined will contain stubs and not the full content.
Retrieving the actual data is done using C<fetchAttachment>.

=item update

Same as C<create> but only operates on documents already in the DB.

=item delete

Deletes the document and resets the object (updating its C<rev>). Returns the object (which
is still perfectly usable). Throws an exception if the document isn't found, or for
connection issues.

=item fetchAttachment $NAME

Fetches the attachment with the given name and returns its content. Throws an exception if
the attachment cannot be retrieved, or if the object had no knowledge of such an attachment.

=item addAttachment $NAME, $CONTENT_TYPE, $DATA

Adds an attachment to the document with a given name, MIME media type, and data. The
data is the original, not the Base64 version which is handled internally. The object
is returned.

=item deleteAttachment $NAME

Deletes an attachment from the document.  Note that this only removes the attachment
on the client side, you have to update the object for it to be removed from the DB.

Throws an exception if the document does not contain an attachment by that name.

=item toBase64 $DATA

A simple helper that returns data in Base64 of a form acceptable to CouchDB (on a single
line).

=item retrieveFromRev $REV

Fetches a specific revision of a document, and returns it I<as a new Doc object>. This is
to avoid destroying your own Doc object. Throws exceptions if it can't connect or find the
document.

=item revisionsInfo

Returns an arrayref or hashresf indicating the C<rev> of previous revisions and their
C<status> (being C<disk>, C<missing>, C<deleted>). Throws exceptions if it can't connect
or find the document.

=back

=head1 TODO

Handling of attachments could be improved by not forcing the data into memory at all
times. Also, an option to turn the attachments into stubs after they have been saved
would be good.

=head1 AUTHOR

Robin Berjon, <robin @t berjon d.t com>
Maverick Edwards, <maverick @t smurfbane d.t org> (current maintainer)

=head1 BUGS

Please report any bugs or feature requests to bug-couchdb-client at rt.cpan.org, or through the
web interface at http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CouchDB-Client.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Robin Berjon, all rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as
Perl itself, either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may
have available.

=cut
