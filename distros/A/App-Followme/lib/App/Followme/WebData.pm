package App::Followme::WebData;

use 5.008005;
use strict;
use warnings;
use integer;
use lib '../..';

use base qw(App::Followme::FileData);
use App::Followme::FIO;
use App::Followme::Web;

our $VERSION = "1.92";

#----------------------------------------------------------------------
# Read the default parameter values

sub parameters {
    my ($self) = @_;

    return (
            body_tag => 'primary',
            metadata_tag => 'meta',
            web_extension => 'html',
           );
}

#----------------------------------------------------------------------
# Get the html metadata from the page header

sub fetch_metadata {
    my ($self, $metadata_block) = @_;
    my $metadata = [];

    my $global = 0;
    my $title_parser = sub {
        my ($metadata, @tokens) = @_;
        my $text = web_only_text(@tokens);
        push(@$metadata, 'title', $text);
        return;
    };

    web_match_tags('<title></title>', $metadata_block,
                   $title_parser, $metadata, $global);

    $global = 1;
    my $metadata_parser = sub  {
        my ($metadata, @tokens) = @_;
        foreach my $tag (web_only_tags(@tokens)) {
            push(@$metadata, $tag->{name}, $tag->{content});
        }
        return;
    };

    web_match_tags('<meta name=* content=*>', $metadata_block,
                   $metadata_parser, $metadata, $global);

    my %metadata = @$metadata;
    return %metadata;
}

#----------------------------------------------------------------------
# Split text into metadata and content sections

sub fetch_sections {
    my ($self, $text) = @_;

    my $section = web_parse_sections($text);

    my %section;
    foreach my $section_name (qw(metadata body)) {
        my $tag = $self->{$section_name . '_tag'};
        die "Couldn't find $section_name\n" unless exists $section->{$tag};

        $section{$section_name} = $section->{$tag};
    }

    return \%section;
}

1;

=pod

=encoding utf-8

=head1 NAME

App::Followme::WebData - Read metadatafrom a web file

=head1 SYNOPSIS

    use App::Followme::WebData;
    my $data = App::Followme::WebData->new();
    my $html = App::Followme::Template->new('example.htm', $data);

=head1 DESCRIPTION

This module extracts data from a web page and uses it to build variables from a
template.

=head1 METHODS

All data classes are first instantiated by calling new and the object
created is passed to a template object. It calls the build method with an
argument name to retrieve that data item, though for the sake of
efficiency, all the data are read from the file at once.

=head1 VARIABLES

This class whatever values are returned in metadata section in the header
as well as the title and body extracted from the body section.

=back

=head1 CONFIGURATION

This class has the following configuration variable:

=over 4

=item body_tag

The name of the section containing the body text. The default value is
'primary'.

=item metadata_tag

The name of the section containing the metadata tags. The default value is
'meta'.

=item web_extension

The file extension of web pages. The default value is 'html'.

=back

=head1 LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernie Simon E<lt>bernie.simon@gmail.comE<gt>

=cut
