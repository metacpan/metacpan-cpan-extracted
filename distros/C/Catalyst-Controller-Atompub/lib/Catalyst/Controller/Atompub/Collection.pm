package Catalyst::Controller::Atompub::Collection;

use strict;
use warnings;

use Atompub::DateTime qw(datetime);
use Atompub::MediaType qw(media_type);
use Atompub::Util qw(is_acceptable_media_type is_allowed_category);
use Catalyst::Utils;
use English qw(-no_match_vars);
use File::Slurp;
use HTTP::Status;
use NEXT;
use POSIX qw(strftime);
use Text::CSV;
use Time::HiRes qw(gettimeofday);
use URI;
use URI::Escape;
use XML::Atom::Entry;

use base qw(Catalyst::Controller::Atompub::Base);

__PACKAGE__->mk_accessors(qw(edited));

my %COLLECTION_METHOD = (
    GET    => '_list',
    HEAD   => '_list',
    POST   => '_create',
);
my %RESOURCE_METHOD = (
    GET    => '_read',
    HEAD   => '_read',
    POST   => '_create',
    PUT    => '_update',
    DELETE => '_delete',
);

sub auto :Private {
    my($self, $c) = @_;
    $self->{resources} = [];
    1;
}

# access to the collection
sub default :Private {
    my($self, $c) = @_;
    my $method = $COLLECTION_METHOD{ uc $c->req->method };
    unless ($method) {
        $c->res->headers->header(Allow => 'GET, HEAD, POST');
        return $self->error($c, RC_METHOD_NOT_ALLOWED);
    }
    $self->$method($c);
}

sub edit_uri :LocalRegex('^([^-?&#][^?&#]*)') {
    my($self, $c) = @_;
    my $method = $RESOURCE_METHOD{ uc $c->req->method };
    unless ($method) {
        $c->res->headers->header(Allow => 'GET, HEAD, PUT, DELETE');
        return $self->error($c, RC_METHOD_NOT_ALLOWED);
    }
    $self->$method($c);
}

sub resource {
    my($self, $rc) = @_;
    if ($rc) {
        push @{ $self->{resources} }, $rc;
    }
    else {
        [ grep { $_ } @{ $self->{resources} } ]->[0];
    }
}

*rc = \&resource;

my @ACCESSORS = (
    [ 'collection_resource', 'feed',  'is_collection' ],
    [ 'entry_resource',      'entry', 'is_entry'      ],
    [ 'media_resource',       undef,  'is_media'      ],
    [ 'media_link_entry',    'entry', 'is_entry'      ],
);

for my $accessor (@ACCESSORS) {
    no strict 'refs'; ## no critic
    my($method, $type, $is) = @$accessor;
    *{$method} = sub {
        my($self, $rc) = @_;
        if ($rc) {
            $rc->type(media_type($type)) if $type;
            push @{ $self->{resources} }, $rc;
        }
        else {
            return [
                grep { !$_->type || $_->$is }
                grep { $_ }
                    @{ $self->{resources} }
            ]->[0];
        }
    };
}

sub make_collection_uri {
    my($self, $c) = @_;
    my $class = ref $self || $self;
    $c->req->base.$class->action_namespace($c);
}

sub make_edit_uri {
    my($self, $c, @args) = @_;

    my $collection_uri = $self->info->get($c, $self)->href;

    my $basename;
    if (my $slug = $c->req->slug) {
        my $slug = uri_unescape $slug;
        $slug =~ s/^\s+//; $slug =~ s/\s+$//; $slug =~ s/[.\s]+/_/;
        $basename = uri_escape lc $slug;
    }
    else {
        my($sec, $usec) = gettimeofday;
        $basename
            = join '-', strftime('%Y%m%d-%H%M%S', localtime($sec)), sprintf('%06d', $usec);
    }

    my @media_types = map { media_type($_) } ('entry', @args);

    my @uris;
    for my $media_type (@media_types) {
        my $ext  = $media_type->extension || 'bin';
        my $name = join '.', $basename, $ext;
        push @uris, join '/', $collection_uri, $name;
    }

    wantarray ? @uris : $uris[0];
}

