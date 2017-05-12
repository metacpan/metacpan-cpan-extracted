package # hide from PAUSE
    MyBlog::Controller::EntryCollection;

use strict;
use warnings;

use Atompub::DateTime qw(datetime);
use Atompub::MediaType qw(media_type);
use HTTP::Status;
use POSIX qw(strftime);
use String::CamelCase qw(camelize);
use Time::HiRes qw(gettimeofday);

use base qw(Catalyst::Controller::Atompub::Collection);

my $ENTRIES_PER_PAGE = 10;
my $TABLE_NAME       = 'entries';

my $MODEL = join '::', 'DBIC', camelize($TABLE_NAME);

sub get_feed :Atompub(list) {
    my($self, $c) = @_;

    ## URI without parameters
    my $uri = $self->collection_resource->uri;

    my $feed = $self->collection_resource->body;

    my $page = $c->req->param('page') || 1;

    my $attr = {
        offset   => ($page - 1) * $ENTRIES_PER_PAGE,
        rows     => $ENTRIES_PER_PAGE,
        order_by => 'edited desc',
    };

    my $rs = $c->model($MODEL)->search({}, $attr);

    while (my $resource = $rs->next) {
        my $entry = XML::Atom::Entry->new(\$resource->body);
        $feed->add_entry($entry);
    }

    $feed->alternate_link($c->req->base.'html');
    $feed->first_link($uri);
    $feed->previous_link("$uri?page=".($page-1)) if $page > 1;
    $feed->next_link("$uri?page=".($page+1)) if $rs->count >= $ENTRIES_PER_PAGE;

    1;
}

sub create_resource :Atompub(create) {
    my($self, $c) = @_;

    # URI of the new Entry, which was determined by C::C::Atompub
    my $uri = $self->entry_resource->uri;

    return $self->error($c, RC_CONFLICT, "Resource name is used (change Slug): $uri")
        if $c->model($MODEL)->find({ uri => $uri });

    my $entry = $self->entry_resource->body;

    # Edit $entry if needed

    my $vals = {
        edited => $self->edited->epoch,
        uri    => $uri,
        etag   => $self->calculate_new_etag($c, $uri),
        body   => $entry->as_xml,
    };

    $c->model($MODEL)->create($vals)
        or return $self->error($c, RC_INTERNAL_SERVER_ERROR, 'Cannot create new resource');

    1;
}

sub get_resource :Atompub(read) {
    my($self, $c) = @_;

    my $uri = $c->req->uri;

    my $rs = $c->model($MODEL)->find({ uri => $uri })
        or return $self->error($c, RC_NOT_FOUND);

    $self->entry_resource->body(XML::Atom::Entry->new(\$rs->body));

    1;
}

sub update_resource :Atompub(update) {
    my($self, $c) = @_;

    my $uri = $c->req->uri;

    # Edit $entry if needed

    my $rs = $c->model($MODEL)->find({ uri => $uri })
        or return $self->error($c, RC_NOT_FOUND);

    my $vals = {
        edited => $self->edited->epoch,
        uri    => $uri,
        etag   => $self->calculate_new_etag($c, $uri),
        body   => $self->entry_resource->body->as_xml,
    };

    $rs->update($vals)
        or return $self->error($c, RC_INTERNAL_SERVER_ERROR, "Cannot update resource: $uri");

    1;
}

sub delete_resource :Atompub(delete) {
    my($self, $c) = @_;

    my $uri = $c->req->uri;

    my $rs = $c->model($MODEL)->find({ uri => $uri })
        or return $self->error($c, RC_NOT_FOUND);

    $rs->delete
        or return $self->error($c, RC_INTERNAL_SERVER_ERROR, "Cannot delete resource: $uri");

    1;
}

sub make_edit_uri {
    my($self, $c, @args) = @_;

    # comment out to getting entry resource
    #my $entry = $self->entry_resource->body;

    my @uris = $self->SUPER::make_edit_uri($c, @args);

    # return, if $uris[0] is not used
    return wantarray ? @uris : $uris[0]
        unless $c->model($MODEL)->find({ uri => $uris[0] });

    my($sec, $usec) = gettimeofday;
    my $dt = strftime '%Y%m%d-%H%M%S', localtime($sec);
    $usec  = sprintf '%06d', $usec;

    # insert $dt-$usec before extension
    $_ =~ s{(\.[^./?]+)$}{-$dt-$usec$1} for @uris;

    @uris;
}

sub find_version {
    my($self, $c, $uri) = @_;

    my $rs = $c->model($MODEL)->find({ uri => $uri }) or return;

    return (etag => $rs->etag);
#    return (etag => $rs->etag, last_modified => datetime($rs->edited)->str);
}

sub calculate_new_etag {
    my($self, $c, $uri) = @_;
    my($sec, $usec) = gettimeofday;
    my $dt = join '-', strftime('%Y%m%d-%H%M%S', localtime($sec)), sprintf('%06d', $usec);
    join '/', $uri, $dt;
}

1;
