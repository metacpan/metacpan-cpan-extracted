package Archive::Probe;
#
# This class searches and extracts files matching given pattern within
# deeply nested archive files. Mixed archive types are supported.
# Pre-requisite: unrar, 7za should be in PATH
#                Get free unrar from: http://www.rarlab.com/rar_add.htm
#                Get free 7za from: http://www.7-zip.org
# Author:          JustinZhang <fgz@cpan.org>
# Creation Date:   2013-05-06
#
use strict;
use warnings;
use Carp;
use File::Basename;
use File::Copy;
use File::Path;
use File::Spec::Functions qw(catdir catfile devnull path);
use File::Temp qw(tempfile);

our $VERSION = "0.86";

my %_CMD_LOC_FOR = ();

=pod

=head1 NAME

Archive::Probe - A generic library to search file within archive

=head1 SYNOPSIS

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

    # or use it as generic archive extractor
    use Archive::Probe;

    my $archive = '<path_to_your_achive>';
    my $dest_dir = '<path_to_dest>';
    $probe->extract($archive, $dest_dir, 1);

=head1 DESCRIPTION

Archive::Probe is a generic utility to search or extract archives.

It facilitates searching of particular file by name or content inside
deeply nested archive with mixed types. It can also extract embedded
archive inside the master archive recursively. It is built on top of
common archive tools such as 7zip, unrar, unzip and tar. It supports
common archive types such as .tar, .tgz, .bz2, .rar, .zip .7z and Java
archive such as .jar, .war, .ear. If the target archive file contains
another archive file of same or other type, this module extracts the
embedded archive to fulfill the inquiry. The level of embedding is
unlimited. This module depends on unzip, unrar, 7za and tar which are
assumed to be present in PATH. The 7za is part of 7zip utility. It is
preferred tool to deal with .zip archive it runs faster and handles meta
character better than unzip. The 7zip is open source software and you
download and install it from www.7-zip.org or install the binary package
p7zip with your favorite package management software. The unrar is
freeware which can be downloaded from http://www.rarlab.com/rar_add.htm.

=cut

=head1 METHODS

=head2 constructor new()

Creates a new C<Archive::Probe> object.

=cut

sub new {
    my $self = shift;

    my $class = ref $self || $self;
    return bless {}, $class;
}

=head2 add_pattern($pattern, $callback)

Register a file pattern to search with in the archive file(s) and the
callback code to handle the matched files. The callback will be passed
two arguments:

=over 4

=item $pattern

This is the pattern of files to be searched.

=item $callback

This is the callback to examine the search result. The array reference
to the files matched the pattern is passed to the callback. If you want
to examine the content of the matched files, then you set the second
argument of the C<search()> method to true.

=back

=cut

sub add_pattern {
    my ($self, $pattern, $callback) = @_;

    # validate pattern and callback
    confess("Pattern is mandatory\n") unless $pattern;
    confess("Code reference is expected\n") unless ref($callback) eq 'CODE';

    my $pattern_map = $self->_search_pattern();
    if (!$pattern_map) {
        $pattern_map = {};
        $self->_search_pattern($pattern_map);
    }

    $pattern_map->{$pattern} = [$callback];
}

=head2 search($base, $extract_matched)

Search files of interest under 'base' and invoke the callback.
It requires two arguments:

=over 4

=item $base

This is the directory containing the archive file(s) or the archive file
itself.

=item $extract_matched

Extract or copy the matched files to the working directory
if this parameter evaluates to true. This is useful when you need search
files based on their content not just by name.

=back

=cut

