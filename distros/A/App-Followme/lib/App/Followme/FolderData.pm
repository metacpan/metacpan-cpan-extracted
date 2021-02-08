package App::Followme::FolderData;

use 5.008005;
use strict;
use warnings;
use integer;
use lib '../..';

use Cwd;
use File::Spec::Functions qw(abs2rel catfile rel2abs splitdir);

use base qw(App::Followme::BaseData);
use App::Followme::FIO;

our $VERSION = "1.96";

#----------------------------------------------------------------------
# Read the default parameter values

sub parameters {
    my ($self) = @_;

    return (
            extension => '',
            site_url => '',
            remote_url => '',
            author => '',
            size_format => 'kb',
            date_format => 'Mon d, yyyy h:mm',
            exclude_index => 0,
            exclude => '',
            exclude_dirs => '.*,_*',
            web_extension => 'html',
           );
}

#----------------------------------------------------------------------
# Return the author's name stored in theconfiguration file

sub calculate_author {
    my ($self, $filename) = @_;
    return $self->{author};
}

#----------------------------------------------------------------------
# Calculate the creation date from the modification date

sub calculate_date {
    my ($self, $filename) = @_;
    return $self->get_mdate($filename);
}

#----------------------------------------------------------------------
# Get the list of keywords from the file path

sub calculate_keywords {
    my ($self, $filename) = @_;
    $filename = $self->dir_to_filename($filename);

    $filename = abs2rel($filename);
    my @path = splitdir($filename);
    pop(@path);

    my $keywords = pop(@path) || '';
    return $keywords;
}

#----------------------------------------------------------------------
# Calculate the title from the filename root

sub calculate_title {
    my ($self, $filename) = @_;
    $filename = $self->dir_to_filename($filename);

    my ($dir, $file) = fio_split_filename($filename);
    my ($root, $ext) = split(/\./, $file);

    if ($root eq 'index') {
        my @dirs = splitdir($dir);
        $root = pop(@dirs) || '';
    }

    $root =~ s/^\d+// unless $root =~ /^\d+$/;
    my @words = map {ucfirst $_} split(/\-/, $root);

    return join(' ', @words);
}

#----------------------------------------------------------------------
# Check that filename is defined, die if not

sub check_filename {
    my ($self, $name, $filename) = @_;

    die "Cannot use \$$name outside of loop" unless defined $filename;
    return;
}

#----------------------------------------------------------------------
# Get a filename if the directory happens to be a directory

sub dir_to_filename {
    my ($self, $directory) = @_;

    my $filename;
    if (-d $directory) {
        my $index = 'index.' . $self->{web_extension};
        $filename = catfile($directory, $index);
    } else {
        $filename = $directory;
    }

    return $filename;
}

#----------------------------------------------------------------------
# Fetch data from all its possible sources

sub fetch_data {
    my ($self, $name, $filename, $loop) = @_;

    # Look under both sets of functions

    $self->check_filename($name, $filename);
    my %data = $self->gather_data('get', $name, $filename, $loop);

    %data = (%data, $self->gather_data('calculate', $name, $filename, $loop))
            unless exists $data{$name};

    return %data;
}

#----------------------------------------------------------------------
# Convert filename to url

sub filename_to_url {
    my ($self, $directory, $filename, $ext) = @_;

    $filename = $self->dir_to_filename($filename);

    $filename = rel2abs($filename);
    $filename = abs2rel($filename, $directory);

    my @path = $filename eq '.' ? () : splitdir($filename);

    my $url = join('/', @path);
    $url =~ s/\.[^\.]*$/.$ext/ if defined $ext;

    return $url;
}

#----------------------------------------------------------------------
# Find the filename at an offset to the current filename

sub find_filename {
    my ($self, $offset, $filename, $loop) = @_;
    die "Can't use \$url_* outside of for\n"  unless $loop;

    my $match = -999;
    foreach my $i (0 .. @$loop) {
        if ($loop->[$i] eq $filename) {
            $match = $i;
            last;
        }
    }

    my $index = $match + $offset;
    if ($index < 0 || $index > @$loop-1) {
        $filename = '';
    } else {
        $filename = $loop->[$index];
    }

    return $filename;
}

