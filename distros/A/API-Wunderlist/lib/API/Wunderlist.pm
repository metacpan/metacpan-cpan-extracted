# ABSTRACT: Wunderlist.com API Client
package API::Wunderlist;

use Data::Object::Class;
use Data::Object::Signatures;

use Data::Object::Library qw(
    Str
);

extends 'API::Client';

our $VERSION = '0.06'; # VERSION

our $DEFAULT_URL = "https://a.wunderlist.com";

# ATTRIBUTES

has client_id => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

has access_token => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

# DEFAULTS

has '+identifier' => (
    default  => 'API::Wunderlist (Perl)',
    required => 0,
);

has '+url' => (
    default  => $DEFAULT_URL,
    required => 0,
);

has '+version' => (
    default  => 1,
    required => 0,
);

# CONSTRUCTION

after BUILD => method {

    my $identifier   = $self->identifier;
    my $client_id    = $self->client_id;
    my $access_token = $self->access_token;
    my $version      = $self->version;
    my $agent        = $self->user_agent;
    my $url          = $self->url;

    $agent->transactor->name($identifier);

    $url->path("/api/v$version");

    return $self;

};

# METHODS

method PREPARE ($ua, $tx, %args) {

    my $headers = $tx->req->headers;
    my $url     = $tx->req->url;

    # default headers
    $headers->header('X-Client-ID' => $self->client_id);
    $headers->header('X-Access-Token' => $self->access_token);
    $headers->header('Content-Type' => 'application/json');

}