sub search {
    my ($self, $base, $do_extract) = @_;
    
    my @queue = ();
    push @queue, $base;

    while (my $path = shift @queue) {
        if (-d $path) {
            opendir(my $dh, $path) or do {
                carp("Can't read directory due to: $!\n");
                next;
            };

            while (my $entry = readdir($dh)) {
                next if $entry eq '.' || $entry eq '..';
                push @queue, catfile($path, $entry);
            }
            closedir($dh);
        }
        elsif (-f $path) {
            my $new_base = $base;
            $new_base = dirname($base) if $base eq $path;
            # Test if the file matches regestered pattern
            $self->_match($do_extract, $new_base, '', $path);
            if ($self->_is_archive_file($path)) {
                my $ctx = $self->_strip_dir($new_base, $path) ;
                $ctx .= '__' if $ctx ne '';
                $self->_search_in_archive(
                    $do_extract,
                    $new_base,
                    $ctx,
                    $path
                );
            }
        }
    }

    # check search result & invoke callback
    $self->_callback();
}

=head2 extract($base, $to_dir, $recursive, $flat)

Extract archive to given destination directory.
It requires three arguments:

=over 4

=item $base

This is the path to the archive file or the base archive directory.

=item $to_dir

The destination directory.

=item $recursive

Recursively extract all embedded archive files in the master archive if
this parameter evaluates to true. It defaults to true.

=item $flat

If this parameter evaluates to true, C<Archive::Probe> extracts embedded
archives under the same folder as their containing folder in recursive
mode. Otherwise, it extracts the content of embedded archives into their
own directories to avoid files with same name from different embedded
archive being overwritten. Default is false.

=item return value

The return value of this method evaluates to true if the archive is
extacted successfully. Otherwise, it evaluates to false.

=back

=cut

sub extract {
    my ($self, $base, $to_dir, $recursive, $flat) = @_;
    
    $recursive = 1 unless defined($recursive);
    my @queue = ();
    my %searched_for = ();
    push @queue, $base;

    while (my $path = shift @queue) {
        if (-d $path) {
            # search archives in this directory
            my $ret = opendir(my $dh, $path);
            if (!$ret) {
                carp("Can't read directory due to: $!\n");
                next;
            }

            while (my $entry = readdir($dh)) {
                next if $entry eq '.' || $entry eq '..';
                my $f = catfile($path, $entry);
                if (-d $f ) {
                    push @queue, $f;
                }
                elsif (-f $f && $self->_is_archive_file($f)) {
                    push @queue, $f unless $searched_for{$f};
                }
            }
            closedir($dh);
        }
        elsif ($self->_is_archive_file($path)) {
            $searched_for{$path} = 1;
            # extract archive and find any embedded archives
            # if recursive extraction is required
            my $dest_dir = $to_dir;
            if (index($path, $to_dir) >= 0) {
                if ($flat) {
                    $dest_dir = dirname($path);
                }
                else {
                    $dest_dir = catdir(
                        dirname($path),
                        basename($path) . "__"
                    );
                }
            }
            my $ret = $self->_extract_archive_file($path, "", $dest_dir);
            if ($ret && $recursive) {
                push @queue, $dest_dir;
            }
            elsif (!$ret) {
                return 0;
            }
        }
    }
    return 1;
}

=head2 reset_matches()

Reset the matched files list.

=cut

sub reset_matches {
    my ($self) = @_;

    my $patterns = $self->_search_pattern();
    foreach my $pat (keys(%$patterns)) {
        undef($patterns->{$pat}[1]);
    }
}

=head1 ACCESSORS

=head2 working_dir([$directory])

Set or get the working directory where the temporary files will be created.

=cut

sub working_dir {
    my ($self, $value) = @_;

    if(defined $value) {
    	my $oldval = $self->{working_dir};
    	$self->{working_dir} = $value;
    	return $oldval;
    }

    return $self->{working_dir};
}

=head2 show_extracting_output([BOOL])

Enable or disable the output of command line archive tool.

=cut

sub show_extracting_output {
    my ($self, $value) = @_;

    if(defined $value) {
    	my $oldval = $self->{show_extracting_output};
    	$self->{show_extracting_output} = $value;
    	return $oldval;
    }

    return $self->{show_extracting_output};
}