#----------------------------------------------------------------------
# Build a recursive list of directories with a breadth first search

sub find_matching_directories {
    my ($self, $directory) = @_;

    my ($filenames, $subdirectories) = fio_visit($directory);

    my @directories;
    foreach my $subdirectory (@$subdirectories) {
        next unless $self->match_directory($subdirectory);
        push(@directories, $subdirectory);
    }

    foreach my $subdirectory (@directories) {
        push(@directories, $self->find_matching_directories($subdirectory));
    }

    return @directories;
}

#----------------------------------------------------------------------
# Build a list of matching files in a folder

sub find_matching_files {
    my ($self, $folder) = @_;

    my ($filenames, $folders) = fio_visit($folder);

    my @files;
    foreach my $filename (@$filenames) {
        push(@files, $filename) if $self->match_file($filename);
    }

    return @files;
}

#----------------------------------------------------------------------
# Find the newest file in a set of files

sub find_newest_file {
    my ($self, @files) = @_;

    my ($newest_file, $newest_date);
    while (@files && ! defined $newest_file) {
        $newest_file = shift(@files);
        $newest_date =fio_get_date($newest_file) if defined $newest_file;
    }

    foreach my $file (@files) {
        next unless defined $file && -e $file;

        my $date = fio_get_date($file);
        if ($date > $newest_date) {
            $newest_date = $date;
            $newest_file = $file;
        }
    }

    return $newest_file;
}

#----------------------------------------------------------------------
# Get the more recently changed files

sub find_top_files {
    my ($self, $folder, $augmented_files) = @_;

    my @files = $self->find_matching_files($folder);
    my @sorted_files = $self->sort_with_field(\@files, 'mdate', 1);

    return $self->merge_augmented($augmented_files, \@sorted_files);
}

#----------------------------------------------------------------------
# Format the file creation date

sub format_date {
    my ($self, $sorted_order, $date) = @_;

    if ($sorted_order) {
        $date = fio_format_date($date);
    } else {
        $date = fio_format_date($date, $self->{date_format});
    }

    return $date;
}

#----------------------------------------------------------------------
# Format the file modification date

sub format_mdate {
    my ($self, $sorted_order, $date) = @_;
    return fio_format_date($date);
}

#----------------------------------------------------------------------
# Make filenames sortable in a cross-os manner

sub format_name {
    my ($self, $sorted_order, $filename) = @_;

    $filename = join(' ', fio_split_filename($filename)) if $sorted_order;
    return $filename;
}

#----------------------------------------------------------------------
# Format the file size

sub format_size {
    my ($self, $sorted_order, $size) = @_;

    if ($sorted_order) {
        $size = sprintf("%012d", $size);

    } else {
        if ($self->{size_format}) {
            my $byte_size = $size;
            my $fmt = lc($self->{size_format});

            foreach my $format (qw(b kb mb gb)) {
                if ($fmt eq $format) {
                    undef $fmt;
                    last;
                }
                $byte_size /= 1024;
            }

            $size = join('', int($byte_size), $self->{size_format})
                    unless $fmt;
        }
    }

    return $size;
}

#----------------------------------------------------------------------
# Get the  absolute url from a filename and the site url

sub get_absolute_url {
    my ($self, $filename) = @_;
    $filename = $self->dir_to_filename($filename);

    my $site_url = $self->get_site_url($filename);
    my $relative_url =  $self->get_url($filename);
    my $absolute_url = "$site_url/$relative_url";

    return $absolute_url;
}

#----------------------------------------------------------------------
# Get a list of matching files in a folder and its subfolders

sub get_all_files {
    my ($self, $filename) = @_;

    my ($folder) = fio_split_filename($filename);
    my @files = $self->find_matching_files($folder);

    my @folders = $self->find_matching_directories($folder);
    foreach my $subfolder (@folders) {
        push(@files, $self->find_matching_files($subfolder));
    }

    return \@files;
}

#----------------------------------------------------------------------
# Get a list of breadcrumb filenames