for my $operation (qw(list create read update delete)) {
    no strict 'refs'; ## no critic
    *{"do_$operation"} = sub {
        my($self, $c, @args) = @_;
        return $self->error($c, RC_METHOD_NOT_ALLOWED)
            unless UNIVERSAL::isa($self->{handler}{$operation}, 'CODE');
        $self->{handler}{$operation}($self, $c, @args);
    };
}

sub _list {
    my($self, $c) = @_;

    my $feed = XML::Atom::Feed->new;
    my $title = $self->info->get($c, $self)->title;
    $feed->title($title);

    if ($self->{author}) {
        my $author = XML::Atom::Person->new;
        $self->{author}{$_} and $author->$_($self->{author}{$_})
            for (qw(name email uri));
        $feed->author($author);
    }

    $feed->updated(datetime->w3c);

    my $uri = $self->make_collection_uri($c);
    $feed->id($uri);
    $feed->self_link($uri);

    $self->collection_resource( Catalyst::Controller::Atompub::Collection::Resource->new({
        uri => $uri,
        body => $feed,
    }) );

    $self->do_list($c)
        or return $self->error($c, RC_INTERNAL_SERVER_ERROR, "Cannot list collection: $uri");

    return unless $self->collection_resource;

    $c->res->content_type($self->collection_resource->type) unless $c->res->content_type;
    $c->res->body($self->collection_resource->serialize) unless $c->res->body;
}

sub _create {
    my($self, $c) = @_;

    my $media_type
        = media_type($c->req->content_type) || media_type('application/octet-stream');

    my $coll = $self->info->get($c, $self);

    return $self->error($c, RC_UNSUPPORTED_MEDIA_TYPE, "Unsupported media type: $media_type")
        unless is_acceptable_media_type($coll, $media_type);

    $self->edited(datetime);

    if ($media_type->is_a('entry')) {
        my $entry = $self->_fixup_entry($c) or return $self->error($c);

        $self->entry_resource( Catalyst::Controller::Atompub::Collection::Resource->new({
            body => $entry,
        }) );

        my ($uri) = $self->make_edit_uri($c) or return $self->error($c);
        $entry = $self->_assign_uri_for_entry($c, $entry, $uri) or return $self->error($c);

        $self->entry_resource->uri($uri);
    }
    else {
        my $entry = $self->_create_media_link_entry($c) or return $self->error($c);
        my $media = read_file($c->req->body, binmode => ':raw');

        $self->media_link_entry( Catalyst::Controller::Atompub::Collection::Resource->new({
            body => $entry,
        }) );

        $self->media_resource( Catalyst::Controller::Atompub::Collection::Resource->new({
            body => $media,
            type => $media_type,
        }) );

        my($entry_uri, $media_uri) = $self->make_edit_uri($c, $media_type) or return $self->error($c);
        $entry = $self->_assign_uri_for_entry($c, $entry, $entry_uri, $media_uri) or return $self->error($c);

        $self->media_link_entry->uri($entry_uri);
        $self->media_resource->uri($media_uri);

        return $self->error($c, RC_BAD_REQUEST, 'No body') unless $c->req->body;
    }

    $self->do_create($c)
        or return $self->error($c, RC_INTERNAL_SERVER_ERROR,
                               'Cannot create new resource: '.$self->make_collection_uri($c));

    $c->res->status(RC_CREATED);

    if (!defined $c->res->etag || !$c->res->last_modified) {
        my %ret = $self->find_version($c, $self->entry_resource->uri);
        $c->res->etag($ret{etag})
            if !defined $c->res->etag && defined $ret{etag};
        $c->res->last_modified($ret{last_modified})
            if !$c->res->last_modified && $ret{last_modified};
    }

    return unless $self->entry_resource;

    $c->res->redirect($self->entry_resource->uri, RC_CREATED) unless $c->res->redirect;
    $c->res->content_type($self->entry_resource->type) unless $c->res->content_type;
    $c->res->body($self->entry_resource->serialize) unless $c->res->body;
}