sub _extract_matched {
    my ($self, $base_dir, $ctx, $file, $do_extract) = @_;

    my $dest;
    my $work_dir = $self->working_dir();
    # extract the matched file here
    if ($ctx ne '') {
        # parent file location = $base_dir + substr($ctx, 0, -2)
        my $parent = catfile($base_dir, substr($ctx, 0, -2));
        my $extract_dir = catdir($work_dir, $ctx);
        if ($do_extract) {
            my $ret = $self->_extract_archive_file(
                $parent,
                $file,
                $extract_dir
            );
            if (!$ret) {
                carp("$file can not be extracted from $parent, ignored\n");
                return;
            }
        }
        $dest = catfile($extract_dir, $file);
    }
    else {
        # matched files are unarchived
        # copy to working directory as-is
        # create absent local dir first
        my $local_path = $self->_strip_dir($base_dir, $file);
        $dest = catfile($work_dir, $local_path);

        if ($do_extract) {
            my $dir2 = catdir($work_dir, $self->_dir_name($local_path));
            mkpath($dir2) unless -d $dir2;
            my $ret = copy($file, $dest);
            if (!$ret) {
                carp("Can't copy file $file to $dest due to: $!\n");
                return;
            }
        }
    }
    return $dest;
}

sub _match {
    my ($self, $do_extract, $base_dir, $ctx, $file) = @_;

    my $matches = 0;
    my $part = $self->_strip_dir(catdir($base_dir, $ctx), $file);
    my $patterns = $self->_search_pattern();
    foreach my $pat (keys(%$patterns)) {
        if ($part =~ /$pat/) {
            $matches ++;
            my $dest = $self->_extract_matched(
                $base_dir,
                $ctx,
                $file,
                $do_extract
            );
            # do not add file to matched list if extract fails
            next unless $dest;

            my $pat_ref = $patterns->{$pat};
            if (!defined($pat_ref->[1])) {
                $pat_ref->[1] = [$dest];
            }
            else {
                push @{$pat_ref->[1]}, $dest;
            }
        }
    }
    return $matches;
}

sub _callback {
    my ($self) = @_;

    my $patterns = $self->_search_pattern();
    foreach my $pat (keys(%$patterns)) {
        my $pat_ref = $patterns->{$pat};
        if (ref($pat_ref->[0]) eq 'CODE' && defined($pat_ref->[1])) {
            $pat_ref->[0]->($pat, $pat_ref->[1]);
        }
    }
    $self->_cleanup();
}

sub _search_in_archive {
    my ($self, $do_extract, $base_dir, $ctx, $file) = @_;

    if ($file =~ /\.zip$|\.jar$|\.war$|\.ear$/) {
        if ($self->_is_cmd_avail('7za')) {
            $self->_peek_archive(
                $do_extract,
                $base_dir,
                $ctx,
                $file,
                '7za l',
                '(-+)\s+(-+)\s+(-+)\s+(-+)\s+(-+)',
                '---+',
                '',
                sub {
                    my ($entry, undef, undef, undef, undef, $file_pos) = @_;
                    my (undef, undef, $a, undef) = split(' ', $entry, 4);
                    return if $a =~ /^D/;
                    if ($file_pos && $file_pos < length($entry)) {
                       my $f = substr($entry, $file_pos);
                       return $f;
                    }
                    return;
                }
            ); 
        }
        else {
            $self->_peek_archive(
                $do_extract,
                $base_dir,
                $ctx,
                $file,
                "unzip -l",
                "--------",
                "--------",
                '',
                sub {
                    my ($entry) = @_;
                    my (undef, undef, undef, $f) = split(' ', $entry, 4);
                    return $f;
                }
            ); 

        }
    }
    elsif ($file =~ /\.7z$/) {
        $self->_peek_archive(
            $do_extract,
            $base_dir,
            $ctx,
            $file,
            '7za l',
            '(-+)\s+(-+)\s+(-+)\s+(-+)\s+(-+)',
            '---+',
            '',
            sub {
                my ($entry, undef, undef, undef, undef, $file_pos_7z) = @_;
                my (undef, undef, $a, undef) = split(' ', $entry, 4);
                return if $a =~ /^D/;
                if ($file_pos_7z && $file_pos_7z < length($entry)) {
                   my $f = substr($entry, $file_pos_7z);
                   return $f;
                }
                return;
            }
        ); 
    }
    elsif ($file =~ /\.rar$/) {
        $self->_peek_archive(
            $do_extract,
            $base_dir,
            $ctx,
            $file,
            "unrar vb",
            '',
            '',
            '',
            sub {
                my ($entry) = @_;
                return $entry;
            }
        ); 
    }
    elsif ($file =~ /\.tgz$|\.tar\.gz$|\.tar\.Z$/) {
        $self->_peek_archive(
            $do_extract,
            $base_dir,
            $ctx,
            $file,
            "tar -tzf",
            '',
            '',
            '\/$',
            sub {
                my ($entry) = @_;
                return $entry;
            }
        ); 
    }
    elsif ($file =~ /\.bz2$/) {
        $self->_peek_archive(
            $do_extract,
            $base_dir,
            $ctx,
            $file,
            "tar -tjf",
            '',
            '',
            '\/$',
            sub {
                my ($entry) = @_;
                return $entry;
            }
        ); 
    }
    elsif ($file =~ /\.tar$/) {
        $self->_peek_archive(
            $do_extract,
            $base_dir,
            $ctx,
            $file,
            "tar -tf",
            '',
            '',
            '\/$',
            sub {
                my ($entry) = @_;
                return $entry;
            }
        ); 
    }
    else {
        carp("Archive file $file is not supported\n");
    }
}

