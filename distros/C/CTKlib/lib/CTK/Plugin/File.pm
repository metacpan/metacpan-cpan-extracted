package CTK::Plugin::File;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::Plugin::File - File plugin

=head1 VERSION

Version 1.03

=head1 SYNOPSIS

    use CTK;
    my $ctk = CTK->new(
            plugins => "file",
        );

    my $n = $ctk->fcopy(
        -dirsrc => "/path/to/source/dir", # Source directory
        -dirdst => "/path/to/destination/dir", # Destination directory
        -glob   => "*.conf",
        -format => '[FILE].copy', # Format. Default: [FILE]
        -uniq   => 0, # 0 -- off; 1 -- on
    );

    my $n = $ctk->fmove(
        -dirsrc => "/path/to/source/dir", # Source directory
        -dirdst => "/path/to/destination/dir", # Destination directory
        -glob   => "*.conf",
        -format => '[FILE]', # Format. Default: [FILE]
        -uniq   => 0, # 0 -- off; 1 -- on
    );

    my $n = $ctk->fremove(
        -dirsrc => "/path/to/source/dir", # Source directory
        -glob   => "*.conf",
    );

    my $n = $ctk->fsplit(
        -dirsrc => "/path/to/source/dir", # Source directory
        -dirdst => "/path/to/destination/dir", # Destination directory
        -glob   => "*.txt",
        -lines  => 3,
        -format => '[FILE].part[PART]', # Format. Default: [FILE].part[PART]
    )

    my $n = $ctk->fjoin(
        -dirsrc => "/path/to/source/dir", # Source directory
        -dirdst => "/path/to/destination/dir", # Destination directory
        -glob   => "*.txt",
        -outfile=> "join.txt",
        -binmode=> "off",
        -eol    => "\n",
    );

=head1 DESCRIPTION

File plugin

=head1 METHODS

=over 8

=item B<fcopy>

    my $n = $ctk->fcopy(
        -dirsrc => "/path/to/source/dir", # Source directory
        -dirdst => "/path/to/destination/dir", # Destination directory
        -glob   => "*.conf",
        -format => '[FILE].copy', # Format. Default: [FILE]
        -uniq   => 0, # 0 -- off; 1 -- on
    );

Copies files from the source directory to the destination directory
and returns how many files was copied

=over 8

=item B<-dirin>, B<-in>, B<-dirsrc>, B<-src>, B<-source>

Specifies source directory

Default: current directory

=item B<-dirout>, B<-out>, B<-dirdst>, B<-dst>, B<-target>

Specifies destination directory

Default: current directory

=item B<-list>, B<-mask>, B<-glob>, B<-file>, B<-files>, B<-regexp>

    -list => [qw/ file1.txt file2.txt file3.* /]

List of files or globs

    -glob => "file.*"

Glob pattern

    -file => "file1.txt"

Name of file

    -regexp => qr/\.(cgi|pl)$/i

Regexp

Default: undef (all files)

=item B<-format>, B<-callback>, B<-cb>

    -format => "[COUNT]_[FILE].copy.[TIME]"

Specifies format for output file

    -callback => sub {
        my $file_name = shift;
        my $file_number = shift;
        ...
        return $file_name;
    }

Callbacks allows you to modify the name of the output file manually

Default: "[FILE]"

=item B<-uniq>, B<-unique>

Unique mode

Default: off

=back

Replacing keys: FILE, COUNT, TIME

=item B<fjoin>

    my $n = $ctk->fjoin(
        -dirsrc => "/path/to/source/dir", # Source directory
        -dirdst => "/path/to/destination/dir", # Destination directory
        -glob   => "*.txt",
        -outfile=> "join.txt",
        -binmode=> "off",
        -eol    => "\n",
    );

Join group of files (by mask from source directory) to one big file (concatenate).
File writes to destination directory by output file name (fout)

    perl -MCTK::Command -e "fjoin(-mask=>qr/txt$/, -fout=>'foo.txt')" -- *

This is new features, added since CTK 1.18

=over 8

=item B<-dirin>, B<-in>, B<-dirsrc>, B<-src>, B<-source>

Specifies source directory

Default: current directory

=item B<-dirout>, B<-out>, B<-dirdst>, B<-dst>, B<-destination>

Specifies destination directory

Default: current directory

=item B<-list>, B<-mask>, B<-glob>, B<-files>, B<-regexp>

    -list => [qw/ file1.txt file2.txt file3.* /]

List of files or globs

    -glob => "file.*"

Glob pattern

    -file => "file1.txt"

Name of file

    -regexp => qr/\.(cgi|pl)$/i