sub _read {
    my($self, $c) = @_;

    return $c->res->status(RC_NOT_MODIFIED) unless $self->_is_modified($c);

    my $uri = $c->req->uri->no_query;

    my @accepts = $self->info->get($c, $self)->accepts;
    my $media_type
        = @accepts == 0                        ? media_type('entry')
        : @accepts == 1 && $accepts[0] !~ /\*/ ? media_type($accepts[0])
        :                                        undef;

    $self->rc( Catalyst::Controller::Atompub::Collection::Resource->new({
        uri => $uri,
        type => $media_type,
    }) );

    $self->do_read($c)
        or return $self->error( $c, RC_INTERNAL_SERVER_ERROR, "Cannot read resource: $uri" );

    if (!defined $c->res->etag || !$c->res->last_modified) {
        my %ret = $self->find_version($c, $uri);
        $c->res->etag($ret{etag})
            if !defined $c->res->etag && defined $ret{etag};
        $c->res->last_modified($ret{last_modified})
            if !$c->res->last_modified && $ret{last_modified};
    }

    return unless $self->rc;

    $c->res->content_type($self->rc->type) unless $c->res->content_type;

    return if $c->req->method eq 'HEAD';

    $c->res->body($self->rc->serialize) unless $c->res->body;
}

sub _update {
    my($self, $c) = @_;

    return $self->error($c, RC_PRECONDITION_FAILED, 'Missing If-match header')
        if $self->_is_modified($c);

    my $media_type
        = media_type($c->req->content_type) || media_type('application/octet-stream');

    my $coll = $self->info->get($c, $self);

    return $self->error($c, RC_UNSUPPORTED_MEDIA_TYPE, "Unsupported media type: $media_type")
        if !is_acceptable_media_type($coll, $media_type) && !$media_type->is_a('entry');

    $self->edited(datetime);

    my $uri = $c->req->uri->no_query;

    my $body;
    if ($media_type->is_a('entry')) {
        $media_type = media_type('entry');
        $body = $self->_fixup_entry($c) or return $self->error($c);
        $body = $self->_assign_uri_for_entry($c, $body, $uri) or return $self->error($c);
    }
    else {
        return $self->error($c, RC_BAD_REQUEST, 'No body') unless $c->req->body;
        $body = read_file($c->req->body, binmode => ':raw');
    }

    $self->rc( Catalyst::Controller::Atompub::Collection::Resource->new({
        uri => $uri,
        body => $body,
        type => $media_type,
    }) );

    $self->do_update($c)
        or return $self->error($c, RC_INTERNAL_SERVER_ERROR, "Cannot update resource: $uri");

    if (!defined $c->res->etag || !$c->res->last_modified) {
        my %ret = $self->find_version($c, $uri);
        $c->res->etag($ret{etag})
            if !defined $c->res->etag && defined $ret{etag};
        $c->res->last_modified($ret{last_modified})
            if !$c->res->last_modified && $ret{last_modified};
    }

    return unless $self->rc;
    return if $c->res->status eq RC_NO_CONTENT;

    $c->res->content_type($self->rc->type) unless $c->res->content_type;
    $c->res->body($self->rc->serialize) unless $c->res->body;
}

sub _delete {
    my($self, $c) = @_;

# If-Match nor If-Unmodified-Since header is not required on DELETE
#    return $self->error($c, RC_PRECONDITION_FAILED)
#       if $self->_is_modified($c);

    my $uri = $c->req->uri->no_query;

    $self->rc( Catalyst::Controller::Atompub::Collection::Resource->new({
        uri => $uri,
    }) );

    $c->res->status(RC_NO_CONTENT);

    $self->do_delete($c)
        or return $self->error($c, RC_INTERNAL_SERVER_ERROR, "Cannot delete resource: $uri");
}

sub find_version {}