sub get_breadcrumbs {
    my ($self, $filename) = @_;

    my @path = splitdir(abs2rel($filename, $self->{top_directory}));
    pop(@path);

    my @breadcrumbs;
    for (;;) {
        my $dir = @path ? catfile($self->{top_directory}, @path)
                        : $self->{top_directory};

        my $breadcrumb = $self->dir_to_filename($dir);
        push (@breadcrumbs, $breadcrumb);

        last unless @path;
        pop(@path);
    }

    @breadcrumbs = reverse(@breadcrumbs);
    return \@breadcrumbs;
}

#----------------------------------------------------------------------
# Get the extension from a filename

sub get_extension {
    my ($self, $filename) = @_;

    my ($folder, $file) = fio_split_filename($filename);
    my ($extension) = ($file =~ /\.([^\.]*)$/);

    return $extension;
}


#----------------------------------------------------------------------
# Get a list of matching files in a folder

sub get_files {
    my ($self, $filename) = @_;

    my ($folder) = fio_split_filename($filename);
    my @files = $self->find_matching_files($folder);
    return \@files;
}

#-----------------------------------------------------------------------
# Get a list of matching directories

sub get_folders {
    my ($self, $filename) = @_;

    my ($folder) = fio_split_filename($filename);
    my ($filenames, $subfolders) = fio_visit($folder);

    my @folders;
    foreach my $subfolder (@$subfolders) {
        next unless $self->match_directory($subfolder);
        push(@folders, $subfolder);
    }

    return \@folders;
}

#-----------------------------------------------------------------------
# Get the url of the index page in the same folder as a file

sub get_index_url {
    my ($self, $filename) = @_;

    my ($dir, $file) = fio_split_filename($filename);
    my $index_page = "index.$self->{web_extension}";
    $index_page = catfile($dir, $index_page);

    return $self->get_url($index_page);
}

#----------------------------------------------------------------------
# Set a flag indicating if the the filename is the index file

sub get_is_index {
    my ($self, $filename) = @_;

    my ($folder, $file) = fio_split_filename($filename);
    my ($root, $ext) = split(/\./, $file);

    my $is_index = $root eq 'index' && $ext eq $self->{web_extension};
    return $is_index ? 1 : 0;
}

#----------------------------------------------------------------------
# Get the modification time in epoch seconds

sub get_mdate {
    my ($self, $filename) = @_;

    return fio_get_date($filename);
}

#----------------------------------------------------------------------
# Get the most recently modified file in a folder and its subfolders

sub get_newest_file {
    my ($self, $filename) = @_;

    my ($folder) = fio_split_filename($filename);
    my @files = $self->find_matching_files($folder);

    my $newest_file = $self->find_newest_file(@files);
    my @folders = $self->find_matching_directories($folder);

    foreach my $subfolder (@folders) {
        @files = $self->find_matching_files($subfolder);
        $newest_file = $self->find_newest_file($newest_file, @files);
    }

    return defined $newest_file ? [$newest_file] : [];
}

#----------------------------------------------------------------------
# Get a list of files with the same rootname as another filename

sub get_related_files {
    my ($self, $filename) = @_;
    my ($folder, $file) = fio_split_filename($filename);

    my $root;
    ($root = $file) =~ s/\.[^\.]*$//;

    my @related_files;
    my ($filenames, $folders) = fio_visit($folder);
    foreach my $filename (@$filenames) {
        my ($folder, $file) = fio_split_filename($filename);

        my $rootname;
        ($rootname = $file) =~ s/\.[^\.]*$//;
        push(@related_files, $filename) if $root eq $rootname;
    }

    return \@related_files;
}

#----------------------------------------------------------------------
# Get the remote url from a filename and the remote url

sub get_remote_url {
    my ($self, $filename) = @_;

    my $remote_url;
    if ($self->{remote_url}) {
        my $relative_url =  $self->get_url($filename);
        $remote_url = "$self->{remote_url}/$relative_url";

    } else {
        $remote_url = $self->get_absolute_url($filename);
    }

    return $remote_url;
}

#----------------------------------------------------------------------
# get the site url

