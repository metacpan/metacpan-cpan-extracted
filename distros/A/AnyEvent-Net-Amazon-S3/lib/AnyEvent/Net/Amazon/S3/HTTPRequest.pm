package AnyEvent::Net::Amazon::S3::HTTPRequest;

# ABSTRACT: Create a signed HTTP::Request
our $VERSION = 'v0.04.0.80'; # VERSION

use strict;
use warnings;

use Module::AnyEvent::Helper::Filter -as => __PACKAGE__,
        -target => substr(__PACKAGE__, 10),
        -transformer => 'Net::Amazon::S3';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Net::Amazon::S3::HTTPRequest - Create a signed HTTP::Request

=head1 VERSION

version v0.04.0.80

=head1 SYNOPSIS

  my $http_request = AnyEvent::Net::Amazon::S3::HTTPRequest->new(
    s3      => $self->s3,
    method  => 'PUT',
    path    => $self->bucket . '/',
    headers => $headers,
    content => $content,
  )->http_request;

=head1 DESCRIPTION

This module creates an HTTP::Request object that is signed
appropriately for Amazon S3,
and the same as L<Net::Amazon::S3::HTTPRequest>,
except for its name.

=head1 METHODS

=head2 http_request

This method creates, signs and returns a HTTP::Request object.

=head2 query_string_authentication_uri

This method creates, signs and returns a query string authentication
URI.

=for test_synopsis no strict 'vars';

=head1 AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
