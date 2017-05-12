package App::Zapzi::Roles::Publisher;
# ABSTRACT: role definition for publisher modules


use utf8;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use Carp;
use Moo::Role;


has folder => (is => 'ro', required => 1);


has encoding => (is => 'rwp', required => 1);


has collection_title => (is => 'ro', required => 1);


has filename => (is => 'ro', required => 1);


has collection_data => (is => 'rwp');





requires qw(name start_publication add_article finish_publication);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Zapzi::Roles::Publisher - role definition for publisher modules

=head1 VERSION

version 0.017

=head1 DESCRIPTION

This defines the publisher role for Zapzi. Publishers take a folder
and create an eBook or collection file containing articles in the
folder.

=head1 ATTRIBUTES

=head2 folder

Folder of articles to publish.

=head2 encoding

Encoding to use when publishing.

=head2 collection_title

Title of collection, eg eBook name.

=head2 filename

File that the published ebook is stored in.

=head2 collection_data

Returns the raw data (eg combined HTML) produced by the publisher -
for testing.

=head1 REQUIRED METHODS

=head2 name

Name of publisher visible to user.

=head2 start_publication($folder, $encoding)

Starts a new publication for the given folder in the given encoding.

=head2 add_article($article)

Adds an article to the publication.

=head2 finish_publication()

Finishes publication and returns the filename created.

=head1 AUTHOR

Rupert Lane <rupert@rupert-lane.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rupert Lane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
