package # hide from PAUSE
    MyBlog::Controller::MediaCollection;

use strict;
use warnings;

use Atompub::DateTime qw(datetime);
use Atompub::MediaType qw(media_type);
use MIME::Base64;
use HTTP::Status;
use POSIX qw(strftime);
use String::CamelCase qw(camelize);
use Time::HiRes qw(gettimeofday);

use base qw(Catalyst::Controller::Atompub::Collection);

my $ENTRIES_PER_PAGE = 10;
my $TABLE_NAME       = 'medias';

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
	my $entry = XML::Atom::Entry->new(\$resource->entry_body);
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

    # URIs were determined by C::C::Atompub
    my $entry_uri = $self->media_link_entry->uri;
    my $media_uri = $self->media_resource->uri;

    return $self->error($c, RC_CONFLICT, "Resource name is used (change Slug): $entry_uri")
	if $c->model($MODEL)->search({ entry_uri => $entry_uri })->count;

    # Edit $entry and $media if needed ...

    my $vals = {
	edited     => $self->edited->epoch,
	entry_uri  => $entry_uri,
	entry_etag => $self->calculate_new_etag($c, $entry_uri),
	entry_body => $self->media_link_entry->body->as_xml,
	media_uri  => $media_uri,
	media_etag => $self->calculate_new_etag($c, $media_uri),
	media_body => MIME::Base64::encode($self->media_resource->body),
	media_type => $self->media_resource->type,
    };

    $c->model($MODEL)->create($vals)
	or return $self->error($c, RC_INTERNAL_SERVER_ERROR,
                               'Cannot create new media resource');

    1;
}

sub get_resource :Atompub(read) {
    my($self, $c) = @_;

    my $uri = $c->req->uri;

    my $cond = {
        '-or' => [
            { entry_uri => $uri },
            { media_uri => $uri },
        ],
    };

    my $rs = $c->model($MODEL)->search($cond)->first
	or return $self->error($c, RC_NOT_FOUND);

    if ($rs->entry_uri eq $uri) {
	$self->media_link_entry->body( XML::Atom::Entry->new(\$rs->entry_body) );
	$self->media_resource->type(media_type('entry'));
    }
    else {
	$self->media_resource->body( MIME::Base64::decode($rs->media_body) );
	$self->media_resource->type($rs->media_type);
    }

    1;
}

sub update_resource :Atompub(update) {
    my($self, $c) = @_;

    my $uri = $c->req->uri;

    my $cond = {
        '-or' => [
            { entry_uri => $uri },
            { media_uri => $uri },
        ],
    };

    my $rs = $c->model($MODEL)->search($cond)->first
	or return $self->error($c, RC_NOT_FOUND);

    my $vals = { edited => $self->edited->epoch };

    my($media_link_entry, $media_type);
    if ($rs->entry_uri eq $uri) {
	$media_link_entry = $self->media_link_entry->body;
        $media_type = $rs->media_type;

	# Don't update the Last-Modified value of the corresponding
        # Media Resource if you use it
    }
    else {
	$media_link_entry = XML::Atom::Entry->new(\$rs->entry_body)
	    or return $self->error($c);

	$vals->{media_etag} = $self->calculate_new_etag($c, $rs->media_uri);
	$vals->{media_body} = MIME::Base64::encode($self->media_resource->body);
	$vals->{media_type} = $media_type = $self->media_resource->type;

	# Do update the Last-Modified value of the Media Resource if you use it
    }

    # app:edited and atom:content in Media Link Entry MUST be updated
    $media_link_entry->edited($self->edited->w3c);
    my $content = XML::Atom::Content->new;
    $content->src($rs->media_uri);
    $content->type($media_type);
    $media_link_entry->content($content);

    $vals->{entry_body} = $media_link_entry->as_xml;
    $vals->{entry_etag} = $self->calculate_new_etag($c, $rs->entry_uri);

    $rs->update($vals)
	or return $self->error($c, RC_INTERNAL_SERVER_ERROR, "Cannot update resource: $uri");

    1;
}

sub delete_resource :Atompub(delete) {
    my($self, $c) = @_;

    my $uri = $c->req->uri;

    my $cond = {
        '-or' => [
            { entry_uri => $uri },
            { media_uri => $uri },
        ],
    };

    my $rs = $c->model($MODEL)->search($cond)->first
	or return $self->error($c, RC_NOT_FOUND);

    # delete entry and media resources at once
    $rs->delete
	or return $self->error($c, RC_INTERNAL_SERVER_ERROR, "Cannot delete resource: $uri");

    1;
}

sub make_edit_uri {
    my($self, $c, @args) = @_;

    my @uris = $self->SUPER::make_edit_uri($c, @args);

    my $cond = {
        '-or' => [
            { entry_uri => $uris[0] },
            { media_uri => $uris[0] },
        ],
    };

    # return, if $uris[0] is not used
    return wantarray ? @uris : $uris[0]
	unless $c->model($MODEL)->search($cond)->count;

    my($sec, $usec) = gettimeofday;
    my $dt = strftime '%Y%m%d-%H%M%S', localtime($sec);
    $usec  = sprintf '%06d', $usec;

    # insert $dt-$usec before extension
    $_ =~ s{(\.[^./?]+)$}{-$dt-$usec$1} for @uris;

    @uris;
}

sub find_version {
    my($self, $c, $uri) = @_;

    my $cond = {
        '-or' => [
            { entry_uri => $uri },
            { media_uri => $uri },
        ],
    };

    my $rs = $c->model($MODEL)->search($cond)->first or return;

    if ($rs->entry_uri eq $uri) {
	return (etag => $rs->entry_etag);
    }
    else {
	return (etag => $rs->media_etag);
    }
}

sub calculate_new_etag {
    my($self, $c, $uri) = @_;
    my($sec, $usec) = gettimeofday;
    my $dt = join '-', strftime('%Y%m%d-%H%M%S', localtime($sec)), sprintf('%06d', $usec);
    join '/', $uri, $dt;
}

1;