sub _peek_archive {
    my ($self,
        $do_extract,
        $base_dir,
        $ctx,
        $file,
        $list_cmd,
        $begin_pat,
        $end_pat,
        $ignore_pat,
        $sub
    ) = @_;

    # stop peeking if archive tool is not available
    my ($ar_cmd) = split(/\s+/, $list_cmd);
    if (!$self->_is_cmd_avail($ar_cmd)) {
        carp("$ar_cmd not in PATH, archive $file ignored\n");
        return;
    }
    
    my $tmpdir = $self->working_dir();
    my $lst_file = $self->_get_list_file();
    my $cmd = join(" ", $list_cmd, $self->_escape($file));
    my $cmd_shell = "$cmd > $lst_file 2>&1";
    my $ret = system($cmd_shell);
    if ($ret != 0) {
        carp("Can't run $cmd\n");
        return;
    }
    $ret = open(my $fh, q{<}, "$lst_file");
    if (!$ret) {
        carp("Can't open file $lst_file due to: $!\n");
        return;
    }

    my @col_indexes;
    my $file_list_begin = 0;
    while(<$fh>) {
        chomp;
        my $line = $_;
        if ($begin_pat) {
            if (! $file_list_begin) {
                # determine if the start of file list and
                # calculate start position of each column
                my @captures = $line =~ /$begin_pat/g;
                if (@captures) {
                    my $pos = 0;
                    $file_list_begin = 1;
                    foreach my $cap (@captures) {
                        push @col_indexes, index($line, $cap, $pos);
                        $pos += length($cap);
                    }
                }
                next; 
            }
        }

        if ($ignore_pat) {
            next if /$ignore_pat/;
        }

        if ($end_pat) {
            last if /$end_pat/;
        }

        my $f = $sub->($line, @col_indexes);
        # ignore empty line, usually directory
        next unless $f;
        $self->_match($do_extract, $base_dir, $ctx, $f);
        if ($self->_is_archive_file($f)) {
            my $extract_dir = catdir($tmpdir, $ctx);
            my $ret = $self->_extract_archive_file($file, $f, $extract_dir);
            if ($ret) {
                my $new_ctx = catfile($ctx, $f . '__');
                $self->_search_in_archive(
                    $do_extract,
                    $tmpdir,
                    $new_ctx,
                    catfile($extract_dir, $f)
                );
            }
            else {
                carp("$f can not be extracted from $file, ignored\n");
            }
        }
    }
    close($fh);
}

