
package CouchDB::Client::DB;

use strict;
use warnings;

our $VERSION = $CouchDB::Client::VERSION;

use Carp        qw(confess);
use URI::Escape qw(uri_escape_utf8);
use CouchDB::Client::Doc;
use CouchDB::Client::DesignDoc;

sub new {
	my $class = shift;
	my %opt = @_ == 1 ? %{$_[0]} : @_;

	$opt{name}   || confess "CouchDB database requires a name.";
	$opt{client} || confess "CouchDB database requires a client.";

	return bless \%opt, $class;
}

sub validName {
	shift;
	my $name = shift;
	return $name =~ m{^[a-z0-9_\$\(\)\+/-]+/$};
}

sub uriName {
	my $self = shift;
	my $sn = uri_escape_utf8($self->{name});
	return "$sn";
}

sub dbInfo {
	my $self = shift;
	my $res = $self->{client}->req('GET', $self->uriName);
	return $res->{json} if $res->{success};
	confess("Connection error: $res->{msg}");
}

sub create {
	my $self = shift;
	my $res = $self->{client}->req('PUT', $self->uriName);
	return $self if $res->{success} and $res->{json}->{ok};
	confess("Database '$self->{name}' exists: $res->{msg}") if $res->{status} == 409;
	confess("Connection error: $res->{msg}");
}

sub delete {
	my $self = shift;
	my $res = $self->{client}->req('DELETE', $self->uriName);
	return 1 if $res->{success} and $res->{json}->{ok};
	confess("Database '$self->{name}' not found: $res->{msg}") if $res->{status} == 404;
	confess("Connection error: $res->{msg}");
}

sub replicate {
	my $self = shift;
	my %args = @_;

	my $name = $self->{name};
	$name =~ s/\/$//;

	my $json;
	if (defined($args{source}) && defined($args{target})) {
		confess("Source and target can't be used at the sametime.");
	}
	elsif (defined($args{source})) {
		$json->{source} = $args{source};  # pull replication
		$json->{target} = $name;
	}
	elsif (defined($args{target})) {
		$json->{source} = $name;          # push replication
		$json->{target} = $args{target};
	}
	else {
		confess("Either source or target is required.");
	}

	my @flags = ('continuous');

	my ($M,$m,undef) = split(/\./,$self->{client}->serverInfo()->{version});
	if ($m > 10) {
		# This flag was added after v0.10
		push(@flags,'create_target');
	}

	foreach (@flags) {
		$json->{$_} = (defined($args{$_}) && $args{$_})?$self->{client}->{json}->true:$self->{client}->{json}->false;
	}

	my $res = $self->{client}->req('POST','_replicate',$json);
	confess("Error replicating database: $res->{msg}") if $res->{status} >= 300;

	return $res->{json};
}

sub newDoc {
	my $self = shift;
	my $id = shift;
	my $rev = shift;
	my $data = shift;
	my $att = shift;
	return CouchDB::Client::Doc->new(id => $id, rev => $rev, data => $data, attachments => $att, db => $self);
}

sub listDocIdRevs {
	my $self = shift;
	my %args = @_;
	my $qs = %args ? $self->argsToQuery(%args) : '';
	my $res = $self->{client}->req('GET', $self->uriName . '/_all_docs' . $qs);
	confess("Connection error: $res->{msg}") unless $res->{success};
	return [
		map {
			{
				id  => $_->{id},
				rev => ($_->{value}->{rev})? # The correct key may be version specific;
					$_->{value}->{rev}:      # v0.10.1 returns rev under this key,
					$_->{value}->{_rev}      # older versions may return it here.
			}
		} @{$res->{json}->{rows}}];
}

sub listDocs {
	my $self = shift;
	my %args = @_;
	return [ map { $self->newDoc($_->{id}, $_->{rev}) } @{$self->listDocIdRevs(%args)} ];
}

sub docExists {
	my $self = shift;
	my $id = shift;
	my $rev = shift;
	if ($rev) {
		return (grep { $_->{id} eq $id and $_->{rev} eq $rev } @{$self->listDocIdRevs}) ? 1 : 0;
	}
	else {
		return (grep { $_->{id} eq $id } @{$self->listDocIdRevs}) ? 1 : 0;
	}
}

sub newDesignDoc {
	my $self = shift;
	my $id = shift;
	my $rev = shift;
	my $data = shift;
	return CouchDB::Client::DesignDoc->new(id => $id, rev => $rev, data => $data, db => $self);
}