sub get_site_url {
    my ($self, $filename) = @_;

    my $site_url ;
    if ($self->{site_url}) {
        $site_url = $self->{site_url};

    } else {
        $site_url = 'file://' . $self->{top_directory};
    }

    $site_url =~ s/\/$//;
    return $site_url;
}

#----------------------------------------------------------------------
# Get the file size

sub get_size {
    my ($self, $filename) = @_;

    return fio_get_size($filename);
}

#----------------------------------------------------------------------
# Get a list of matching files in a directory and its subdirectories

sub get_top_files {
    my ($self, $filename) = @_;

    my $augmented_files = [];
    my ($folder) = fio_split_filename($filename);
    $augmented_files = $self->find_top_files($folder, $augmented_files);

    my @directories = $self->find_matching_directories($folder);

    foreach my $subfolder (@directories) {
        $augmented_files = $self->find_top_files($subfolder,
                                                 $augmented_files);
    }

    my @top_files = $self->strip_augmented(@$augmented_files);
    return \@top_files;
}

#----------------------------------------------------------------------
# Get a url from a filename

sub get_url {
    my ($self, $filename) = @_;
    $filename = $self->dir_to_filename($filename);

    return $self->filename_to_url($self->{top_directory},
                                  $filename,
                                  $self->{web_extension});
}

#----------------------------------------------------------------------
# Get a url with no extension from a filename

sub get_url_base {
    my ($self, $filename) = @_;
    $filename = $self->dir_to_filename($filename);

    my $url_base =  $self->filename_to_url($self->{top_directory},
										   $filename, '');
	chop($url_base); # remove trailing dot
	return $url_base;
}

#----------------------------------------------------------------------
# Get a url from the next filename in the loop

sub get_url_next {
    my ($self, $filename, $loop) = @_;

    $filename = $self->find_filename(1, $filename, $loop);
    return $filename ? $self->get_url($filename) : '';
}

#----------------------------------------------------------------------
# Get a url from the previous filename in the loop

sub get_url_previous {
    my ($self, $filename, $loop) = @_;

    $filename = $self->find_filename(-1, $filename, $loop);
    return $filename ? $self->get_url($filename) : '';
}

#----------------------------------------------------------------------
# Return true if this is an included directory

sub match_directory {
    my ($self, $directory) = @_;

    $self->{exclude_dir_patterns} ||= fio_glob_patterns($self->{exclude_dirs});

    return if $self->match_patterns($directory, $self->{exclude_dir_patterns});
    return 1;
}

#----------------------------------------------------------------------
# Return true if this is an included file

sub match_file {
    my ($self, $filename) = @_;

    my ($dir, $file) = fio_split_filename($filename);

    if ($self->{exclude_index}) {
        my $index_file = join('.', 'index', $self->{web_extension});
        return if $file eq $index_file;
    }

    my @patterns = map {"*.$_"} split(/\s*,\s*/, $self->{extension});
    my $patterns = join(',', @patterns);

    $self->{include_file_patterns} ||= fio_glob_patterns($patterns);
    $self->{exclude_file_patterns} ||= fio_glob_patterns($self->{exclude});

    return if $self->match_patterns($file, $self->{exclude_file_patterns});
    return unless $self->match_patterns($file, $self->{include_file_patterns});
    return 1;
}

#----------------------------------------------------------------------
# Return true if filename matches pattern

sub match_patterns {
    my ($self, $file, $patterns) = @_;

    my @path = splitdir($file);
    $file = pop(@path);

    foreach my $pattern (@$patterns) {
        return 1 if $file =~ /$pattern/;
    }

    return;
}

#----------------------------------------------------------------------
# Initialize the configuration parameters

sub setup {
    my ($self, %configuration) = @_;

    # Set filename extension if unset
    $self->{extension} ||= $self->{web_extension};

    # Remove any trailing slash from urls
    foreach my $url (qw(remote_url site_url)) {
        next unless $self->{$url};
        $self->{$url} =~ s/\/$//;
    }

    return;
}

1;

=pod

=encoding utf-8

=head1 NAME

