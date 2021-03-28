package App::Followme::FileData;

use 5.008005;
use strict;
use warnings;
use integer;
use lib '../..';


use base qw(App::Followme::FolderData);
use App::Followme::FIO;
use App::Followme::NestedText;
use App::Followme::Web;

our $VERSION = "2.02";

#----------------------------------------------------------------------
# Read the default parameter values

sub parameters {
    my ($self) = @_;

    return (
            base_directory => '',
            title_template => '',
           );
}

#----------------------------------------------------------------------
# Convert content represented in html format (stub)

sub fetch_as_html {
    my ($self, $content_block) = @_;
    return $content_block;
}

#----------------------------------------------------------------------
# Parse content as html to get fallback values for data

sub fetch_content {
    my ($self, $content_block) = @_;

    # Content within title template is title, rest of content is body

    my $metadata = [];
    my $global = 0;
    my $body;


    if ($self->{title_template}) {

        my $title_parser = sub {
            my ($metadata, @tokens) = @_;
            my $text = web_only_text(@tokens);
            push(@$metadata, 'title', $text);
            return '';
        };

        $body = web_substitute_tags($self->{title_template},
                                    $content_block,
                                    $title_parser,
                                    $metadata,
                                    $global
                                    );
    } else {
        $body = $content_block;
    }

    $body =~ s/^\s+//;
    push(@$metadata, 'body', $body);
    my %content = @$metadata;

    my $paragraph_parser = sub {
        my ($paragraph, @tokens) = @_;
        $$paragraph = web_only_text(@tokens);
        return;
    };

    my $paragraph;
    if (web_match_tags('<p></p>',
                       $body,
                       $paragraph_parser,
                       \$paragraph,
                       $global)) {

        # Description is first sentence of first paragraph
        $paragraph =~ /([^.!?\s][^.!?]*(?:[.!?](?!['"]?\s|$)[^.!?]*)*[.!?]?['"]?(?=\s|$))/;
        $content{description} = $1;
        $content{summary} = $paragraph;
    }

    return %content;
}

#----------------------------------------------------------------------
# Fetch data from all its possible sources

sub fetch_data {
    my ($self, $name, $filename, $loop) = @_;

    # Check to see if you can get data without opening file
    $self->check_filename($name, $filename);
    my %data = $self->gather_data('get', $name, $filename, $loop);

    # Then open the file and try to read the data from it
    %data = ($self->fetch_from_file($filename), %data)
            unless exists $data{$name};

    # If not found in the file, calculate from other fields
    %data = (%data, $self->gather_data('calculate', $name, $filename, $loop))
            unless exists $data{$name};

    return %data;
}

#----------------------------------------------------------------------
# Look in the file for the data

sub fetch_from_file {
    my ($self, $filename) = @_;

    my (%metadata, %content);
    my $text = fio_read_page($filename);
    return () unless length $text;

    my $section = $self->fetch_sections($text);

    # First look in the metadata and then the content
    %metadata = $self->fetch_metadata($section->{metadata});
    %content = $self->fetch_content($section->{body});

    return (%content, %metadata);
}

#----------------------------------------------------------------------
# Fetch metadata directly from file

sub fetch_metadata {
    my ($self, $metadata_block) = @_;

    my %metadata = nt_parse_almost_yaml_string($metadata_block);
    return %metadata;
}

#----------------------------------------------------------------------
# Split text into metadata and content sections

sub fetch_sections {
    my ($self, $text) = @_;

    my %section;
    my $divider = qr(-{3,}\s*\n);

    if ($text =~ /^$divider/) {
        my @sections = split($divider, $text, 3);
        $section{body} = $sections[2];
        $section{metadata} = $sections[1];

    } else {
        $section{body} = $text;
        $section{metadata} = '';
    }

    die "Could not fetch body of text\n" unless $section{body};
    $section{body} = $self->fetch_as_html($section{body});
    return \%section;
}

#----------------------------------------------------------------------
# Return author's name in sortable order

sub format_author {
    my ($self, $sorted_order, $author) = @_;

    if ($sorted_order) {
        $author = lc($author);

        # no need to sort if last name is first
        if ($author !~ /^\w+,/) {
            # put last name first
            $author =~ s/[^\w\s]//g;
            my @names = split(' ', $author);
            my $name = pop(@names);
            unshift(@names, $name);

            $author =  join(' ', @names);
        }
    }

    return $author;
}

#----------------------------------------------------------------------
# Return title in sortable order

sub format_title {
    my ($self, $sorted_order, $title) = @_;

    if ($sorted_order) {
        $title = lc($title);
        $title =~ s/^a\s+//;
        $title =~ s/^the\s+//;
    }

    return $title;
}

#----------------------------------------------------------------------
# Return the base directory defined in this object

sub get_base_directory {
    my ($self) = @_;
    return $self->{base_directory};
}

1;

=pod

=encoding utf-8

=head1 NAME

App::Followme::FileData

=head1 SYNOPSIS

    use App::Followme::FileData;
    my $data = App::Followme::FileData->new();
    my $html = App::Followme::Template->new('example.htm', $data);

=head1 DESCRIPTION

This module extracts data from a file. It assumes the file is a text 
file with the metadata in a nested text block preceding a content block 
that is in html format or convertible to html format. The two sections 
are separated by a line of three or more dots. These asumptions can be 
overriden by overriding the methods in the class. Like the other data 
classes, this class is normally called by the Template class and not 
directly by user code.

=head1 METHODS

All data classes are first instantiated by calling new and the object
created is passed to a template object. It calls the build method with an
argument name to retrieve that data item, though for the sake of
efficiency, all the data are read from the file at once.

=head1 VARIABLES

The file metadata class can evaluate the following variables. When passing
a name to the build method, the sigil should not be used.

=over 4

=item $body

The main content of the file.

=item $description

A one sentence description of the file contents

=item $date

The creation date of a file. The display format is controlled by the
configuration variable, data_format

=item $summary

A summary of the file's contents, by default the first paragraph.

=item $title

The title of the file, either derived from the content or the file metadata.

=back

=head1 CONFIGURATION

This class has the following configuration variable:

=over 4

=item base_directory

The top directory containing the files to be processed

=item title_template

A set of html tags that bound the title in the file's contents. The default
value is "<h1></h1>".

=back

=head1 LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernie Simon E<lt>bernie.simon@gmail.comE<gt>

=cut