Regexp string (recommended)

Default: undef (all files)

=item B<-file>, B<-filename>, B<-fileout>, B<-target>

Specifies target file

Required parameter

=item B<-binmode>

Turns on binary mode of processing file.
Default is textmode -
will read each line of input file and write it to output file

Default: no (textmode)

=item B<-eol>, B<-newline>, B<-nl>, B<-crlf>

Specifies end-of-line character for lines preprocessing

Default: \n

=back

=item B<fmove>

    my $n = $ctk->fmove(
        -dirsrc => "/path/to/source/dir", # Source directory
        -dirdst => "/path/to/destination/dir", # Destination directory
        -glob   => "*.conf",
        -format => '[FILE]', # Format. Default: [FILE]
        -uniq   => 0, # 0 -- off; 1 -- on
    );

Movies files from the source directory to the destination directory
and returns how many files was moved

Format of arguments see L</"fcopy">

=item B<fremove>

    my $n = $ctk->fremove(
        -dir    => "/path/to/source/dir", # Source directory
        -glob   => "*.conf",
    );

Removing files from the source directory

Format of arguments see L</"fcopy">

=item B<fsplit>

    my $n = $ctk->fsplit(
        -dirsrc => "/path/to/source/dir", # Source directory
        -dirdst => "/path/to/destination/dir", # Destination directory
        -glob   => "*.txt",
        -lines  => 3,
        -format => '[FILE].part[PART]', # Format. Default: [FILE].part[PART]
    )

Split group of files to parts

=over 8

=item B<-dirin>, B<-in>, B<-dirsrc>, B<-src>, B<-source>

Specifies source directory

Default: current directory

=item B<-dirout>, B<-out>, B<-dirdst>, B<-dst>, B<-target>

Specifies destination directory

Default: current directory

=item B<-list>, B<-mask>, B<-glob>, B<-file>, B<-files>, B<-regexp>

    -list => [qw/ file1.txt file2.txt file3.* /]

List of files or globs

    -glob => "file.*"

Glob pattern

    -file => "file1.txt"

Name of file

    -regexp => qr/\.(cgi|pl)$/i

Regexp

Default: undef (all files)

=item B<-limit>, B<-lines>, B<-rows>, B<-n>

    -lines => 5

Splits file by 5 lines

=item B<-format>, B<-callback>, B<-cb>

    -format => "[COUNT]_[FILE].copy[TIME].part[PART]"

Specifies format for output file

    -callback => sub {
        my $input_file_name = shift;
        my $input_file_number = shift;
        my $output_file_number = shift; # Part number
        ...
        return $file_name;
    }

Callbacks allows you to modify the name of the output file manually

Default: "[FILE].part[PART]"

=back

Replacing keys: FILE, COUNT, TIME, PART

=back

=head2 REPLACING KEYS

=over 8

=item B<FILE>

Path and filename

=item B<FILENAME>

Filename only

=item B<FILEEXT>

File extension only

=item B<COUNT>

Current number of file in sequence (for fcopy and fmove methods)

For fsplit method please use perl mask %i

=item B<TIME>

Current time value (unix-time format, time())

=back

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<CTK>, L<CTK::Plugin>, L<File::Find>, L<File::Copy>, L<Cwd>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK>, L<CTK::Plugin>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION /;
$VERSION = '1.03';

use base qw/CTK::Plugin/;

use CTK::Util qw/ :BASE /;
use Carp;
use File::Find;
use Cwd qw/getcwd abs_path/;
use File::Copy;
use Fcntl qw/ :flock /;
use Symbol;

use constant BUFFER_SIZE => 32 * 1024; # 32kB

__PACKAGE__->register_method(
    method    => "fcopy",
    callback  => \&_cpmv
);

__PACKAGE__->register_method(
    method    => "fmove",
    callback  => sub { &_cpmv(@_, '-X_CTK_PLUGIN_OP' => 'move') }
);

__PACKAGE__->register_method(
    method    => "fremove",
    callback  => sub { &_cpmv(@_, '-X_CTK_PLUGIN_OP' => 'remove') }
);

