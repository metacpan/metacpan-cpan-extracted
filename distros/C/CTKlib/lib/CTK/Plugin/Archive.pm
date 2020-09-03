package CTK::Plugin::Archive;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::Plugin::Archive - Archive plugin

=head1 VERSION

Version 1.02

=head1 SYNOPSIS

    use CTK;
    my $ctk = new CTK(
            plugins => "archive",
        );

    my $n = $ctk->fcompress(
        -dirsrc => "/path/to/source/dir", # Source directory
        -glob   => "*.txt",
        -arcdef => "targz",
        -archive=> "archive.tar.gz",
    );

    my $n = $ctk->fextract(
        -dirsrc => "/path/to/source/dir", # Source directory
        -dirdst => "/path/to/destination/dir", # Destination directory
        -file   => "archive.tar.gz",
        -arcdef => "targz",
    );

=head1 DESCRIPTION

Archive (compress and decompress) plugin

Allowed arcdefs: targz, tarxz, tarbz2, tgz, gz, zip, rar

Default arcdef: targz

=head1 METHODS

=over 8

=item B<fcompress>

    my $n = $ctk->fcompress(
        -dirsrc => "/path/to/source/dir", # Source directory
        -glob   => "*.txt",
        -arcdef => "targz",
        -archive=> "archive.tar.gz",
    );

Сompressing files

=over 8

=item B<-dirin>, B<-in>, B<-dirsrc>, B<-src>, B<-source>

Specifies source directory

Default: current directory

=item B<-file>, B<-fileout>, B<-archive>, B<-target>

Specifies target archive file

Required parameter

=item B<-list>, B<-mask>, B<-glob>, B<-files>, B<-regexp>

    -list => [qw/ file1.txt file2.txt file3.* /]

List of files or globs

    -glob => "file.*"

Glob pattern

    -file => "file1.txt"

Name of file

    -regexp => qr/\.(cgi|pl)$/i

Regexp

Default: undef (all files)

=item B<-options>, B<-opts>, B<-arcdef>, B<-arcopts>, B<-arcname>

Defines section of archive options or arcname, for example:

    {
        "ext"        => ".tar.gz",
        "create"     => "tar -cpf \"[NAME].tar\" [LIST]",
        "append"     => "tar -rpf \"[NAME].tar\" [LIST]",
        "postprocess"=> "gzip \"[NAME].tar\"",
        "extract"    => "tar -zxpf \"[FILE]\" -C \"[DIRDST]\"",
    }

or:

    targz

Default: targz

=back

Replacing keys: FILE, NAME, EXT, LIST

=item B<fextract>

    my $n = $ctk->fextract(
        -dirsrc => "/path/to/source/dir", # Source directory
        -dirdst => "/path/to/destination/dir", # Destination directory
        -file   => "archive.tar.gz",
        -arcdef => "targz",
    );

Extracting files

=over 8

=item B<-dirin>, B<-in>, B<-dirsrc>, B<-src>, B<-source>

Specifies source directory

Default: current directory

=item B<-dirout>, B<-out>, B<-dirdst>, B<-dst>, B<-target>

Specifies destination directory

Default: current directory

=item B<-list>, B<-mask>, B<-glob>, B<-files>, B<-regexp>

    -list => [qw/ file1.zip file2.zip foo*.zip /]

List of files or globs

    -glob => "*.zip"

Glob pattern

    -file => "file1.zip"

Name of file

    -regexp => qr/\.(zip|zip2)$/i

Regexp

Default: undef (all files)

=item B<-options>, B<-opts>, B<-arcdef>, B<-arcopts>, B<-arcname>

Defines section of archive options or arcname, for example:

    {
        "ext"        => ".tar.gz",
        "create"     => "tar -cpf \"[NAME].tar\" [LIST]",
        "append"     => "tar -rpf \"[NAME].tar\" [LIST]",
        "postprocess"=> "gzip \"[NAME].tar\"",
        "extract"    => "tar -zxpf \"[FILE]\" -C \"[DIRDST]\"",
    }

or:

    targz

Default: targz

=back

Replacing keys: FILE, DIRDST, FILEOUT

=back

=head2 REPLACING KEYS

=over 8

=item B<FILE>

File with path

In fcompress - destination file; in fextract - souce file

=item B<FILEOUT>

Output file with path. For fextract only!

=item B<NAME>

Filename only (with path!). For fcompress only

=item B<DIRDST>

Destination directory for extracting files. For fextract only!

=item B<EXT>

File extension only. For fcompress only

=item B<LIST>

List of source files or one file. For fcompress only

=back

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<CTK>, L<CTK::Plugin>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK>, L<CTK::Plugin>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2020 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION /;
$VERSION = '1.02';

use base qw/CTK::Plugin/;

