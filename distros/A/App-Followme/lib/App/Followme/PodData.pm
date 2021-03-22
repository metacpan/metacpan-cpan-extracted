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

our $VERSION = "2.01";

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

    my $site_url = $self->get_site_url($url);

    my $package;
    if ($site_url eq substr($url, 0, length($site_url))) {
        $package = substr($url, length($site_url));
    } else {
        $package = $url;
    }

    $package =~ s/^$self->{package}:://;
    my @package_path = split(/::/, $package);

    my $filename = catfile($self->{base_directory}, @package_path);

    my $found;
    foreach my $ext ('pod', 'pm', 'pl') {
        if (-e "$filename.$ext") {
            $filename .= ".$ext";
            $found = 1;
            last;
        }
    }

    if ($found) {
        $url = $self->filename_to_url($self->{top_directory}, 
                                      $filename,
                                      $self->{web_extension});
    } else {
        $url = '';
    }

    return $url;
}

#-----------------------------------------------------------------------
# Get the name of the web file a file will be converted to

sub convert_filename {
    my ($self, $filename) = @_;

    die "Base directory is undefined" unless $self->{base_directory};

    my $new_file = abs2rel($filename, $self->{base_directory});
    $new_file = join('-', splitdir(lc($new_file)));

    $new_file =~ s/\.[^\.]*$/.$self->{web_extension}/;
    $new_file = catfile($self->{final_directory}, $new_file);

    return $new_file;
}

#-----------------------------------------------------------------------
# Get the name of the source directory for ConvertPage

sub convert_source_directory {
    my ($self, $directory) = @_;

    die "Base directory is undefined" unless $self->{base_directory};

    my $source_directory;
    if (fio_same_file($directory, $self->{final_directory},
                      $self->{case_sensitivity})) {
        $source_directory = $self->{base_directory};
    }

    return $source_directory;
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

    if ($content{title}) {
        my @title_parts = split(/\s+-+\s+/, $content{title}, 2);
        $content{title} = $title_parts[0];
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

    $filename = $self->convert_filename($filename);
    return $self->SUPER::filename_to_url($directory, $filename, $ext);
}

#----------------------------------------------------------------------
# Find the directory containing the pod files

sub find_base_directory {
    my ($self)= @_;

    my @package_path = split(/::/, $self->{package});
    my $package_folder = catfile(@package_path);
    my $package_file = "$package_folder.pm";

    my @folders;
    push(@folders, split(/\s*,\s*/, $self->{pod_directory}))
        if $self->{pod_directory};
    push(@folders, @INC);

    for my $folder (@folders) {
        if (-e catfile($folder, $package_file)) {
            pop(@package_path);
            return ($folder, \@package_path);

        } elsif(-e catfile($folder, $package_folder)) {
            return ($folder, \@package_path);
        }
    }

    return;
}

#----------------------------------------------------------------------
# Treat all pod files as if they were in a single directory

sub find_matching_directories {
    my ($self, $directory) = @_;

    my @directories = ();
    return @directories;
}

#----------------------------------------------------------------------
# Treat all pod files as if they were in a single directory

sub find_matching_files {
    my ($self, $folder) = @_;

    my ($filenames, $folders) = fio_visit($folder);

    my @files;
    foreach my $filename (@$filenames) {
        push(@files, $filename) if $self->match_file($filename);
    }

    foreach my $folder (@$folders) {
        push(@files, $self->find_matching_files($folder)) 
            if $self->match_directory($folder);
    }

    return @files;
}

#-----------------------------------------------------------------------
# Treat all pod files as if they were in a single directory

sub get_folders {
    my ($self, $filename) = @_;

    my ($directory, $file) = fio_split_filename($filename);
    my @directories = $self->find_matching_directories($directory);

    return \@directories;
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
    my ($self) = @_;

    my  ($pod_folder, $package_path) = $self->find_base_directory();
    die "Couldn't find folder for $self->{package}" 
        unless defined $pod_folder;

    $self->{final_directory} = $self->{base_directory};
    $self->{base_directory} = catfile($pod_folder, @$package_path);
    $self->{package} = join('::', @$package_path);

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

All the contents of the file, minus the title if there is one. 
Pod::Simple::XHTML is called on the file's content to generate html 
before being stored in the body variable.

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