sub _extract_archive_file {
    my ($self, $parent, $file, $extract_dir) = @_;

    mkpath($extract_dir) unless -d $extract_dir;
    my $cmd = "";
    if ($parent =~ /\.zip$|\.jar$|\.war$|\.ear$/) {
        if ($self->_is_cmd_avail('7za')) {
            # specify dummy password to make 7za fail fast
            # instead of waiting for user input password when
            # the zip file is password-protected
            $cmd = $self->_build_cmd(
                '7za x -y -pxxx',
                $extract_dir,
                $parent,
                $file
            );
        }
        else {
            if ($^O !~ /bsd$/i) {
                # specify dummy password to make unzip fail fast
                # instead of waiting for user input password when
                # the zip file is password-protected
                $cmd = $self->_build_cmd(
                    'unzip -P xxx -o',
                    $extract_dir,
                    $parent,
                    $file
                );
            }
            else {
                # FreeBSD and its derivatives do NOT support -P
                if ($file !~ /[;<>\\\*\|`&\$!#\(\)\[\]\{\}:'"]/) {
                    $cmd = $self->_build_cmd(
                        'unzip -o',
                        $extract_dir,
                        $parent,
                        $file
                    );
                }
                else {
                    # extract all files if the matched
                    # file has shell meta-char in the name
                    $cmd = $self->_build_cmd(
                        'unzip -o',
                        $extract_dir,
                        $parent,
                        ''
                    );
                }
            }
        }
    }
    elsif ($parent =~ /\.7z$/) {
        # specify dummy password to make 7za fail fast
        # instead of waiting for user input password when
        # the zip file is password-protected
        $cmd = $self->_build_cmd(
            '7za x -y -pxxx',
            $extract_dir,
            $parent,
            $file
        );
    }
    elsif ($parent =~ /\.rar$/) {
        $cmd = $self->_build_cmd(
            'unrar x -o+',
            $extract_dir,
            $parent,
            $file
        );
    }
    elsif ($parent =~ /\.tgz$|\.tar\.gz$|\.tar\.Z$/) {
        # The "-o" avoid to restore the owner as it could be root
        $cmd = $self->_build_cmd(
            'tar -xzof',
            $extract_dir,
            $parent,
            $file
        );
    }
    elsif ($parent =~ /\.bz2$/) {
        # The "-o" avoid to restore the owner as it could be root
        $cmd = $self->_build_cmd(
            'tar -xjof',
            $extract_dir,
            $parent,
            $file
        );
    }
    elsif ($parent =~ /\.tar$/) {
        # The "-o" avoid to restore the owner as it could be root
        $cmd = $self->_build_cmd(
            'tar -xof',
            $extract_dir,
            $parent,
            $file
        );
    }
    my $cmd_shell = sprintf("%s 2>%s 1>&2", $cmd, devnull());
    $cmd_shell = "$cmd 1>&2" if $self->show_extracting_output();
    my $ret = system($cmd_shell);
    return $ret == 0;
}

sub _build_cmd {
    my ($self, $extract_cmd, $dir, $parent, $file) = @_;

    my $chdir_cmd = q[cd];
    if ($^O eq 'MSWin32') {
        $chdir_cmd = q[cd /d];
    }
    return sprintf(
        "%s %s && %s %s %s",
        $chdir_cmd,
        $self->_escape($dir),
        $extract_cmd,
        $self->_escape($parent),
        $self->_escape($file)
    );
}

sub _is_cmd_avail {
    my ($self, $cmd) = @_;

    if (!exists $_CMD_LOC_FOR{$cmd}) {
        my @path = path();
        foreach my $p (@path) {
            my $fp = catfile($p, $cmd);
            if (-f $fp) {
                $_CMD_LOC_FOR{$cmd} = $fp;
                return 1;
            }
            else {
                if($^O eq 'MSWin32') {
                    # try to append .exe to the name
                    my $fp_win = $fp . ".exe";
                    if (-f $fp_win) {
                        $_CMD_LOC_FOR{$cmd} = $fp_win;
                        return 1;
                    }
                    # try to append .bat to the name
                    $fp_win = $fp . ".bat";
                    if (-f $fp_win) {
                        $_CMD_LOC_FOR{$cmd} = $fp_win;
                        return 1;
                    }
                }
            }
        }
        # executable not found, won't try again
        $_CMD_LOC_FOR{$cmd} = "";
    }
    return $_CMD_LOC_FOR{$cmd} ? 1 : 0;
}

sub _strip_dir {
    my ($self, $base_dir, $path) = @_;

    my $dir1 = $base_dir;
    my $path1 = $path;

    my $path_sep = '/';
    $path_sep = '\\' if $^O eq 'MSWin32';

    $dir1 .= $path_sep unless substr($dir1, -1, 1) eq $path_sep;
    if (index($path1, $dir1) == 0) {
        $path1 = substr($path1, length($dir1));
    }
    return $path1;
}

sub _escape {
    my ($self, $str) = @_;

    my $ret = $str;
    if ($^O ne 'MSWin32') {
        $ret =~ s/([ ;<>\\\*\|`&\$!#\(\)\[\]\{\}:'"])/\\$1/g;
    }
    else {
        $ret = qq["$ret"] if $ret =~ /[ &#*\|\[\]\(\)\{\}\=;!+,`~']/;
    }
    return $ret;
}

sub _is_archive_file {
    my ($self, $file) = @_;

    return $file =~ /\.(zip|jar|war|ear|7z|rar|tgz|bz2|tar|tar\.gz|tar\.Z)$/
}

sub _property {
    my ($self, $attr, $value) = @_;

    if(defined $value) {
    	my $oldval = $self->{$attr};
    	$self->{$attr} = $value;
    	$self->{_properties_with_value} = {}
    	    if(!exists $self->{_properties_with_value});
    	$self->{_properties_with_value}{$attr} = 1;
    	return $oldval;
    }

    return $self->{$attr};
}

sub _remove_property {
    my ($self, $attr) = @_;

    $self->{$attr} = undef;
}

sub _search_pattern {
    my ($self, $value) = @_;

    if(defined $value) {
    	my $oldval = $self->{search_pattern};
    	$self->{search_pattern} = $value;
    	return $oldval;
    }

    return $self->{search_pattern};
}

sub _dir_name {
    my ($self, $path) = @_;

    my $path_sep = '/';
    $path_sep = '\\' if $^O eq 'MSWin32';
    my $idx = rindex($path, $path_sep);
    if ($idx > 0) {
        return substr($path, 0, $idx);
    }
    else {
        return '';
    }
}

sub _get_list_file {
    my ($self) = @_;

    my (undef, $lst) = tempfile();
    my $files = $self->_property('archive_lst_files');
    if (!defined($files)) {
        $files = [];
        $self->_property('archive_lst_files', $files);
    }
    push @$files, $lst;
    return $lst;
}

sub _cleanup {
    my ($self) = @_;

    my $files = $self->_property('archive_lst_files');
    foreach my $f (@$files) {
        unlink($f);
    }
}

1;

=pod

=head1 HOW IT WORKS

C<Archive::Probe> provides plumbing boiler code to search files in nested
archive files. It does the heavy lifting to extract mininal files necessary
to fulfill the inquiry.

=head1 SOURCE AVAILABILITY

This code is hosted on Github

    https://github.com/schnell18/archive-probe

=head1 BUG REPORTS

Please report bugs or other issues to E<lt>fgz@rt.cpan.orgE<gt>.

=head1 AUTHOR

This module is developed by Justin Zhang E<lt>fgz@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright (C) 2013 by Justin Zhang

This library is free software; you may redistribute and/or modify it
under the same terms as Perl itself.

=cut

# vim: set ai nu nobk expandtab sw=4 ts=4 tw=72 :