sub listDesignDocIdRevs {
	my $self = shift;
	my %args = @_;
	return [grep { $_->{id} =~ m{^_design/} } @{$self->listDocIdRevs(%args)}];
}

sub listDesignDocs {
	my $self = shift;
	my %args = @_;
	return [ map { $self->newDesignDoc($_->{id}, $_->{rev}) } @{$self->listDesignDocIdRevs(%args)} ];
}

sub designDocExists {
	my $self = shift;
	my $id = shift;
	my $rev = shift;
	$id = "_design/$id" unless $id =~ m{^_design/};
	if ($rev) {
		return (grep { $_->{id} eq $id and $_->{rev} eq $rev } @{$self->listDesignDocIdRevs}) ? 1 : 0;
	}
	else {
		return (grep { $_->{id} eq $id } @{$self->listDesignDocIdRevs}) ? 1 : 0;
	}
}

sub tempView {
	my $self = shift;
	my $view = shift;
	my $res = $self->{client}->req('POST', $self->uriName . '/_temp_view', $view);
	return $res->{json} if $res->{success};
	confess("Connection error: $res->{msg}");
}

sub bulkStore {
	my $self = shift;
	my $docs = shift;
	my $json = { docs => [map { $_->contentForSubmit } @$docs] };
	my $res = $self->{client}->req('POST', $self->uriName . '/_bulk_docs', $json);
	confess("Connection error: $res->{msg}") unless $res->{success};
	my $i = 0;

	# versions prior to 0.9 returned the results under the new_revs key,
	# newer versions just return an array.
	my $list = (ref($res->{json}) eq "ARRAY")?$res->{json}:$res->{json}->{new_revs};
	for my $ok (@{$list}) {
		my $doc = $docs->[$i];
		$doc->{id} = $ok->{id} unless $doc->{id};
		$doc->{rev} = $ok->{rev};
		$i++;
	}
	return $res->{json} if $res->{success};
}

sub bulkDelete {
	my $self = shift;
	my $docs = shift;
	my $json = { docs => [map { my $cnt = $_->contentForSubmit; $cnt->{_deleted} = $self->{client}->{json}->true; $cnt; } @$docs] };
	my $res = $self->{client}->req('POST', $self->uriName . '/_bulk_docs', $json);
	confess("Connection error: $res->{msg}") unless $res->{success};
	my $i = 0;

	# versions prior to 0.9 returned the results under the new_revs key,
	# newer versions just return an array.
	my $list = (ref($res->{json}) eq "ARRAY")?$res->{json}:$res->{json}->{new_revs};
	for my $ok (@{$list}) {
		my $doc = $docs->[$i];
		$doc->{deletion_stub_rev} = $ok->{rev};
		$doc->{rev} = '';
		$doc->data({});
		$doc->attachments({});
		$i++;
	}
	return $res->{json} if $res->{success};
}

# from docs
# key=keyvalue
# startkey=keyvalue
# startkey_docid=docid
# endkey=keyvalue
# count=max rows to return
# update=false
# descending=true
# skip=rows to skip
sub fixViewArgs {
	my $self = shift;
	my %args = @_;

	for my $k (keys %args) {
		if ($k eq 'key' or $k eq 'startkey' or $k eq 'endkey') {
			if (ref($args{$k}) eq 'ARRAY' or ref($args{$k}) eq 'HASH') {
				$args{$k} = $self->{client}->{json}->encode($args{$k});
			}
			else {
                                unless ($args{$k} =~ /^\d+(?:\.\d+)*$/s) {
                                        $args{$k} = '"' . $args{$k} . '"';
                                }
			}
		}
		elsif ($k eq 'descending') {
			if ($args{$k}) {
				$args{$k} = 'true';
			}
			else {
				delete $args{$k};
			}
		}
		elsif ($k eq 'update') {
			if ($args{$k}) {
				delete $args{$k};
			}
			else {
				$args{$k} = 'false';
			}
		}
	}
	return %args;
}

sub argsToQuery {
	my $self = shift;
	my %args = @_;
	%args = $self->fixViewArgs(%args);
	return  '?' .
			join '&',
			map { uri_escape_utf8($_) . '=' . uri_escape_utf8($args{$_}) }
			keys %args;
}

1;

=pod

=head1 NAME

CouchDB::Client::DB - CouchDB::Client database

=head1 SYNOPSIS

	use CouchDB::Client;
	my $c = CouchDB::Client->new(uri => 'https://dbserver:5984/');
	my $db = $c->newDB('my-stuff')->create;
	$db->dbInfo;
	my $doc = $db->newDoc('dahut.svg', undef, { foo => 'bar' })->create;
	my $dd = $db->newDesignDoc('dahut.svg', undef, $myViews)->create;
	#...
	$db->delete;

