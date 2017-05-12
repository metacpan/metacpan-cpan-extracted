# NAME
Archive::Probe - A generic library to search file within archive

# SYNOPSIS

For searching archive:
````perl
    use Archive::Probe;

    my $tmpdir = '<temp_dir>';
    my $base = '<directory_or_archive_file>';
    my $probe = Archive::Probe->new();
    $probe->working_dir($tmpdir);
    $probe->add_pattern(
	'<your_pattern_here>',
	sub {
	    my ($pattern, $file_ref) = @_;

	    # do something with result files
    });
    $probe->search($base, 1);
````

For extracting archive:
````perl
    use Archive::Probe;

    my $archive = '<path_to_your_achive>';
    my $dest_dir = '<path_to_dest>';
    $probe->extract($archive, $dest_dir, 1);
````

# DESCRIPTION

Archive::Probe is a generic library to search file within archive.

It facilitates searching of particular file by name or content inside
deeply nested archive with mixed types. It supports common archive
types such as .tar, .tgz, .bz2, .rar, .zip .7z and Java archive such
as .jar, .war, .ear. If the target archive file contains another
archive file of same or other type, this module extracts the embedded
archive to fulfill the inquiry. The level of embedding is unlimited.
This module depends on unzip, unrar, 7za and tar which are assumed to
be present in PATH. The 7za is part of 7zip utility. It is preferred
tool to deal with .zip archive it runs faster and handles meta
character better than unzip. The 7zip is open source software and you
download and install it from [www.7-zip.org][1] or install the binary
package p7zip with your favorite package management software. The
unrar is freeware and you get it from [rarlab][2] or [atrpms][3].


# METHODS

## new()
Creates a new "Archive::Probe" object.

## add_pattern($regex, $coderef)
Register a file pattern to search with in the archive file(s) and the
callback code to handle the matched files. The callback will be passed
two arguments:

### $pattern
    This is the pattern of the matched files.

### $file_ref
    This is the array reference to the files matched the pattern. The
    existence of the files is controlled by the second argument to the
    "search()" method.

## search($base, $extract_matched)
Search registered files under 'base' and invoke the callback. It
requires two arguments:
## $base
    This is the directory containing the archive file(s).

## $extract_matched
    Extract or copy the matched files to the working directory if this
    parameter evaluate to true.

## reset_matches()
Reset the matched files list.

## extract($base, $dest_dir, $recursive, $flat)
Extract archive of various types to destination directory. It extracts
 embedded archive to its own directory by default.

### $base
This is the directory containing the archive file(s) or the archive
file itself.

### $dest_dir
This is the directory to store extracted files from the archive.

### $recursive
This parameter defaults to true which means any embedded archives are
extracted recursively by default. Specify 0 to disable extracting
embedded archives recursively.

### $flat
If this parameter evaluates to true, it extracts embedded archives in
the same directory as their containing directory. Otherwise, it extracts
embedded archive to its own folder named after the archive with two
underscore appended.

# ACCESSORS

## working_dir([directory])
Set or get the working directory where the temporary files will be
created.

## show_extracting_output([BOOL])
Enable or disable the output of command line archive tool.

# HOW IT WORKS

"Archive::Probe" provides low level code to search files in nested
archive files. It does the heavy lifting to extract mininal files
necessary to fulfill the inquiry.

# BUG REPORTS

Please report bugs or other issues to <schnell18@gmail.com>.

# AUTHOR

This module is developed by Justin Zhang <schnell18@gmail.com>.

# COPYRIGHT

Copyright 2013 schnell18
This library is free software; you may redistribute and/or modify it
under the same terms as Perl itself.

[1]: http://www.7-zip.org "7zip official site"
[2]: http://www.rarlab.com/rar_add.htm "RAR Lab download page"
[3]: http://atrpms.net/ "ATrpms"
