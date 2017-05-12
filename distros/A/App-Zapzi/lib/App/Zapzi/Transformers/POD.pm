package App::Zapzi::Transformers::POD;
# ABSTRACT: transform POD to HTML


use utf8;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use Pod::Html;
use Path::Tiny;
use Carp;
use Moo;

extends "App::Zapzi::Transformers::HTML";


sub name
{
    return 'POD';
}


sub handles
{
    my $self = shift;
    my $content_type = shift;

    return 1 if $content_type =~ m|text/pod|;
}


sub transform
{
    my $self = shift;

    my $tempdir = Path::Tiny->tempdir("zapzi-pod-XXXXX", TMPDIR => 1);

    # pod2html requires files for input and output
    my $infile = "$tempdir/in.pod";
    open my $infh, '>', $infile or croak "Can't open temporary file: $!";
    print {$infh} $self->input->text;
    close $infh;

    my $outfile = "$tempdir/out.html";

    my $title = path($self->input->source)->basename;

    # --quiet will supress warnings on missing links etc
    pod2html("$infile", "--quiet", "--cachedir=$tempdir",
             "--title=$title",
             "--infile=$infile", "--outfile=$outfile");
    croak('Could not transform POD') unless -s $outfile;

    my $html = path($outfile)->slurp;

    return $self->SUPER::transform($html);
}

# _extract_title and _extract_text inherited from parent

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Zapzi::Transformers::POD - transform POD to HTML

=head1 VERSION

version 0.017

=head1 DESCRIPTION

This class takes POD and returns readable HTML using pod2html

=head1 METHODS

=head2 name

Name of transformer visible to user.

=head2 handles($content_type)

Returns true if this module handles the given content-type

=head2 transform

Converts L<input> to readable text. This is done by passing the POD
through pod2html to get HTML then calling the HTML transformer.

Returns true if converted OK.

=head1 AUTHOR

Rupert Lane <rupert@rupert-lane.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rupert Lane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