__PACKAGE__->register_method(
    method    => "fsplit",
    callback  => sub {
    my $self = shift;
    my ($dirin, $dirout, $filter, $limit, $format) =
        read_attributes([
            ['DIRSRC', 'SRC', 'SRCDIR', 'DIR', 'DIRIN', 'IN', 'DIRECTORY', 'SOURCE'],
            ['DIRDST', 'DSTDIR', 'DST', 'DEST', 'DIROUT', 'OUT', 'DESTINATION', 'TARGET'],
            ['FILTER', 'REGEXP','MASK', 'MSK', 'LISTMSK', 'LIST', 'FILE', 'FILES', 'GLOB'],
            ['LIMIT','STRINGS','ROWS','MAX','ROWMAX','N','LIM','LINES'],
            ['FORMAT', 'CALLBACK', 'CB'],
        ], @_);
    $self->error(""); # Cleanup first

    $dirin = _get_path($dirin);
    unless (-e $dirin) {
        $self->error(sprintf("Source directory not found \"%s\"", $dirin));
        return 0;
    }
    $dirout = _get_path($dirout);
    unless (-e $dirout) {
        $self->error(sprintf("Destination directory not found \"%s\"", $dirout));
        return 0;
    }
    $filter //= '';
    return 0 unless $limit;
    $format //= '[FILE].part[PART]';

    # Prepare filter (@list or $reg)
    my (@list, @inlist, $reg);
    if (ref($filter) eq 'ARRAY') { @list = @$filter } # array of globs
    elsif (ref($filter) eq 'Regexp') { $reg = $filter } # regexp
    elsif (length($filter)) { @list = ($filter) } # glob
    my $count = 0;

    # Processing
    find({ wanted => sub {
        return if -d;
        return if -B;
        return if -z;
        my $name = $_; # File name only
        my $file = $File::Find::name; # File (full path)
        my $dir = $File::Find::dir; # Directory
        return if $dir ne $dirin;
        @inlist = _expand_wildcards(@list) unless @inlist;
        if ($reg) {
            return unless $name =~ $reg;
        } elsif (@inlist) {
            return unless grep {$_ eq $name} @inlist;
        } else {
            return if length $filter;
        }

        # Start splitting!
        $self->debug(sprintf("split \"%s\" \"%s\"", $file, $dirout));
        my $fh_in = gensym;
        if (open($fh_in, "<", $name)) {
            if (flock($fh_in, LOCK_SH)) {
                $count++; # File count
                my $fpart = 0; # Parts
                my $fline = $limit; # Line
                my $fh_out = gensym;
                open $fh_out, ">-";
                while (! eof($fh_in)) { # No chomp! Leave as is!
                    my $line = readline($fh_in);
                    next unless defined($line);
                    if ($fline >= $limit) { # is limit
                        $fline = 1;
                        $fpart++;

                        # Gen out file path
                        my $dst_f = ref($format) eq 'CODE'
                            ? $format->($name, $count, $fpart)
                            : dformat($format, {
                                FILE  => $name,
                                COUNT => $count,
                                TIME  => time(),
                                PART  => $fpart,
                            });
                        next unless defined($dst_f) && length($dst_f);
                        my $dst = File::Spec->catfile($dirout, $dst_f);

                        # Make output FH
                        close($fh_out) or $self->error(sprintf("Can't close output file: %s"), $!);
                        open($fh_out, ">", $dst) or do {
                            $self->error(sprintf("Can't open file \"%s\" for writing: %s", $dst, $!));
                            next;
                        };
                        flock($fh_out, LOCK_EX) or do {
                            $self->error(sprintf("Can't lock [%d] file \"%s\" to writing: %s"), LOCK_EX, $dst, $!);
                            next;
                        };
                    } else {
                        $fline++;
                    }
                    print $fh_out $line;
                }
                close($fh_out) or $self->error(sprintf("Can't close output file: %s"), $!);
            } else {
                $self->error(sprintf("Can't lock [%d] file \"%s\" to reading: %s"), LOCK_SH, $file, $!);
            }
            close($fh_in) or $self->error(sprintf("Can't close file \"%s\": %s"), $file, $!);
        } else {
            $self->error(sprintf("Can't open file \"%s\" to reading: %s"), $file, $!);
        }
    }}, $dirin);

    return $count; # Number of files
});

