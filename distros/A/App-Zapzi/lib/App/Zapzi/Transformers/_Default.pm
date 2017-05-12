package App::Zapzi::Transformers::_Default;
# ABSTRACT: default text transformer


use utf8;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use Carp;
use Encode;
use Text::Markdown;
use Moo;

extends 'App::Zapzi::Transformers::TextMarkdown';


sub name
{
    return 'Default';
}


sub handles
{
    # This is the default for any text not handled by other modules
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Zapzi::Transformers::_Default - default text transformer

=head1 VERSION

version 0.017

=head1 DESCRIPTION

This module is the default choice where no other transformer can be
found. It calls Text::Markdown.

=head1 METHODS

=head2 name

Name of transformer visible to user.

=head2 handles($content_type)

Returns true if this module handles the given content-type

=head1 AUTHOR

Rupert Lane <rupert@rupert-lane.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rupert Lane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
