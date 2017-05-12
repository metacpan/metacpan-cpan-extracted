package ArangoDB2::HTTP::LWP;

use strict;
use warnings;

use base qw(
    ArangoDB2::HTTP
);

use Data::Dumper;
use JSON::XS;
use LWP::UserAgent;
use Scalar::Util qw(weaken);



my $JSON = JSON::XS->new->utf8;



sub new
{
    my($class, $arango) = @_;
    # we do not want to hold this reference if the
    # parent goes out of scope
    weaken $arango;
    # create new instance
    my $self = {
        arango => $arango,
    };
    bless($self, $class);

    $self->{lwp} = LWP::UserAgent->new(
        keep_alive => 1
    );

    # set authentication is username is specified
    if ($self->arango->username) {
        $self->lwp->default_headers->authorization_basic(
            $self->arango->username,
            $self->arango->password,
        );
    }

    return $self;
}

# delete
#
# make a DELETE request using the ArangoDB API uri along with
# the path and any args passed
sub delete
{
    my($self, $path, $args, $raw) = @_;
    # get copy of ArangoDB API URI
    my $uri = $self->arango->uri->clone;
    # set path for request
    $uri->path($path);
    # set query params on URI if passed
    $uri->query_form($args) if $args;
    # make request
    my $response = $self->lwp->delete($uri);
    # do not process response if raw requested
    return $response if $raw;
    # process response
    return $self->response($response);
}

# get
#
# make a GET request using the ArangoDB API uri along with
# the path and any args passed
sub get
{
    my($self, $path, $args, $raw) = @_;
    # get copy of ArangoDB API URI
    my $uri = $self->arango->uri->clone;
    # set path for request
    $uri->path($path);
    # set query params on URI if passed
    $uri->query_form($args) if $args;
    # make request
    my $response = $self->lwp->get($uri);
    # do not process response if raw requested
    return $response if $raw;
    # process response
    return $self->response($response);
}

# head
#
# make a HEAD request using the ArangoDB API uri along with
# the path and any args passed
sub head
{
    my($self, $path, $args, $raw) = @_;
    # get copy of ArangoDB API URI
    my $uri = $self->arango->uri->clone;
    # set path for request
    $uri->path($path);
    # set query params on URI if passed
    $uri->query_form($args) if $args;
    # make request
    my $response = $self->lwp->head($uri);
    # do not process response if raw requested
    return $response if $raw;
    # return code
    return $response->code;
}

# lwp
#
# LWP::UserAgent instance
sub lwp { $_[0]->{lwp} }

# patch
#
# make a PATCH request using the ArangoDB API uri along with
# the path and any args passed
sub patch
{
    my($self, $path, $args, $patch, $raw) = @_;
    # get copy of ArangoDB API URI
    my $uri = $self->arango->uri->clone;
    # set path for request
    $uri->path($path);
    # set query params on URI if passed
    $uri->query_form($args) if $args;
    # build HTTP::Request
    my $request = HTTP::Request->new('PATCH', $uri);
    $request->content($patch);
    # make request
    my $response = $self->lwp->request($request);
    # do not process response if raw requested
    return $response if $raw;
    # process response
    return $self->response($response);
}

# put
#
# make a PUT request using the ArangoDB API uri along with
# the path and any args passed
sub put
{
    my($self, $path, $args, $put, $raw) = @_;
    # get copy of ArangoDB API URI
    my $uri = $self->arango->uri->clone;
    # set path for request
    $uri->path($path);
    # set query params on URI if passed
    $uri->query_form($args) if $args;
    # make request
    my $response = ref $put
        # if put is hashref then treat as key/value pairs
        # to be form encoded
        ? $self->lwp->put($uri, $put)
        # if put is string then put raw data
        : $self->lwp->put($uri, Content => $put);
    # do not process response if raw requested
    return $response if $raw;
    # process response
    return $self->response($response);
}

# post
#
# make a POST request using the ArangoDB API uri along with
# the path and any args passed
sub post
{
    my($self, $path, $args, $post, $raw) = @_;
    # get copy of ArangoDB API URI
    my $uri = $self->arango->uri->clone;
    # set path for request
    $uri->path($path);
    # set query params on URI if passed
    $uri->query_form($args) if $args;
    # make request
    my $response = ref $post
        # if post is hashref then treat as key/value pairs
        # to be form encoded
        ? $self->lwp->post($uri, $post)
        # if post is string then post raw data
        : $self->lwp->post($uri, Content => $post);
    # do not process response if raw requested
    return $response if $raw;
    # process response
    return $self->response($response);
}

# response
#
# process LWP::UserAgent response
sub response
{
    my($self, $response) = @_;

    if ($response->is_success) {
        my $res = eval { $JSON->decode($response->content) };
        # if content is not valid JSON then return entire content
        return $response->content unless $res;
        # res may be array in rare cases
        if (!(ref $res eq 'HASH')) {
            return $res;
        }
        # if there is a result object and no error and this is not a
        # cursor result then only return the result object
        elsif ( ($res->{result} || $res->{graph} || $res->{graphs})
                && !$res->{error} && !defined $res->{hasMore} )
        {
            return $res->{result} || $res->{graph} || $res->{graphs};
        }
        # otherwise return entire response
        else {
            return $res;
        }
    }
    else {
        # set error code
        $self->error($response->code);
        return;
    }
}

1;

__END__


=head1 NAME

ArangoDB2::HTTP::LWP - ArangoDB HTTP transport layer implemented with LWP

=head1 METHODS

=over 4

=item new

=item delete

=item get

=item head

=item lwp

=item patch

=item put

=item post

=item response

=back

=head1 AUTHOR

Ersun Warncke, C<< <ersun.warncke at outlook.com> >>

http://ersun.warnckes.com

=head1 COPYRIGHT

Copyright (C) 2014 Ersun Warncke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
