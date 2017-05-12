package App::Zapzi::Fetchers::POD;
# ABSTRACT: fetch article from a named POD module


use utf8;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use Carp;
use Path::Tiny;
use Pod::Find;
use Moo;

with 'App::Zapzi::Roles::Fetcher';


sub name
{
    return 'POD';
}


sub handles
{
    my $self = shift;
    my $source = shift;

    return Pod::Find::pod_where({ -inc => 1 }, $source);
}


sub fetch
{
    my $self = shift;

    my $pod = path($self->source)->slurp;
    $self->_set_text($pod);

    $self->_set_content_type('text/pod');

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Zapzi::Fetchers::POD - fetch article from a named POD module

=head1 VERSION

version 0.017

=head1 DESCRIPTION

This class reads POD from a given module name, eg 'Foo::Bar'

=head1 METHODS

=head2 name

Name of transformer visible to user.

=head2 handles($content_type)

Returns a valid filename if this module handles the given content-type.
For POD this means it will search C<@INC> for a matching file.

=head2 fetch

Reads the POD file into the application.

=head1 AUTHOR

Rupert Lane <rupert@rupert-lane.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rupert Lane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