__PACKAGE__->register_method(
    method    => "fjoin",
    callback  => sub {
    my $self = shift;
    my ($dirin, $dirout, $filter, $fileout, $bm, $eol) =
        read_attributes([
            ['DIRSRC', 'SRC', 'SRCDIR', 'DIR', 'DIRIN', 'IN', 'DIRECTORY', 'SOURCE'],
            ['DIRDST', 'DSTDIR', 'DST', 'DEST', 'DIROUT', 'OUT', 'DESTINATION'],
            ['FILTER', 'REGEXP','MASK', 'MSK', 'LISTMSK', 'LIST', 'FILES', 'GLOB'],
            ['FILEOUT', 'FILEDST', 'OUTFILE', 'DSTFILE', 'FILE', 'FILENAME', 'TARGET'],
            ['BINMODE', 'BIN'],
            ['EOL', 'NEWLINE', 'NL', 'CHAR', 'LFCH', 'LFCHAR', 'CRLF'],
        ], @_);
    $self->error(""); # Cleanup first

    $dirin = _get_path($dirin);
    unless (-e $dirin) {
        $self->error(sprintf("Source directory not found \"%s\"", $dirin));
        return 0;
    }
    $dirout = _get_path($dirout);
    unless (-e $dirout) {
        $self->error(sprintf("Destination directory not found \"%s\"", $dirout));
        return 0;
    }
    $filter //= '';
    $fileout //= '';
    unless (length($fileout)) {
        $self->error("Incorrect destination file for joining");
        return 0;
    }
    $fileout = File::Spec->catfile($dirout, $fileout) unless File::Spec->file_name_is_absolute($fileout);
    $bm = isTrueFlag($bm);
    $eol = "\n" unless defined($eol) && length($eol);

    # Make the name of the FileOut
    my $fh_out = gensym;
    if (open($fh_out, ">", $fileout)) {
        if (flock($fh_out, LOCK_EX)) {
            unless (!$bm || binmode($fh_out)) {
                $self->error(sprintf("Can't call binmode() for file \"%s\" to writing: %s,%s"), $fileout, $!, $^E);
                close($fh_out) or $self->error(sprintf("Can't close file \"%s\" before writing: %s"), $fileout, $!);
                return 0;
            }
        } else {
            $self->error(sprintf("Can't lock [%d] file \"%s\" to writing: %s"), LOCK_EX, $fileout, $!);
            close($fh_out) or $self->error(sprintf("Can't close file \"%s\" before writing: %s"), $fileout, $!);
            return 0;
        }
    } else {
        $self->error(sprintf("Can't open file \"%s\" to writing: %s"), $fileout, $!);
        return 0;
    }

    # Prepare filter (@list or $reg)
    my (@list, @inlist, $reg);
    if (ref($filter) eq 'ARRAY') { @list = @$filter } # array of globs
    elsif (ref($filter) eq 'Regexp') { $reg = $filter } # regexp
    elsif (length($filter)) { @list = ($filter) } # glob
    my $count = 0;

    # Processing
    find({
        preprocess => sub { sort {$a cmp $b} @_ },
        wanted => sub {
        return if -d;
        return if -B;
        return if -z;
        my $name = $_; # File name only
        my $file = $File::Find::name; # File (full path)
        my $dir = $File::Find::dir; # Directory
        return if $dir ne $dirin;
        @inlist = _expand_wildcards(@list) unless @inlist;
        if ($reg) {
            return unless $name =~ $reg;
        } elsif (@inlist) {
            return unless grep {$_ eq $name} @inlist;
        } else {
            return if length $filter;
        }
        $count++;

        # Start Joining!
        $self->debug(sprintf("join \"%s\" \"%s\"", $file, $fileout));
        my $fh_in = gensym;
        if (open($fh_in, "<", $name)) {
            if (flock($fh_in, LOCK_SH)) {
                if ($bm) { # BinMode!
                    unless (binmode($fh_in)) {
                        $self->error(sprintf("Can't call binmode() for file \"%s\" to reading: %s,%s"), $file, $!, $^E);
                        close($fh_in) or $self->error(sprintf("Can't close file \"%s\" before reading: %s"), $file, $!);
                        $count--;
                        return;
                    }
                    while (1) {
                        my $buf;
                        my ($r, $w);
                        $r = sysread($fh_in, $buf, BUFFER_SIZE);
                        last unless $r;
                        $w = syswrite($fh_out, $buf, $r) or last;
                    }
                } else { # LineMode!
                    local $/ = $eol; # Input EOL (for chomp)
                    local $\ = $eol; # Output EOL (for print)
                    while (! eof($fh_in)) {
                        my $line = readline($fh_in);
                        next unless defined($line);
                        chomp($line);
                        print $fh_out $line;
                    }
                }
                close($fh_in) or $self->error(sprintf("Can't close file \"%s\" after reading: %s"), $file, $!);
            } else {
                close($fh_in) or $self->error(sprintf("Can't close file \"%s\" before reading: %s"), $file, $!);
                $self->error(sprintf("Can't lock [%d] file \"%s\" to reading: %s"), LOCK_SH, $file, $!);
            }
        } else {
            $self->error(sprintf("Can't open file \"%s\" to reading: %s"), $file, $!);
            $count--;
        }
    }}, $dirin);

    # Close output file
    close($fh_out) or $self->error(sprintf("Can't close file \"%s\" after writing: %s"), $fileout, $!);
    unlink($fileout) if defined($fileout) && (-e $fileout) && (-z $fileout);

    return $count; # Number of files
});