=head1 DESCRIPTION

This module represents databases in the CouchDB database.

We don't currently handle the various options available on listing all documents.

=head1 METHODS

=over 8

=item new

Constructor. Takes a hash or hashref of options, both of which are required:
C<name> being the name of the DB (do not escape it, that is done internally,
however the name isn't validated, you can use C<validName> for that) and C<client>
being a reference to the parent C<Couch::Client>. It is not expected that
you would use this constructor directly, but rather that would would go through
C<<< Couch::Client->newDB >>>.

=item validName $NAME

Returns true if the name is a valid CouchDB database name, false otherwise.

=item dbInfo

Returns metadata that CouchDB maintains about its databases as a Perl structure.
It will throw an exception if it can't connect. Typically it will look like:

	{
		db_name         => "dj",
		doc_count       => 5,
		doc_del_count   => 0,
		update_seq      => 13,
		compact_running => 0,
		disk_size       => 16845,
	}

=item create

Performs the actual creation of a database. Returns the object itself upon success.
Throws an exception if it already exists, or for connection problems.

=item delete

Deletes the database. Returns true on success. Throws an exception if
the DB can't be found, or for connection problems.

=item replicate %ARGS

Sets up replication between two databases.  Setting C<target> to a database url (either local or remote)
replicates this database into one specified by the url.  Conversely, setting C<source> to a database url
replicates that database into the current one.  In CouchDB terminology, C<target> and C<source>, respectively,
set up "push" and "pull" replication.

Either C<target> or C<source> is required; both can't be used at the same time.

By default, replication is a one time event.  New modifications to the origin database do not automatically
appear in the replicated database.  Setting C<continuous> to a true value will cause new changes in
the origin database to be reflected in the replicated one.

Note: Support for the C<create_target> flag (which was added after version 0.10) is included, but untested.

=item newDoc $ID?, $REV?, $DATA?, $ATTACHMENTS?

Returns a new C<CouchDB::Client::Doc> object, optionally with the given ID, revision, data,
and attachments. Note that this does not create the actual document, simply the object. For
constraints on these fields please look at C<<<CouchDB::Client::Doc->new>>>

=item listDocIdRevs %ARGS?

Returns an arrayref containing the ID and revision of all documents in this DB as hashrefs
with C<id> and C<rev> keys. Throws an exception if there's a problem. Takes an optional hash
of arguments matching those understood by CouchDB queries.

=item listDocs %ARGS?

The same as above, but returns an arrayref of C<CouchDB::Client::Doc> objects.
Takes an optional hash of arguments matching those understood by CouchDB queries.

=item docExists $ID, $REV?

Takes an ID and an optional revision and returns true if there is a document with that ID
in this DB, false otherwise. If the revision is provided, note that this will match only if
there is a document with the given ID B<and> its latest revision is the same as the given
one.

=item newDesignDoc $ID?, $REV?, $DATA?

Same as above, but instantiates design documents.

=item listDesignDocIdRevs %ARGS?

Same as above, but only matches design documents.

=item listDesignDocs %ARGS?

Same as above, but only matches design documents.

=item designDocExists $ID, $REV?

Same as above, but only matches design documents.

=item tempView $VIEW

Given a view (defined as a hash with the fields that CouchDB expects from the corresponding
JSON), will run it and return the CouchDB resultset. Throws an exception if there is a
connection error.

=item bulkStore \@DOCS

Takes an arrayref of Doc objects and stores them on the server (creating or updating them
depending on whether they exist or not). Returns the data structure that CouchDB returns
on success (which is of limited interest as this client already updates all documents so
that their ID and revisions are correct after this operation), and throws an exception
upon failure.

=item bulkDelete \@DOCS

Same as above but performs mass deletion of documents. Note that using bulkStore you could
also obtain the same effect by setting a C<_deleted> field to true on your objects but
that is not recommended as fields that begin with an underscore are reserved by CouchDB.

=item uriName

Returns the name of the database escaped.

=item fixViewArgs %ARGS

Takes a hash of view parameters expressed in a Perlish fashion (e.g. 1 for true or an arrayref
for multi-valued keys) and returns a hash with the same options turned into what CouchDB
understands.

=item argsToQuery %ARGS

Takes a hash of view parameters, runs them through C<fixViewArgs>, and returns a query
string (complete with leading '?') to pass on to CouchDB.

=back

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
