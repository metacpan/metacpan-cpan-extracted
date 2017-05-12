package App::Zapzi::Roles::Fetcher;
# ABSTRACT: role definition for fetcher modules


use utf8;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use Carp;
use Moo::Role;


has source => (is => 'ro', default => '');


has text => (is => 'rwp', default => '');


has content_type => (is => 'rwp', default => 'text/plain');


has error => (is => 'rwp', default => '');



requires qw(name handles fetch);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Zapzi::Roles::Fetcher - role definition for fetcher modules

=head1 VERSION

version 0.017

=head1 DESCRIPTION

This defines the fetcher role for Zapzi. Fetchers take a source, such
as a filename or URL, and return raw article text.

=head1 ATTRIBUTES

=head2 source

Pass in the source of the article - either a filename or a URL.

=head2 text

Holds the raw text of the article

=head2 content_type

MIME content type for text.

=head2 error

Holds details of any errors encountered while retrieving the article;
will be blank if no errors.

=head1 REQUIRED METHODS

=head2 name

Name of fetcher visible to user.

=head2 handles($source)

Returns true if this implementation handles the specified
article source

=head2 fetch

Fetch the article

=head1 AUTHOR

Rupert Lane <rupert@rupert-lane.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rupert Lane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
