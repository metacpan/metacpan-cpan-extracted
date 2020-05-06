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

our $VERSION = "1.93";

#----------------------------------------------------------------------
# Read the default parameter values

sub parameters {
    my ($self) = @_;

    return (
            extension => '',
            site_url => '',
            author => '',
            size_format => 'kb',
            date_format => 'Mon d, yyyy h:m',
            sort_field => '',
            sort_reverse => 0,
            sort_cutoff => 5,
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
# Calculate the creation dat from the modification date

sub calculate_date {
    my ($self, $filename) = @_;
    return $self->get_mdate($filename);
}

#----------------------------------------------------------------------
# Get the list of keywords from the file path

sub calculate_keywords {
    my ($self, $filename) = @_;

    $filename = abs2rel($filename);
    my @path = splitdir($filename);
    pop(@path);

    my $keywords = @path ? join(', ', @path) : '';
    return $keywords;
}

#----------------------------------------------------------------------
# Calculate the title from the filename root

sub calculate_title {
    my ($self, $filename) = @_;

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
# Choose the file comparison routine that matches the configuration

sub file_comparer {
    my ($self, $sort_reverse) = @_;

    my $comparer;
    if ($sort_reverse) {
        $comparer = sub ($$) {$_[1]->[0] cmp $_[0]->[0]};
    } else {
        $comparer = sub ($$) {$_[0]->[0] cmp $_[1]->[0]};
    }

    return $comparer;
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
    my ($self, $folder, $sort_field, $sort_reverse, @augmented_files) = @_;

    my @filenames = $self->sort_augmented($sort_reverse,
                    $self->make_augmented($sort_field,
                    $self->find_matching_files($folder)));

    return $self->merge_augmented($sort_reverse,
                                  \@augmented_files,
                                  \@filenames);
}

#----------------------------------------------------------------------
# Change the sort order of the files to reverse mdate

sub format_all_files {
    my ($self, $sorted_order, $all_files) = @_;
    return $self->format_files($sorted_order, $all_files);
}

#----------------------------------------------------------------------
# Format the file date

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
# Change the sort order of the files to reverse mdate

sub format_files {
    my ($self, $sorted_order, $files) = @_;
    my ($sort_field, $sort_reverse);

    if ($sorted_order) {
        $sort_field = 'mdate';
        $sort_reverse = 1;
    } else {
        $sort_field = $self->{sort_field};
        $sort_reverse = $self->{sort_reverse};
    }

    @$files = $self->sort_files($sort_field, $sort_reverse, @$files);
    return $files;
}

#----------------------------------------------------------------------
# Change the sort order of the files to reverse mdate

sub format_folders {
    my ($self, $sorted_order, $folders) = @_;

    $folders = $self->format_files($sorted_order, $folders);
    return $folders if $sorted_order;

    my @folders = map {fio_to_file($_, $self->{web_extension})}
                  @$folders;

    return \@folders;
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
# Get the url from a filename

sub get_absolute_url {
    my ($self, $filename) = @_;

    my $absolute_url = '/' . $self->filename_to_url($self->{top_directory},
                                                    $filename,
                                                    $self->{web_extension}
                                                   );

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
# Get the modification date in epoch seconds

sub get_mdate {
    my ($self, $filename) = @_;

    my $date = fio_get_date($filename);
    return fio_format_date($date);
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

    return [$newest_file];
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

    my @augmented_files = ();
    my ($folder) = fio_split_filename($filename);
    @augmented_files = $self->find_top_files($folder,
                                             $self->{sort_field},
                                             $self->{sort_reverse},
                                             @augmented_files);

    my @directories = $self->find_matching_directories($folder);

    foreach my $subfolder (@directories) {
        @augmented_files = $self->find_top_files($subfolder,
                                                $self->{sort_field},
                                                $self->{sort_reverse},
                                                @augmented_files);
    }

    my @top_files = $self->strip_augmented(@augmented_files);
    return \@top_files;
}

#----------------------------------------------------------------------
# Get a url from a filename

sub get_url {
    my ($self, $filename) = @_;

    return $self->filename_to_url($self->{base_directory},
                                  $filename,
                                  $self->{web_extension});
}

#----------------------------------------------------------------------
# Augment the list of filenames with the sort field

sub make_augmented {
    my $self = shift @_;
    my $sort_field = shift @_;

    my @augmented_files;

    if ($sort_field) {
        @augmented_files =  map {[$self->sort_value($sort_field, $_), $_]}
                            @_;
    } else {
        @augmented_files = map {[$_, $_]} @_;
    }

    return @augmented_files;
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

    my @patterns = map {"*.$_"} split(/\s*,\s*/, $self->{extension});
    my $patterns = join(',', @patterns);

    $self->{include_file_patterns} ||= fio_glob_patterns($patterns);
    $self->{exclude_file_patterns} ||= fio_glob_patterns($self->{exclude});

    my ($dir, $file) = fio_split_filename($filename);

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
# Merge two sorted lists of augmented filenames

sub merge_augmented {
    my ($self, $sort_reverse, $list1, $list2) = @_;

    my @merged_list = ();
    my $comparer = $self->file_comparer($sort_reverse);

    while(@$list1 && @$list2) {
        if ($comparer->($list1->[0], $list2->[0]) > 0) {
            push(@merged_list, shift @$list2);
        } else {
            push(@merged_list, shift @$list1);
        }
        return @merged_list if @merged_list == $self->{sort_cutoff};
    }

    while (@$list1) {
        push(@merged_list, shift @$list1);
        return @merged_list if @merged_list == $self->{sort_cutoff};
    }

    while (@$list2) {
        push(@merged_list, shift @$list2);
        return @merged_list if @merged_list == $self->{sort_cutoff};
    }

     return @merged_list;
}

#----------------------------------------------------------------------
# Set the directory if not passed as an argument

sub setup {
    my ($self, %configuration) = @_;

    $self->{extension} ||= $self->{web_extension};
    return;
}

#----------------------------------------------------------------------
# Sort a list of files augmented by their sort field

sub sort_augmented {
    my $self = shift @_;
    my $sort_reverse = shift @_;

    my $comparer = $self->file_comparer($sort_reverse);
    return sort $comparer @_;
}

#----------------------------------------------------------------------
# Sort a list of filenames by metadata field

sub sort_files {
    my $self = shift @_;
    my $sort_field = shift @_;
    my $sort_reverse = shift @_;

    return $self->strip_augmented(
           $self->sort_augmented($sort_reverse,
           $self->make_augmented($sort_field, @_)));
}

#----------------------------------------------------------------------
# Get value to sort on from the the field name

sub sort_value {
    my ($self, $sort_field, $filename) = @_;

    my $value;
    if ($sort_field) {
        $value = ${$self->build($sort_field, $filename)};
    } else {
        $value = join(' ', fio_split_filename($filename));
    }

    return $value;
}

#----------------------------------------------------------------------
# Return the filenames from an augmented set of files

sub strip_augmented {
    my $self = shift @_;
    return map {$_->[1]} @_;
}

1;

=pod

=encoding utf-8

=head1 NAME

App::Followme::FolderData - Build metadata from folder information

TODO rewrite

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

=item @breadcrumbs

A list of breadcrumb filenames, which are the names of the index files
above the filename passed as the argument.

=item @files

A list of matching files in a directory.

=item @folders

A list of folders under the default folder that contain an index file.

=item $author

The name of the author of a file

=item $absolute_url

The absolute url of a web page from a filename.

=item $date

A date string built from the modification date of the file. The date is
built using the template in date_format which contains the fields:
C<weekday, month,day, year, hour,  minute,> and C<second.>

=item $mdate

The epoch is modification date of a file in the number of seconds since 1970

=item $is_current

One if the filename matches the default filename, zero if it does not.

=item $is_index

One of the filename is an index file and zero if it is not.

=item $keywords

A list of keywords describing the file from the filename path.

=item $site_url

The url of the website. Does not have a trailing slash

=item $title

The title of a file is derived from the file name by removing the filename
extension, removing any leading digits,replacing dashes with spaces, and
capitalizing the first character of each word.

=item $url

Build the relative url of a web page from a filename.

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

The extension of the files metadata is retrieved from. This is used by list
valued metadata. The default value is the same as the web extension.

=item date_format

The format used to produce date strings. The format is described in the
POD for L<Time::Format>.

=item sort_field

The metatdata field to sort list valued variables. The default value is the
empty string, which means files are sorted on their filenames.

=item sort_numeric

If one, use numeric comparisons when sorting. If zero, use string comparisons
when sorting.

=item sort_reverse

If this field is 0, the data are sorted the first filename has the smallest
metadata value. If the field is 1, it has the largest. The default value of the
parameter is 0.

=item sort_cutoff

This determons the number of filenames returned by @top_files. The default
value of this parameter id 5

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
