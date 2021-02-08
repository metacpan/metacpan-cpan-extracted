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

our $VERSION = "1.96";

#----------------------------------------------------------------------
# Read the default parameter values

sub parameters {
    my ($self) = @_;

    return (
            package => '',
            pod_directory => '',
            final_directory => '',
            extension => 'pm,pod',
            title_template => '<h2></h2>',
           );
}

#----------------------------------------------------------------------
# Alter urls in body of pod file to corect final location

sub alter_url {
    my ($self, $url) = @_;

    my $site_url = $self->get_site_url();
    $url =~ s/^$site_url//;

    my @podfile_path = split(/::/, $url);
    my $podfile = pop(@podfile_path);

    my $filename = catfile($self->{pod_directory}, 
                           @podfile_path, $podfile);

    my $found;
    foreach my $ext ('pod', 'pm', 'pl') {
        if (-e "$filename.$ext") {
            $podfile = lc("$podfile.$ext");
            $found = 1;
            last;
        }
    }

    if ($found) {
        $filename = catfile($self->{pod_directory}, 
                           @podfile_path, $podfile);

        $url = $self->filename_to_url($self->{top_directory}, 
                                      $filename,
                                      $self->{web_extension});
    } else {
        $url = '';
    }

    return $url;
}

#----------------------------------------------------------------------
# Extract the content between body tags in a web page

sub extract_body {
    my ($self, $html) = @_;

    my @section = split(/<\s*\/?body[^>]*>/i, $html);
    s/^\s+// foreach @section;
    
    my $body = $section[1];

    $body =~ s/src="([^"]*)"/'src="' . $self->alter_url($1) . '"'/ge;
    $body =~ s/href="([^"]*)"/'href="' . $self->alter_url($1) . '"'/ge;

    return $body;
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
                       'summary' => 'description',
                       'author' => 'author',
                       );

        while (my ($cname, $sname) = each %mapping) {
            $content{$cname} = $section->{$sname};
        }

        foreach my $cname (qw(author title)) {
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
# Convert filename to url

sub filename_to_url {
    my ($self, $directory, $filename, $ext) = @_;

    $filename = rel2abs($filename);
    $filename = lc(abs2rel($filename, $self->{base_directory}));
    $filename = catfile($self->{final_directory}, $filename);
    $filename = fio_shorten_path($filename) if $filename =~ /\.\./;

    return $self->SUPER::filename_to_url($directory, $filename, $ext);
}

#----------------------------------------------------------------------
# Find the directory containing the pod files

sub find_pod_directory {
    my ($self)= @_;

    my @package_path = split(/::/, $self->{package});
    pop(@package_path);
    my $package_folder = catfile(@package_path);

    my @folders;
    push(@folders, split(/\s*,\s*/, $self->{pod_directory}))
        if $self->{pod_directory};
    push(@folders, @INC);

    for my $pod_folder (@folders) {
        my $base_folder = catfile($pod_folder, $package_folder);
        if (-e $base_folder) {
            return ($pod_folder, $base_folder);
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

    $psx->html_h_level($h_level) 
		if $psx->can('html_h_level');

    $psx->perldoc_url_prefix($self->{site_url}) 
		if $psx->can('perldoc_url_prefix');

    return $psx;
}

#----------------------------------------------------------------------
# Initialize pod parser and find pod directory

sub setup {
    my ($self, %configuration) = @_;

    my ($pod_folder, $base_folder) = $self->find_pod_directory();
    die "Couldn't find folder for $self->{package}" 
        unless defined $pod_folder;

    $self->{final_directory} = $self->{base_directory};
    $self->{base_directory} = $base_folder;
    $self->{pod_directory} = $pod_folder;
    
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

=item pod_extension

The extension of files that contain pod documentation. The default value
is pm,pod.

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