use CTK::Util qw/ :API :FORMAT :FILE :EXT /;
use Carp;
use File::Spec;
use File::Find;
use Cwd qw/getcwd abs_path/;

use constant {
    ARC_DEFAULT => "targz",
    ARC_OPTIONS => {
        targz =>  {
            "ext"        => ".tar.gz",
            "create"     => "tar -cpf \"[NAME].tar\" \"[LIST]\"",
            "append"     => "tar -rpf \"[NAME].tar\" \"[LIST]\"",
            "postprocess"=> "gzip \"[NAME].tar\"",
            "extract"    => "tar -zxpf \"[FILE]\" -C \"[DIRDST]\"",
        },
        tgz   =>  {
            "ext"        => ".tgz",
            "create"     => "tar -cpf \"[NAME].tar\" \"[LIST]\"",
            "append"     => "tar -rpf \"[NAME].tar\" \"[LIST]\"",
            "postprocess"=> [
                    "gzip \"[NAME].tar\"",
                    "mv \"[NAME].tar.gz\" \"[NAME].tgz\"",
                ],
            "extract"    => "tar -zxpf \"[FILE]\" -C \"[DIRDST]\"",
        },
        tar   =>  {
            "ext"        => ".tar",
            "create"     => "tar -cpf \"[FILE]\" \"[LIST]\"",
            "append"     => "tar -rpf \"[FILE]\" \"[LIST]\"",
            "extract"    => "tar -xpf \"[FILE]\" -C \"[DIRDST]\"",
        },
        gz   =>  {
            "ext"        => ".gz",
            "create"     => "gzip -c \"[LIST]\" > \"[FILE]\"",
            "extract"    => "cp \"[FILE]\" \"[FILEOUT]\" && cd \"[DIRDST]\" && gunzip \"[FILE]\"",
        },
        tarbz2 =>  {
            "ext"        => ".tar.bz2",
            "create"     => "tar -cpf \"[NAME].tar\" \"[LIST]\"",
            "append"     => "tar -rpf \"[NAME].tar\" \"[LIST]\"",
            "postprocess"=> "bzip2 \"[NAME].tar\"",
            "extract"    => "tar -jxpf \"[FILE]\" -C \"[DIRDST]\"",
        },
        tarxz =>  {
            "ext"        => ".tar.xz",
            "create"     => "tar -cpf \"[NAME].tar\" \"[LIST]\"",
            "append"     => "tar -rpf \"[NAME].tar\" \"[LIST]\"",
            "postprocess"=> "xz \"[NAME].tar\"",
            "extract"    => "tar -Jxpf \"[FILE]\" -C \"[DIRDST]\"",
        },
        zip   => {
            "ext"        => ".zip",
            "create"     => $^O =~ /mswin/i ? "zip -rqq \"[FILE]\" \"[LIST]\"" : "zip -rqqy \"[FILE]\" \"[LIST]\"",
            "extract"    => $^O =~ /mswin/i ? "unzip -uqqoX \"[FILE]\" -d \"[DIRDST]\"" : "unzip -uqqoX \"[FILE]\" -d \"[DIRDST]\"",
        },
        rar   => {
            "ext"        => ".rar",
            "create"     => $^O =~ /mswin/i ? "rar a \"[FILE]\" \"[LIST]\"" : "rar a \"[FILE]\" \"[LIST]\"",
            "extract"    => "rar x -y \"[FILE]\" \"[DIRDST]\"",
        }
    },
};

