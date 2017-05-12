package ArangoDB2::HTTP::Curl;

use strict;
use warnings;

use base qw(
    ArangoDB2::HTTP
);

use Data::Dumper;
use HTTP::Response;
use JSON::XS;
use Scalar::Util qw(weaken);
use WWW::Curl::Easy;



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

    # setup curl
    my $curl = $self->{curl} = WWW::Curl::Easy->new;
    # set authentication is username is specified
    if ($self->arango->username) {
        $curl->setopt(CURLOPT_USERNAME, $self->arango->username);
        $curl->setopt(CURLOPT_PASSWORD, $self->arango->password);
        $curl->setopt(CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
    }

    return $self;
}

# curl
#
# return new Curl client instance
sub curl
{
    my($self, $method, $path, $args, $data, $raw) = @_;

    my $curl = $self->{curl};

    # get copy of ArangoDB API URI
    my $uri = $self->arango->uri->clone;
    # set path for request
    $uri->path($path);
    # set query params on URI if passed
    $uri->query_form($args) if $args;

    # response body
    my $response;
    # setup curl request
    $curl->setopt(CURLOPT_URL, $uri->as_string);
    $curl->setopt(CURLOPT_CUSTOMREQUEST, $method);
    $curl->setopt(CURLOPT_WRITEDATA, \$response);
    # add post data if set
    if ($data && length $data) {
        $curl->setopt(CURLOPT_POSTFIELDS, $data);
        $curl->setopt(CURLOPT_POSTFIELDSIZE, length $data);
    }
    else {
        $curl->setopt(CURLOPT_POSTFIELDS, '');
        $curl->setopt(CURLOPT_POSTFIELDSIZE, 0);
    }
    # do not get body on HEAD request
    if ($method eq 'HEAD') {
        $curl->setopt(CURLOPT_NOBODY, 1);
    }
    else {
        $curl->setopt(CURLOPT_NOBODY, 0);
    }
    # combined headers and body for parsing by HTTP::Response
    if ($raw) {
        $curl->setopt(CURLOPT_HEADER, 1)
    }
    else {
        $curl->setopt(CURLOPT_HEADER, 0)
    }

    # do request
    my $ret = $curl->perform;

    # if raw is specified we build an HTTP::Response to return
    return $raw
        ? HTTP::Response->parse($response)
        : $self->curl_response($curl, $ret, \$response);
}

# delete
#
# make a DELETE request using the ArangoDB API uri along with
# the path and any args passed
sub delete
{
    my($self, $path, $args, $raw) = @_;

    return $self->curl("DELETE", $path, $args, undef, $raw);
}

# get
#
# make a GET request using the ArangoDB API uri along with
# the path and any args passed
sub get
{
    my($self, $path, $args, $raw) = @_;

    return $self->curl("GET", $path, $args, undef, $raw);
}

# head
#
# make a HEAD request using the ArangoDB API uri along with
# the path and any args passed
sub head
{
    my($self, $path, $args, $raw) = @_;
    # get HTTP::Response so we can check code
    my $res = $self->curl("HEAD", $path, $args, undef, 1);
    # if raw was set then return response
    return $res if $raw;
    # return code if success
    return $res->is_success ? $res->code : undef;
}

# patch
#
# make a PATCH request using the ArangoDB API uri along with
# the path and any args passed
sub patch
{
    my($self, $path, $args, $data, $raw) = @_;

    return $self->curl("PATCH", $path, $args, $data, $raw);
}

# put
#
# make a PUT request using the ArangoDB API uri along with
# the path and any args passed
sub put
{
    my($self, $path, $args, $data, $raw) = @_;

    return $self->curl("PUT", $path, $args, $data, $raw);
}

# post
#
# make a POST request using the ArangoDB API uri along with
# the path and any args passed
sub post
{
    my($self, $path, $args, $data, $raw) = @_;

    return $self->curl("POST", $path, $args, $data, $raw);
}

# curl_response
#
# process a curl response
sub curl_response
{
    my($self, $curl, $ret, $response) = @_;
    # a curl error occured
    if ($ret != 0) {
        $self->error($curl->strerror($ret)." ".$curl->errbuf);
        return;
    }
    # get http response code
    my $code = $curl->getinfo(CURLINFO_HTTP_CODE);
    # require code in 200 range for success
    if (!($code >= 200 && $code < 300)) {
        $self->error($code);
        return;
    }
    # decode response, assuming JSON
    my $res = eval { $JSON->decode($$response) };
    # if content is not valid JSON then return entire content
    return $$response unless $res;
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

1;

__END__


=head1 NAME

ArangoDB2::HTTP::LWP - ArangoDB HTTP transport layer implemented with LWP

=head1 METHODS

=over 4

=item new

=item curl

=item delete

=item get

=item head

=item patch

=item put

=item post

=item curl_response

=back

=head1 AUTHOR

Ersun Warncke, C<< <ersun.warncke at outlook.com> >>

http://ersun.warnckes.com

=head1 COPYRIGHT

Copyright (C) 2014 Ersun Warncke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
