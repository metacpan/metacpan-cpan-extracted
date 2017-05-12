package App::Zapzi::Roles::Transformer;
# ABSTRACT: role definition for transformer modules


use utf8;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use Carp;
use App::Zapzi::FetchArticle;
use Moo::Role;


has input => (is => 'ro', isa => sub
              {
                  croak 'Source must be an App::Zapzi::FetchArticle'
                      unless ref($_[0]) eq 'App::Zapzi::FetchArticle';
              });


has readable_text => (is => 'rwp', default => '');


has title => (is => 'rwp', default => '');



requires qw(name handles transform);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Zapzi::Roles::Transformer - role definition for transformer modules

=head1 VERSION

version 0.017

=head1 DESCRIPTION

This defines the transformer role for Zapzi. Transformers take
articles in their native format and transform it to 'simple HTML' for
consumption by an eReader.

=head1 ATTRIBUTES

=head2 input

Object of type App::Zapzi::FetchArticle to get original text from.

=head2 readable_text

Holds the readable text of the article

=head2 title

Title extracted from the article

=head1 REQUIRED METHODS

=head2 name

Name of transformer visible to user.

=head2 handles($content_type)

Returns true if this implementation handles the specified
content_type, eg 'text/html'.

=head2 transform

Transform input to readable text and title.

=head1 AUTHOR

Rupert Lane <rupert@rupert-lane.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rupert Lane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
