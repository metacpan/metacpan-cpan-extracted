package App::Zapzi::Fetchers::File;
# ABSTRACT: fetch article from a file


use utf8;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use Carp;
use File::MMagic 1.30;
use Cwd;
use Moo;

with 'App::Zapzi::Roles::Fetcher';


sub name
{
    return 'File';
}


sub handles
{
    my $self = shift;
    my $source = shift;

    return (-r $source && -s $source) ? Cwd::realpath($source) : undef;
}


sub fetch
{
    my $self = shift;

    my $file;
    if (! open $file, '<', $self->source)
    {
        $self->_set_error("Failed to open " . $self->source . ": $!");
        return;
    }

    my $file_text;
    while (<$file>)
    {
        $file_text .= $_;
    }
    $self->_set_text($file_text);

    close $file;

    my $content_type;

    # Try extension first
    $content_type = 'text/plain' if $self->source =~ /\.(txt|md|mkdn)$/;
    $content_type = 'text/html' if $self->source =~ /\.(html)$/;
    $content_type = 'text/pod' if $self->source =~ /\.(pm|pl)$/;

    # Try file magic
    $content_type //= File::MMagic->new()->checktype_contents($self->text);

    # Default to plain text
    $content_type //= 'text/plain';

    $self->_set_content_type($content_type);

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Zapzi::Fetchers::File - fetch article from a file

=head1 VERSION

version 0.017

=head1 DESCRIPTION

This class reads an article from a local file.

=head1 METHODS

=head2 name

Name of transformer visible to user.

=head2 handles($content_type)

Returns a valid filename if this module handles the given content-type

=head2 fetch

Downloads an article

=head1 AUTHOR

Rupert Lane <rupert@rupert-lane.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rupert Lane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