sub _is_modified {
    my($self, $c) = @_;

    my $method = $c->req->method;

    my %ret = $self->find_version($c, $c->req->uri->no_query);

    my $etag          = $ret{etag};
    my $last_modified = $ret{last_modified};

    return $method eq 'GET' ? 1 : 0
        if !defined $etag && !$last_modified; # if don't check version

    my $match = $method eq 'GET' ? $c->req->if_none_match : $c->req->if_match;
    $match =~ s/^['"](.+)['"]$/$1/ if $match; #" unquote

    return 1 if defined $etag && (!defined $match || $etag ne $match);

    my $since = $method eq 'GET' ? $c->req->if_modified_since : $c->req->if_unmodified_since;

    return 1 if $last_modified && (!$since || datetime($last_modified) != datetime($since));

    return 0;
}

sub _fixup_entry {
    my($self, $c) = @_;

    my $entry;
    eval {
        $entry = XML::Atom::Entry->new($c->req->body)
            or die XML::Atom::Entry->errstr;
    };
    if ($EVAL_ERROR) {
        return $self->error($c, RC_BAD_REQUEST, $EVAL_ERROR);
    }

    return $self->error($c, RC_BAD_REQUEST, 'Forbidden category')
        unless is_allowed_category($self->info->get($c, $self), $entry->category);

    $entry->edited($self->edited->w3c);
    $entry->updated($self->edited->w3c) unless $entry->updated;

    if (!$entry->author) {
        my $author = XML::Atom::Person->new;
        $author->name('');
        $entry->author($author);
    }
    elsif (!$entry->author->name) {
        $entry->author->name('');
    }

    $entry->title('') unless defined $entry->title;

    $entry;
}

sub _assign_uri_for_entry {
    my($self, $c, $entry, $entry_uri, $media_uri) = @_;
    $entry->id(_make_id($entry_uri)) unless $entry->id;
    $entry->edit_link($entry_uri);
    if ($media_uri) {
        $entry->edit_media_link($media_uri);
        unless ($entry->content) {
            my $content = XML::Atom::Content->new;
            $content->src($media_uri);
            $content->type($c->req->content_type);
            $entry->content($content);
        }
    }
    $entry;
}

sub _make_id {
    my($uri) = @_;
    $uri = URI->new($uri);
    my $path = $uri->path;
    $path =~ s{#}{/}g;
    my $dt = datetime->dt;
    'tag:'.$uri->authority.','.$dt->ymd.':'.$path;
}

sub _create_media_link_entry {
    my($self, $c) = @_;
    my $entry = XML::Atom::Entry->new;
    $entry->edited($self->edited->w3c);
    $entry->updated($self->edited->w3c) unless $entry->updated;
    $entry->title(uri_unescape $c->req->slug || '');
    $entry->summary('');
    $entry;
}

sub create_action {
    my($self, %args) = @_; # %args: namespace, name, reverse, class, attributes, code

    my $attr = lc $args{attributes}{Atompub}[0];
    my $code =    $args{code};

    my $csv = Text::CSV->new({ allow_whitespace => 1 });
    $csv->parse($attr);
    for ($csv->fields) {
        $self->{handler}{$_} = $code if length $_;
#        %args = (); # removes 'Loaded Private actions' message in initialization
    }

    $self->NEXT::create_action(%args);
}

sub URI::no_query { [ split /[?&]/, shift->canonical ]->[0] }

package Catalyst::Controller::Atompub::Collection::Resource;

use Atompub::MediaType qw(media_type);

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(uri type body));

sub new {
    my($class, $args) = @_;
    $args ||= {};
    bless $args, $class;
}

sub is_collection {
    my($self) = @_;
    my $media_type = media_type($self->type) or return;
    return $media_type->is_a('feed');
}

sub is_entry {
    my($self) = @_;
    my $media_type = media_type($self->type) or return;
    return $media_type->is_a('entry');
}

sub is_media {
    my($self) = @_;
    my $media_type = media_type($self->type) or return;
    return !$media_type->is_a('application/atom+xml');
}

sub serialize {
    my($self) = @_;
    my $body = $self->body;
    UNIVERSAL::can($body, 'as_xml') ? $body->as_xml : $body;
}

1;
__END__

=head1 NAME

Catalyst::Controller::Atompub::Collection
- A Catalyst controller for the Atom Collection Resources


=head1 SYNOPSIS

    # Use the Catalyst helper
    $ perl script/myatom_create.pl controller MyCollection Atompub::Collection

    # And edit lib/MyAtom/Controller/MyCollection.pm
    package MyAtom::Controller::MyCollection;
    use base 'Catalyst::Controller::Atompub::Collection';

    # List resources in a Feed Document, which must be implemented in
    # the mehtod with "Atompub(list)" attribute
    sub get_feed :Atompub(list) {
        my($self, $c) = @_;

        # Skeleton of the Feed (XML::Atom::Feed) was prepared by
        # C::C::Atompub
        my $feed = $self->collection_resource->body;

        # Retrieve Entries sorted in descending order
        my $rs = $c->model('DBIC::Entries')->search({}, {
            order_by => 'edited desc',
        });

        # Add Entries to the Feed
        while (my $entry_resource = $rs->next) {
            my $entry = XML::Atom::Entry->new(\$entry_resource->xml);
            $feed->add_entry($entry);
        }

        # Return true on success
        1;
    }

    # Create new Entry in the method with "Atompub(create)" attribute
    sub create_entry :Atompub(create) {
        my($self, $c) = @_;

        # URI of the new Entry, which was determined by C::C::Atompub
        my $uri = $self->entry_resource->uri;

        # app:edited element, which was assigned by C::C::Atompub,
        # is coverted into ISO 8601 format like '2007-01-01 00:00:00'
        my $edited = $self->edited->iso;

        # POSTed Entry (XML::Atom::Entry)
        my $entry = $self->entry_resource->body;

        # Create new Entry
        $c->model('DBIC::Entries')->create({
            uri    => $uri,
            edited => $edited,
            xml    => $entry->as_xml,
        });

        # Return true on success
        1;
    }

    # Search the requested Entry in the method with "Atompub(read)"
    # attribute
    sub get_entry :Atompub(read) {
        my($self, $c) = @_;

        my $uri = $c->entry_resource->uri;

        # Retrieve the Entry
        my $rs = $c->model('DBIC::Entries')->find({ uri => $uri });

        # Set the Entry
        my $entry = XML::Atom::Entry->new(\$rs->xml);
        $self->entry_resource->body($entry);

        # Return true on success
        1;
    }

    # Update the requested Entry in the method with "Atompub(update)"
    # attribute
    sub update_entry :Atompub(update) {
        my($self, $c) = @_;

        my $uri = $c->entry_resource->uri;

        # app:edited element, which was assigned by C::C::Atompub,
        # is coverted into ISO 8601 format like '2007-01-01 00:00:00'
        my $edited = $self->edited->iso;

        # PUTted Entry (XML::Atom::Entry)
        my $entry = $self->entry_resource->body;

        # Update the Entry
        $c->model('DBIC::Entries')->find({ uri => $uri })->update({
            uri => $uri,
            edited => $edited,
            xml => $entry->as_xml,
        });

        # Return true on success
        1;
    }

    # Delete the requested Entry in the method with "Atompub(delete)"
    # attribute
    sub delete_entry :Atompub(delete) {
        my($self, $c) = @_;

        my $uri = $c->entry_resource->uri;

        # Delete the Entry
        $c->model('DBIC::Entries')->find({ uri => $uri })->delete;

        # Return true on success
        1;
    }

    # Access to http://localhost:3000/mycollection and get Feed Document


=head1 DESCRIPTION

Catalyst::Controller::Atompub::Collection provides the following features:

=over 4

=item * Pre-processing requests

L<Catalyst::Controller::Atompub::Collection> pre-processes the HTTP requests.
All you have to do is just writing CRUD operations in the subroutines
with I<Atompub> attribute.

=item * Media Resource support

Media Resources (binary data) as well as Entry Resources are supported.
A Media Link Entry, which has an I<atom:link> element to the newly created Media Resource,
is given by L<Catalyst::Controller::Atompub::Collection>.

=item * Media type check

L<Catalyst::Controller::Atompub::Collection> checks a media type of
the POSTed/PUTted resource based on collection configuration.

=item * Category check

L<Catalyst::Controller::Atompub::Collection> checks
I<atom:category> elements in the POSTed/PUTted Entry Document
based on collection configuration.

=item * Cache controll and versioning

Cache controll and versioning are enabled just by overriding C<find_version> method,
which returns I<ETag> and/or I<Last-Modified> header.

=item * Naming resources by I<Slug> header

Resource URIs are determined based on I<Slug> header if exists.
If the I<Slug> header is "Entry 1", the resource URI will be like:

    http://localhost:3000/mycollection/entry_1.atom

The default naming rules can be changed by overriding C<make_edit_uri> method.

=back


=head1 SUBCLASSING

One or more subclasses are required in your Atompub server implementation.
In the subclasses, methods with the following attributes must be defined.


=head2 sub xxx :Atompub(list)

Lists resources in a Feed Document.

This method is expected to add Entries and other elements to a skeleton of the Feed.
The following accessors can be used.

=over 2

=item - $controller->collection_resource->uri

URI of Collection

=item - $controller->collection_resource->body

Skeleton of Feed (L<XML::Atom::Feed>)

=back

Returns true on success, false otherwise.


=head2 sub xxx :Atompub(create)

Creates new resource.

=over 4

=item * In Collections with Entry Resources

The implementation is expected to insert the new Entry to your model, such as L<DBIx::Class>.
The following accessors can be used.

=over 2

=item - $controller->entry_resource->uri

URI of New Entry

=item - $controller->entry_resource->edited

I<app:edited> element of New Entry

=item - $controller->entry_resource->body

New Entry (L<XML::Atom::Entry>)

=back


=item * In Collections with Media Resources

The implementation is expected to insert new Media Link Entry as well as new Media Resource
to your model, such as L<DBIx::Class>.

The following accessors can be used for the Media Resource.

=over 2

=item - $controller->media_resource->uri

URI of New Media Resource

=item - $controller->media_resource->edited

I<app:edited> element of New Media Resource

=item - $controller->media_resource->type

Media type of New Media Resource

=item - $controller->media_resource->body

New Media Resource (a byte string)

=back


The following accessors can be used for Media Link Entry.

=over 2

=item - $controller->media_link_entry->uri

URI of New Media Link Entry

=item - $controller->media_link_entry->edited

I<app:edited> element of New Media Link Entry

=item - $controller->media_link_entry->body

New Media Link Entry (L<XML::Atom::Entry>)

=back


=back

Returns true on success, false otherwise.


=head2 sub xxx :Atompub(read)

Searchs the requested resource.

=over 4

=item * In Collections with Entry Resources

The implementation is expected to search the Entry,
which must be stored in C<body> accessor described below.
The following accessors can be used.

=over 2

=item - $controller->entry_resource->body

Entry (L<XML::Atom::Entry>)

=back

=item * In Collections with Media Resources

The implementation is expected to search Media Resource or Media Link Entry,
which must be stored in C<body> accessor described below.
The following accessors can be used for the Media Resource.

=over 2

=item - $controller->media_resource->type

Media type of Media Resource

=item - $controller->media_resource->body

Media Resource (a byte string)

=back

The following accessors can be used for the Media Link Entry.

=over 2

=item - $controller->media_link_entry->body

Media Link Entry (L<XML::Atom::Entry>)

=back

=back

Returns true on success, false otherwise.


=head2 sub xxx :Atompub(update)

Updates the requested resource.


=over 4

=item * In Collections with Entry Resources

The implementation is expected to update the Entry.
The following accessors can be used.

=over 2

=item - $controller->entry_resource->uri

URI of Entry

=item - $controller->entry_resource->edited

I<app:edited> element of Entry

=item - $controller->entry_resource->body

Entry (L<XML::Atom::Entry>)

=back


=item * In Collections with Media Resources

The implementation is expected to update the Media Resource or the Media Link Entry.
The following accessors can be used for the Media Resource.

=over 2

=item - $controller->media_resource->uri

URI of Media Resource

=item - $controller->media_resource->edited

I<app:edited> element of Media Resource

=item - $controller->media_resource->type

Media type of Media Resource

=item - $controller->media_resource->body

Media Resource (a byte string)

=back


The following accessors can be used for the Media Link Entry.

=over 2

=item - $controller->media_link_entry->uri

URI of Media Link Entry

=item - $controller->media_link_entry->edited

I<app:edited> element of Media Link Entry

=item - $controller->media_link_entry->body

Media Link Entry (L<XML::Atom::Entry>)

=back

=back

Returns true on success, false otherwise.


=head2 sub xxx :Atompub(delete)

Deletes the requested resource.

The implementation is expected to delete the resource.
If the collection contains Media Resources,
corresponding Media Link Entry must be deleted at once.

Returns true on success, false otherwise.


=head1 METHODS

The following methods can be overridden to change the default behaviors.


=head2 $controller->find_version($uri)

By overriding C<find_version> method, cache control and versioning are enabled.

The implementation is expected to return I<ETag> and/or I<Last-Modified> value
of the requested URI:

    package MyAtom::Controller::MyCollection;

    sub find_version {
        my($self, $c, $uri) = @_;

        # Retrieve ETag and/or Last-Modified of $uri

        return (etag => $etag, last_modified => $last_modified);
    }

When a resource of the URI does not exist, the implementation must return an empty array.

The behavior of Atompub server will be changed in the following manner:

=over 4

=item * On GET request

Status code of 304 (Not Modified) will be returned,
if the requested resource has not been changed.

=item * On PUT request

Status code of 412 (Precondition Failed) will be returned,
if the current version of the resource that a client is modifying is not
the same as the version that the client is basing its modifications on.

=back


=head2 $controller->make_edit_uri($c, [@args])

By default, if the I<Slug> header is "Entry 1", the resource URI will be like:

    http://localhost:3000/mycollection/entry_1.atom

This default behavior can be changed by overriding C<find_version> method:

    package MyAtom::Controller::MyCollection;

    sub make_edit_uri {
        my($self, $c, @args) = @_;

        my @uris = $self->SUPER::make_edit_uri($c, @args);

        # Modify @uris as you like

        return @uris;
    }

Arguments @args are media types of POSTed resources.

This method returns an array of resource URIs;
the first element is a URI of the Entry Resource (including Media Link Entry),
and the second one is a URI of the Media Resource if exists.


=head2 $controller->default($c)

=head2 $controller->edit_uri($c)

=head2 $controller->make_collection_uri($c)

The collection URI can be changed,
by overriding C<default> and C<edit_uri> methods and modify the attributes.

In the following example, the collection URI is changed like /mycollection/<username>
by overriding C<default> and C<edit_uri> methods.
The new parameter <username> is obtained by $c->req->captures->[0] in the collection,
or $c->user->username in the service document.

Override C<make_collection_uri> method, if collection URI has to be changed.

See samples/OurBlogs in details.

    package MyAtom::Controller::MyCollection;

    sub default :LocalRegex('^(\w+)$') {
        my($self, $c) = @_;
        $self->NEXT::default($c);
    }

    sub edit_uri :LocalRegex('^(\w+)/([.\w]+)$') {
        my($self, $c) = @_;
        $self->NEXT::edit_uri($c);
    }

    sub make_collection_uri {
        my($self, $c) = @_;
        my $class = ref $self || $self;
        $class->NEXT::make_collection_uri($c).'/'
            .(ref $c->controller eq $class ? $c->req->captures->[0] : $c->user->username);
    }

=head2 $controller->do_list

=head2 $controller->do_create

=head2 $controller->do_read

=head2 $controller->do_update

=head2 $controller->do_delete


=head1 ACCESSORS

=head2 $controller->resource

=head2 $controller->rc

An accessor for a resource object except Media Link Entry.


=head2 $controller->collection_resource

An accessor for a Collection Resource object.


=head2 $controller->entry_resource

An accessor for an Entry Resource objecgt.


=head2 $controller->media_resource

An accessor for a Media Resource object.


=head2 $controller->media_link_entry

An accessor for a Media Link Entry object.


=head2 $controller->edited

An accessor for a app:edited, which is applied for the POSTed/PUTted Entry Resource.


=head1 INTERNAL INTERFACES

=head2 $controller->auto

=head2 $controller->_list

=head2 $controller->_create

=head2 $controller->_read

=head2 $controller->_update

=head2 $controller->_delete

=head2 $controller->_is_modified

=head2 $controller->create_action


=head1 FEED PAGING

This module does not provide paging of Feed Documents.
Paging mechanism should be implemented in a method with "Atompub(list)" attribute.


=head1 CONFIGURATION

By default (no configuration), Collections accept Entry Documents
(application/atom+xml) and any I<atom:category> element.

Acceptable I<atom:category> elements can be set like:

    Controller::EntryCollection:
        collection:
            title: Diary
            categories:
              - fixed: yes
                scheme: http://example.com/cats/big3
                category:
                  - term: animal
                    label: animal
                  - term: vegetable
                    label: vegetable
                  - term: mineral
                    scheme: http://example.com/dogs/big3
                    label: mineral

Acceptable media types is configured like:

    Controller::MediaCollection:
        collection:
            title: Photo
            accept:
              - image/png
              - image/jpeg
              - image/gif


=head1 ERROR HANDLING

See ERROR HANDLING in L<Catalyst::Controller::Atompub::Base>.


=head1 SAMPLES

See SAMPLES in L<Catalyst::Controller::Atompub>.


=head1 SEE ALSO

L<XML::Atom>
L<XML::Atom::Service>
L<Atompub>
L<Catalyst::Controller::Atompub>


=head1 AUTHOR

Takeru INOUE  C<< <takeru.inoue _ gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Takeru INOUE C<< <takeru.inoue _ gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