sub _cpmv {
    my $self = shift;
    my ($dirin, $dirout, $filter, $format, $uniq, $op) =
        read_attributes([
            ['DIRSRC', 'SRC', 'SRCDIR', 'DIR', 'DIRIN', 'IN', 'DIRECTORY', 'SOURCE'],
            ['DIRDST', 'DSTDIR', 'DST', 'DEST', 'DIROUT', 'OUT', 'DESTINATION', 'TARGET'],
            ['FILTER', 'REGEXP','MASK', 'MSK', 'LISTMSK', 'LIST', 'FILE', 'FILES', 'GLOB'],
            ['FORMAT', 'CALLBACK', 'CB'],
            ['UNIQ', 'UNIQUE', 'DISTINCT'],
            'X_CTK_PLUGIN_OP'
        ], @_);
    $self->error(""); # Cleanup first

    $op ||= "copy"; # copy / move / remove
    $uniq = isTrueFlag($uniq); # on / off
    $dirin = _get_path($dirin);
    unless (-e $dirin) {
        $self->error(sprintf("Source directory not found \"%s\"", $dirin));
        return 0;
    }
    $dirout = _get_path($dirout);
    unless (($op eq "remove") || -e $dirout) {
        $self->error(sprintf("Destination directory not found \"%s\"", $dirout));
        return 0;
    }
    $filter //= '';
    $format //= '[FILE]';

    # Prepare filter (@list or $reg)
    my (@list, @inlist, $reg);
    if (ref($filter) eq 'ARRAY') { @list = @$filter } # array of globs
    elsif (ref($filter) eq 'Regexp') { $reg = $filter } # regexp
    elsif (length($filter)) { @list = ($filter) } # glob
    my $count = 0;

    # Processing
    find({ wanted => sub {
        return if -d;
        my $name = $_; # File name only
        my $file = $File::Find::name; # File (full path)
        my $dir = $File::Find::dir; # Directory
        return if $dir ne $dirin;
        @inlist = _expand_wildcards(@list) unless @inlist;
        if ($reg) {
            return unless $name =~ $reg;
        } elsif (@inlist) {
            return unless grep {$_ eq $name} @inlist;
        } else {
            return if length $filter;
        }
        $count++;

        # Remove first
        if ($op eq 'remove') {
            $self->debug(sprintf("remove \"%s\"", $file));
            unlink($name) or do {
                $self->error(sprintf("Can't remove file \"%s\": %s", $file, $!));
                $count--;
            };
            return;
        }

        # Make destination file name by format
        my $dst_f = ref($format) eq 'CODE'
            ? $format->($name, $count)
            : dformat($format,{
                FILE  => $name,
                COUNT => $count,
                TIME  => time(),
            });
        unless (defined($dst_f) && length($dst_f)) {
            $count--;
            return;
        }

        # Get destination file (full path)
        my $dst = File::Spec->catfile($dirout, $dst_f);
        if ($uniq && -e $dst) {
            my $src_fs = _filesize($name);
            my $dst_fs = _filesize($dst);
            if ($src_fs == $dst_fs) { # Is eq. Skip!
                $count--;
                return;
            }
        }

        # Go!
        if ($op eq 'move') { # Move
            $self->debug(sprintf("move \"%s\" \"%s\"", $file, $dst));
            move($name, $dst) or do {
                $self->error(sprintf("Move \"%s\" to \"%s\" failed: %s", $file, $dst, $!));
                $count--;
            };
        } else { # copy
            $self->debug(sprintf("copy \"%s\" \"%s\"", $file, $dst));
            copy($name, $dst) or do {
                $self->error(sprintf("Copy \"%s\" to \"%s\" failed: %s", $file, $dst, $!));
                $count--;
            };
        }
    }}, $dirin);

    return $count; # Number of files
}

sub _expand_wildcards {
    my @wildcards = grep {defined && length} @_;
    return () unless @wildcards;
    my @g = map(/[*?]/o ? (glob($_)) : ($_), @wildcards);
    return () unless @g;
    return @g;
}

sub _get_path {
    my $d = shift;
    return getcwd() unless defined($d) && length($d);
    return abs_path($d) if -e $d and -l $d;
    return File::Spec->catdir(getcwd(), $d) unless File::Spec->file_name_is_absolute($d);
    return $d;
}

sub _filesize {
    my $f = shift;
    my $filesize = 0;
    $filesize = (stat $f)[7] if -e $f;
    return $filesize // 0;
}

1;

__END__