__PACKAGE__->register_method(
    method    => "fcompress",
    callback  => sub {
    my $self = shift;
    my ($dirin, $fileout, $filter, $arcdef) =
        read_attributes([
            ['DIRSRC', 'SRC', 'SRCDIR', 'DIR', 'DIRIN', 'IN', 'DIRECTORY', 'SOURCE'],
            ['FILEOUT', 'FILEDST', 'OUTFILE', 'DSTFILE', 'FILE', 'FILENAME', 'ARCHIVE', 'TARGET'],
            ['FILTER', 'REGEXP','MASK', 'MSK', 'LISTMSK', 'LIST', 'FILES', 'GLOB'],
            ['OPTIONS', 'OPTS', 'ARCDEF', 'ARCOPTS', 'NAME', 'ARCNAME'],
        ], @_);
    $self->error(""); # Cleanup first

    $dirin = _get_path($dirin);
    unless (-e $dirin) {
        $self->error(sprintf("Source directory not found \"%s\"", $dirin));
        return 0;
    }
    $fileout //= '';
    unless (length($fileout)) {
        $self->error("Incorrect destination file for joining");
        return 0;
    }
    $fileout = File::Spec->catfile(getcwd(), $fileout) unless File::Spec->file_name_is_absolute($fileout);
    $filter //= '';

    # ArcDef
    $arcdef ||= ARC_DEFAULT;
    if (ref($arcdef) ne 'HASH') { $arcdef = ARC_OPTIONS()->{$arcdef} || {} };
    my $arc_create = $arcdef->{create};
    unless ($arc_create) {
        $self->error("Incorrect \"create\" archive definition");
        return 0;
    }
    my $arc_append = $arcdef->{append} || $arc_create;
    my $arc_ext = $arcdef->{ext};
    my $arc_proc = $arcdef->{postprocess};

    # Output data
    my ($fname, $fext) = _splitFile($fileout, $arc_ext);

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

        # Compress (create or add)
        #printf "#%d Dir: %s; Name: %s; File: %s\n", $count, $dir, $name, $file;
        my $cmd = dformat($count ? $arc_append : $arc_create, {
                FILE    => $fileout,
                LIST    => $name,
                NAME    => $fname,
                EXT     => $fext,
            });
        $self->debug($cmd);
        my $errdata = "";
        my $outdata = execute( $cmd, undef, \$errdata, 1 );
        $self->debug($outdata) if defined($outdata) && length($outdata);
        $self->error($errdata) if defined($errdata) && length($errdata);
        $count++;
    }}, $dirin);
    return 0 unless $count; # No files found

    # PostProcessing
    my @postproc;
    if ($arc_proc && ref($arc_proc) eq "ARRAY") {@postproc = @$arc_proc}
    elsif ($arc_proc) {@postproc = ($arc_proc)}
    foreach my $proc (@postproc) {
        next unless $proc;
        my $cmd = dformat($proc, {
                FILE    => $fileout,
                NAME    => $fname,
                EXT     => $fext,
            });
        $self->debug($cmd);
        my $errdata = "";
        my $outdata = execute( $cmd, undef, \$errdata, 1 );
        $self->debug($outdata) if defined($outdata) && length($outdata);
        $self->error($errdata) if defined($errdata) && length($errdata);
    }

    return $count; # Number of files
});

__PACKAGE__->register_method(
    method    => "fextract",
    callback  => sub {
    my $self = shift;
    my ($dirin, $dirout, $filter, $arcdef) =
        read_attributes([
            ['DIRSRC', 'SRC', 'SRCDIR', 'DIR', 'DIRIN', 'IN', 'DIRECTORY', 'SOURCE'],
            ['DIRDST', 'DSTDIR', 'DST', 'DEST', 'DIROUT', 'OUT', 'DESTINATION', 'TARGET'],
            ['FILTER', 'REGEXP','MASK', 'MSK', 'LISTMSK', 'LIST', 'FILE', 'FILES', 'GLOB'],
            ['OPTIONS', 'OPTS', 'ARCDEF', 'ARCOPTS', 'NAME', 'ARCNAME'],
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

    # ArcDef
    $arcdef ||= ARC_DEFAULT;
    if (ref($arcdef) ne 'HASH') { $arcdef = ARC_OPTIONS()->{$arcdef} || {} };
    my $arc_extract = $arcdef->{extract};
    unless ($arc_extract) {
        $self->error("Incorrect \"extract\" archive definition");
        return 0;
    }

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

        # Extract
        #printf "#%d Dir: %s; Name: %s; File: %s\n", $count, $dir, $name, $file;
        my $cmd = dformat($arc_extract, {
                FILE    => $name,
                DIRDST  => $dirout,
                DIROUT  => $dirout,
                FILEOUT => File::Spec->catfile($dirout, $name),
            });
        $self->debug($cmd);
        my $errdata = "";
        my $outdata = execute( $cmd, undef, \$errdata, 1 );
        $self->debug($outdata) if defined($outdata) && length($outdata);
        $self->error($errdata) if defined($errdata) && length($errdata);

        $count++;
    }}, $dirin);

    return $count; # Number of files
});

sub _expand_wildcards {
    my @wildcards = grep {defined && length} @_;
    return () unless @wildcards;
    my @g = map(/[*?]/o ? (glob($_)) : ($_), @wildcards);
    return () unless @g;
    return @g;
}

sub _splitFile { # ("foo.txt", ".txt") -> ("foo", ".txt")
    my $file = shift // return ("","");
    my $ext  = shift;
    unless (defined($ext) && length($ext)) {
        $file =~ s/(\.[a-z0-9]+)$//;
        return ($file, $1 // "");
    }
    my $p = index($file, $ext);
    if ($p > 0) {
        return (substr($file, 0, $p), substr($file, $p));
    }
}

sub _get_path {
    my $d = shift;
    return getcwd() unless defined($d) && length($d);
    return abs_path($d) if -e $d and -l $d;
    return File::Spec->catdir(getcwd(), $d) unless File::Spec->file_name_is_absolute($d);
    return $d;
}

1;

__END__
