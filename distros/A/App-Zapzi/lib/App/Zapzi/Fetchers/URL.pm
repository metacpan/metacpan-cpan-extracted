package App::Zapzi::Fetchers::URL;
# ABSTRACT: fetch article via URL


use utf8;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use Carp;
use Data::Validate::URI 0.06;
use HTTP::Tiny;
use HTTP::CookieJar;
use Moo;

with 'App::Zapzi::Roles::Fetcher';


sub name
{
    return 'URL';
}


sub handles
{
    my $self = shift;
    my $source = shift;

    my $v = Data::Validate::URI->new();
    my $url = $v->is_web_uri($source) || $v->is_web_uri('http://' . $source);
    return $url;
}


sub fetch
{
    my $self = shift;

    my $jar = HTTP::CookieJar->new;
    my $http = HTTP::Tiny->new(cookie_jar => $jar);

    my $url = $self->source;
    my $response = $http->get($url, $self->_http_request_headers());

    if (! $response->{success} || ! length($response->{content}))
    {
        my $error = "Failed to fetch $url: ";
        if ($response->{status} == 599)
        {
            # Internal exception to HTTP::Tiny
            $error .= $response->{content};
        }
        else
        {
            # Error details from remote server
            $error .= $response->{status} . " ";
            $error .= $response->{reason};
        }
        $self->_set_error($error);
        return;
    }

    $self->_set_text($response->{content});
    $self->_set_content_type($response->{headers}->{'content-type'});

    return 1;
}

sub _http_request_headers
{
    my $self = shift;

    my $ua = "App::Zapzi";

    no strict 'vars'; ## no critic - $VERSION does not exist in dev
    $ua .= "/$VERSION" if defined $VERSION;

    return {headers => {
                           'User-agent' => $ua,
                           # Don't gzip encode the response
                           'Accept-encoding' => 'identity'
                       }};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Zapzi::Fetchers::URL - fetch article via URL

=head1 VERSION

version 0.017

=head1 DESCRIPTION

This class downloads an article over HTTP via the given URL.

=head1 METHODS

=head2 name

Name of transformer visible to user.

=head2 handles($content_type)

Returns a validated URL if this module handles the given content-type

=head2 fetch

Downloads an article

=head1 AUTHOR

Rupert Lane <rupert@rupert-lane.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rupert Lane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