App::Followme::FolderData - Build metadata from folder information

=head1 SYNOPSIS

    use Cwd;
    use App::Followme::FolderData;
    my $directory = cwd();
    my $data = App::Followme::FolderData->new(directory => $directory);
    @filenames = $data->get_files();
    foreach my $filename (@filename) {
        print "$filename\n";
    }

=head1 DESCRIPTION

This module contains the methods that build metadata values that can be computed
from properties of the file system, that is, without opening a file or
without regard to the type of file. It serves as the base of all the metadata
classes that build metadata for specific file types.

=head1 METHODS

All data are accessed through the build method.

=over 4

=item my %data = $obj->build($name, $filename);

Build a variable's value. The first argument is the name of the variable. The
second argument is the name of the file the metadata is being computed for. If
it is undefined, the filename in the object
is used.

=back

=head1 VARIABLES

The folder metadata class can evaluate the following variables. When passing
a name to the build method, the sigil should not be used.

=over 4

=item @all_files

A list of matching files in a directory and its subdirectories.

=item @top_files

A list of the most recently created files in a directory and its
subdirectory. The length of the list is determined by the 
configuration parameter list_length. 

=item @breadcrumbs

A list of breadcrumb filenames, which are the names of the index files
above the filename passed as the argument.

=item @related_files

A list of files with the same file root name as a specified file. This
list is not filtered by the configuration variables extension and exclude.

=item @files

A list of matching files in a directory.

=item @folders

A list of folders under the default folder that contain an index file.

=item $author

The name of the author of a file

=item $absolute_url

The absolute url of a web page from a filename.

=item $date

A date string built from the creation date of the file. The date is
built using the template in date_format which contains the fields:
C<weekday, month,day, year, hour,  minute,> and C<second.>

=item $mdate

A date string built from the modification date of the file. The date is
built using the template in date_format which contains the fields:
C<weekday, month,day, year, hour,  minute,> and C<second.>

=item $is_current

One if the filename matches the default filename, zero if it does not.

=item $is_index

One of the filename is an index file and zero if it is not.

=item $keywords

A list of keywords describing the file from the filename path.

=item $remote_url

The remote url of a web page from a filename.

=item $site_url

The url of the website. Does not have a trailing slash

=item $index_url

The url of the index page in the same folder as a file.

=item $title

The title of a file is derived from the file name by removing the filename
extension, removing any leading digits,replacing dashes with spaces, and
capitalizing the first character of each word.

=item $url

Build the relative url of a web page from a filename.

=item $url_base

Build the relative url of a filename minus any extension and trailing dot

=item $extension

The extension of a filename.

=item $url_next

Build the relative url of a web page from the next filename in the loop 
sequence. Empty string if there is no next filename.

=item $url_previous

Build the relative url of a web page from the previous filename in the loop 
sequence. Empty string if there is no previous filename.

=back

=head1 CONFIGURATION

The following fields in the configuration file are used in this class and every
class based on it:

=over 4

=item filename

The filename used to retrieve metatdata from if no filename is passed to the
build method.

=item directory

The directory used to retrieve metadata. This is used by list valued variables.

=item extension

A comma separated list of extensions of files to include in a list of files.
If it is left empty, it is set to the web extension.

=item date_format

The format used to produce date strings. The format is described in the
POD for Time::Format.

=item remote_url

The url of the remote website, e.g. http://www.cloudhost.com.

=item site_url

The url of the local website, e.g. http://www.example.com.

=item sort_numeric

If one, use numeric comparisons when sorting. If zero, use string comparisons
when sorting.

=item exclude_index

If the value of this variable is true (1) exclude the index page in the list
of files. If it is false (0) include the index page. The default value is 0.

=item exclude

The files to exclude when traversing the list of files. Leave as a zero length
string if there are no files to exclude.

=item exclude_dirs

The directories excluded while traversing the list of directories. The default
value of this parameter is '.*,_*',

=item web_extension

The extension used by web pages. This controls which files are returned. The
default value is 'html'.

=back

=head1 LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernie Simon E<lt>bernie.simon@gmail.comE<gt>

=cut
