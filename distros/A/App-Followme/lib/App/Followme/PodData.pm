package App::Followme::PodData;

use 5.008005;
use strict;
use warnings;
use integer;
use lib '../..';

use base qw(App::Followme::FileData);

use Pod::Simple::XHTML;
use File::Spec::Functions qw(abs2rel catfile rel2abs splitdir);

use App::Followme::FIO;
use App::Followme::Web;

our $VERSION = "1.92";

#----------------------------------------------------------------------
# Read the default parameter values

sub parameters {
    my ($self) = @_;

    return (
            extension => 'pm,pod',
            title_template => '<h2></h2>',
            package => '',
            pod_directory => '',
           );
}

#----------------------------------------------------------------------
# Extract the content between body tags in a web page

sub extract_body {
    my ($self, $html) = @_;

    my @section = split(/<\s*\/?body[^>]*>/i, $html);
    s/^\s+// foreach @section;

    return $section[1];
}

#----------------------------------------------------------------------
# Parse content as html to get values for data

sub fetch_content {
    my ($self, $content_block) = @_;

    my %content;
    $content{body} = $content_block;

    if ($self->{title_template}) {
        my $title_parser = sub {
                my $title = web_only_text(@_);
                $title =~ s/\s+/_/g;
                return lc($title);
            };

        my $section = web_titled_sections($self->{title_template},
                                          $content_block,
                                          $title_parser);

        my %mapping = ('title' => 'name',
                       'description' => 'description',
                       'summary' => 'description',
                       );

        while (my ($cname, $sname) = each %mapping) {
            $content{$cname} = $section->{$sname};
        }

        foreach my $cname (qw(title)) {
            my @tokens = web_split_at_tags($content{$cname});
            $content{$cname} = web_only_text(@tokens);
        }
    }


    return %content;
}

#----------------------------------------------------------------------
# Convert Pod into html

sub fetch_as_html {
    my ($self, $text) = @_;

    my $psx = $self->initialize_parser();

    my $html;
    $psx->output_string(\$html);
    $psx->parse_string_document($text);
    return $self->extract_body($html);
}

#----------------------------------------------------------------------
# Split into text from file into section blocks.

sub fetch_sections {
    my ($self, $text) = @_;

    my %section;
    $section{body} = $self->fetch_as_html($text);
    $section{metadata} = '';

    return \%section;
}

#----------------------------------------------------------------------
# Find the directory containing the pod files

sub find_pod_directory {
    my ($self)= @_;

    my @package_path = split(/::/, $self->{package});
    pop(@package_path);

    my $package_folder = catfile(@package_path);
    my @folders = (split(/\s*,\s*/, $self->{pod_directory}), @INC);

    for my $folder (@folders) {
        my $pod_folder = catfile($folder, $package_folder);
        if (-e $pod_folder) {
            return $pod_folder;
        }
    }

    return;
}

#----------------------------------------------------------------------
# Initialize the pod parser

sub initialize_parser {
    my ($self) = @_;

    my ($h_level) = $self->{title_template} =~ /(\d+)/;
    $h_level = 1 unless defined $h_level;

    my $psx = Pod::Simple::XHTML->new();

    $psx->html_encode_chars('&<>"');
    $psx->html_h_level($h_level);
    $psx->perldoc_url_prefix($self->{site_url});

    return $psx;
}

#----------------------------------------------------------------------
# Initialize pod parser and find pod directory

sub setup {
    my ($self, %configuration) = @_;

    my $directory = $self->find_pod_directory();
    die "Couldn't find folder for $self->{package}" unless defined $directory;
    $self->{base_directory} = $directory;

    return;
}

1;
__END__
=encoding utf-8

=head1 NAME

App::Followme::PodData - Convert Pod files to html

=head1 SYNOPSIS

    use App::Followme::PodData;
    my $data = App::Followme::PodData->new();
    my $html = App::Followme::Template->new('example.htm', $data);

=head1 DESCRIPTION

This module converts Perl files with POD markup into html and extracts the
metadata from the html.

=head1 METHODS

All data are accessed through the build method.

=over 4

=item my %data = $obj->build($name, $filename);

Build a variable's value. The first argument is the name of the variable. The
second argument is the name of the file the metadata is being computed for. If
it is undefined, the filename stored in the object is used.

=back

=head1 VARIABLES

The Pod metadata class can evaluate the following variables. When passing
a name to the build method, the sigil should not be used.

=over 4

=item $body

All the contents of the file, minus the title if there is one. Markdown is
called on the file's content to generate html before being stored in the body
variable.

=item $description

A one line sentence description of the content.

=item $title

The title of the page is derived from contents of the top header tag, if one is
at the front of the file content, or the filename, if it is not.

=back

=head1 CONFIGURATION

The following parameters are used from the configuration:

=over 4

=item extension

The extension of files that are converted to web pages. The default value
is pod.

=item pod_directory

The directory containing the pod files

=back

=head1 LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernie Simon E<lt>bernie.simon@gmail.comE<gt>

=cut