method resource (@segments) {

    # build new resource instance
    my $instance = __PACKAGE__->new(
        debug        => $self->debug,
        fatal        => $self->fatal,
        retries      => $self->retries,
        timeout      => $self->timeout,
        user_agent   => $self->user_agent,
        identifier   => $self->identifier,
        client_id    => $self->client_id,
        access_token => $self->access_token,
        version      => $self->version,
    );

    # resource locator
    my $url = $instance->url;

    # modify resource locator if possible
    $url->path(join '/', $self->url->path, @segments);

    # return resource instance
    return $instance;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Wunderlist - Wunderlist.com API Client

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    use API::Wunderlist;

    my $wunderlist = API::Wunderlist->new(
        client_id    => 'CLIENT_ID',
        access_token => 'ACCESS_TOKEN',
        identifier   => 'APPLICATION NAME',
    );

    $wunderlist->debug(1);
    $wunderlist->fatal(1);

    my $list = $wunderlist->lists('12345');
    my $results = $list->fetch;

    # after some introspection

    $list->update( ... );

=head1 DESCRIPTION

This distribution provides an object-oriented thin-client library for
interacting with the Wunderlist (L<https://wunderlist.com/>) API. For usage and
documentation information visit L<https://developer.wunderlist.com/documentation>.
API::Wunderlist is derived from L<API::Client> and inherits all of it's
functionality. Please read the documentation for API::Client for more usage
information.

=head1 ATTRIBUTES

=head2 access_token

    $wunderlist->access_token;
    $wunderlist->access_token('ACCESS_TOKEN');

The access_token attribute should be set to an Access-Token associated with
your Client-ID.

=head2 client_id

    $wunderlist->client_id;
    $wunderlist->client_id('CLIENT_ID');

The client_id attribute should be set to the Client-ID of your application.

=head2 identifier

    $wunderlist->identifier;
    $wunderlist->identifier('IDENTIFIER');

The identifier attribute should be set to a string that identifies your app.

=head2 debug

    $wunderlist->debug;
    $wunderlist->debug(1);

The debug attribute if true prints HTTP requests and responses to standard out.

=head2 fatal

    $wunderlist->fatal;
    $wunderlist->fatal(1);

The fatal attribute if true promotes 4xx and 5xx server response codes to
exceptions, a L<API::Client::Exception> object.

=head2 retries

    $wunderlist->retries;
    $wunderlist->retries(10);

The retries attribute determines how many times an HTTP request should be
retried if a 4xx or 5xx response is received. This attribute defaults to 0.

=head2 timeout

    $wunderlist->timeout;
    $wunderlist->timeout(5);

The timeout attribute determines how long an HTTP connection should be kept
alive. This attribute defaults to 10.

=head2 url

    $wunderlist->url;
    $wunderlist->url(Mojo::URL->new('https://a.wunderlist.com'));

The url attribute set the base/pre-configured URL object that will be used in
all HTTP requests. This attribute expects a L<Mojo::URL> object.

=head2 user_agent

    $wunderlist->user_agent;
    $wunderlist->user_agent(Mojo::UserAgent->new);

The user_agent attribute set the pre-configured UserAgent object that will be
used in all HTTP requests. This attribute expects a L<Mojo::UserAgent> object.

=head1 METHODS

=head2 action

    my $result = $wunderlist->action($verb, %args);

    # e.g.

    $wunderlist->action('head', %args);    # HEAD request
    $wunderlist->action('options', %args); # OPTIONS request
    $wunderlist->action('patch', %args);   # PATCH request

The action method issues a request to the API resource represented by the
object. The first parameter will be used as the HTTP request method. The
arguments, expected to be a list of key/value pairs, will be included in the
request if the key is either C<data> or C<query>.

=head2 create

    my $results = $wunderlist->create(%args);

    # or

    $wunderlist->POST(%args);

The create method issues a C<POST> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head2 delete

    my $results = $wunderlist->delete(%args);

    # or

    $wunderlist->DELETE(%args);

The delete method issues a C<DELETE> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head2 fetch

    my $results = $wunderlist->fetch(%args);

    # or

    $wunderlist->GET(%args);

The fetch method issues a C<GET> request to the API resource represented by the
object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head2 update

    my $results = $wunderlist->update(%args);

    # or

    $wunderlist->PUT(%args);

The update method issues a C<PUT> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head1 RESOURCES

=head2 avatars

    $wunderlist->avatars;

The avatars method returns a new instance representative of the API
I<Avatar> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.wunderlist.com/documentation/endpoints/avatar>.

=head2 file_previews

    $wunderlist->previews;

The file_previews method returns a new instance representative of the API
I<Preview> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.wunderlist.com/documentation/endpoints/file_preview>.

=head2 files

    $wunderlist->files;

The files method returns a new instance representative of the API
I<File> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.wunderlist.com/documentation/endpoints/file>.

=head2 folders

    $wunderlist->folders;

The folders method returns a new instance representative of the API
I<Folder> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.wunderlist.com/documentation/endpoints/folder>.

=head2 lists

    $wunderlist->lists;

The lists method returns a new instance representative of the API
I<List> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.wunderlist.com/documentation/endpoints/list>.

=head2 memberships

    $wunderlist->memberships;

The memberships method returns a new instance representative of the API
I<Membership> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.wunderlist.com/documentation/endpoints/membership>.

=head2 notes

    $wunderlist->notes;

The notes method returns a new instance representative of the API
I<Note> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.wunderlist.com/documentation/endpoints/note>.

=head2 positions

    $wunderlist->list_positions;

The positions method returns a new instance representative of the API
I<Positions> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.wunderlist.com/documentation/endpoints/positions>.

=head2 reminders

    $wunderlist->reminders;

The reminders method returns a new instance representative of the API
I<Reminder> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.wunderlist.com/documentation/endpoints/reminder>.

=head2 subtasks

    $wunderlist->subtasks;

The subtasks method returns a new instance representative of the API
I<Subtask> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.wunderlist.com/documentation/endpoints/subtask>.

=head2 task_comments

    $wunderlist->task_comments;

The task_comments method returns a new instance representative of the API
I<Task Comment> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.wunderlist.com/documentation/endpoints/task_comment>.

=head2 tasks

    $wunderlist->tasks;

The tasks method returns a new instance representative of the API
I<Task> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.wunderlist.com/documentation/endpoints/task>.

=head2 uploads

    $wunderlist->uploads;

The uploads method returns a new instance representative of the API
I<Upload> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.wunderlist.com/documentation/endpoints/upload>.

=head2 users

    $wunderlist->users;

The users method returns a new instance representative of the API
I<User> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.wunderlist.com/documentation/endpoints/user>.

=head2 webhooks

    $wunderlist->webhooks;

The webhooks method returns a new instance representative of the API
I<Webhooks> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.wunderlist.com/documentation/endpoints/webhooks>.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
