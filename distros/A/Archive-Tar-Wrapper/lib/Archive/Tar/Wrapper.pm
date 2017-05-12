###########################################
package Archive::Tar::Wrapper;
###########################################

use strict;
use warnings;
use File::Temp qw(tempdir);
use Log::Log4perl qw(:easy);
use File::Spec::Functions;
use File::Spec;
use File::Path;
use File::Copy;
use File::Find;
use File::Basename;
use File::Which qw(which);
use IPC::Run qw(run);
use Cwd;

our $VERSION = "0.23";

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        tar                   => undef,
        tmpdir                => undef,
        tar_read_options      => '',
        tar_write_options     => '',
        tar_gnu_read_options  => [],
        tar_gnu_write_options => [],
        dirs                  => 0,
        max_cmd_line_args     => 512,
        ramdisk               => undef,
        %options,
    };

    bless $self, $class;

    $self->{tar} = which("tar") unless defined $self->{tar};
    $self->{tar} = which("gtar") unless defined $self->{tar};

    if( ! defined $self->{tar} ) {
        LOGDIE "tar not found in PATH, please specify location";
    }

    if(defined $self->{ramdisk}) {
        my $rc = $self->ramdisk_mount( %{ $self->{ramdisk} } );
        if(!$rc) {
            LOGDIE "Mounting ramdisk failed";
        }
        $self->{tmpdir} = $self->{ramdisk}->{tmpdir};
    } else {
        $self->{tmpdir} = tempdir($self->{tmpdir} ? 
                                        (DIR => $self->{tmpdir}) : ());
    }

    $self->{tardir} = File::Spec->catfile($self->{tmpdir}, "tar");
    mkpath [$self->{tardir}], 0, 0755 or
        LOGDIE "Cannot mkpath $self->{tardir} ($!)";

    $self->{objdir} = tempdir();

    return $self;
}

###########################################
sub tardir {
###########################################
    my($self) = @_;

    return $self->{tardir};
}

###########################################
sub read {
###########################################
    my($self, $tarfile, @files) = @_;

    my $cwd = getcwd();

    unless(File::Spec::Functions::file_name_is_absolute($tarfile)) {
        $tarfile = File::Spec::Functions::rel2abs($tarfile, $cwd);
    }

    chdir $self->{tardir} or 
        LOGDIE "Cannot chdir to $self->{tardir}";

    my $compr_opt = "";
    $compr_opt = $self->is_compressed($tarfile);

    my $cmd = [$self->{tar}, "${compr_opt}x$self->{tar_read_options}",
               @{$self->{tar_gnu_read_options}},
               "-f", $tarfile, @files];

    DEBUG "Running @$cmd";

    my $rc = run($cmd, \my($in, $out, $err));

    if(!$rc) {
         ERROR "@$cmd failed: $err";
         chdir $cwd or LOGDIE "Cannot chdir to $cwd";
         return undef;
    }

    WARN $err if $err;

    chdir $cwd or LOGDIE "Cannot chdir to $cwd";

    return 1;
}

###########################################
sub is_compressed {
###########################################
    my($self, $tarfile) = @_;

    return 'z' if $tarfile =~ /\.t?gz$/i;
    return 'j' if $tarfile =~ /\.bz2$/i;

        # Sloppy check for gzip files
    open FILE, "<$tarfile" or die "Cannot open $tarfile";
    binmode FILE;
    my $read = sysread(FILE, my $two, 2, 0) or die "Cannot sysread";
    close FILE;
    return 'z' if 
        ord(substr($two, 0, 1)) eq 0x1F and 
        ord(substr($two, 1, 1)) eq 0x8B;

    return q{};
}

###########################################
sub locate {
###########################################
    my($self, $rel_path) = @_;

    my $real_path = File::Spec->catfile($self->{tardir}, $rel_path);

    if(-e $real_path) {
        DEBUG "$real_path exists";
        return $real_path;
    }
    DEBUG "$real_path doesn't exist";

    WARN "$rel_path not found in tarball";
    return undef;
}

###########################################
sub add {
###########################################
    my($self, $rel_path, $path_or_stringref, $opts) = @_;
            
    if($opts) {
        if(!ref($opts) or ref($opts) ne 'HASH') {
            LOGDIE "Option parameter given to add() not a hashref.";
        }
    }

    my $perm    = $opts->{perm} if defined $opts->{perm};
    my $uid     = $opts->{uid} if defined $opts->{uid};
    my $gid     = $opts->{gid} if defined $opts->{gid};
    my $binmode = $opts->{binmode} if defined $opts->{binmode};

    my $target = File::Spec->catfile($self->{tardir}, $rel_path);
    my $target_dir = dirname($target);

    if( ! -d $target_dir ) {
        if( ref($path_or_stringref) ) {
            $self->add( dirname( $rel_path ), dirname( $target_dir ) );
        } else {
            $self->add( dirname( $rel_path ), dirname( $path_or_stringref ) );
        }
    }

    if(ref($path_or_stringref)) {
        open FILE, ">$target" or LOGDIE "Can't open $target ($!)";
        if(defined $binmode) {
            binmode FILE, $binmode;
        }
        print FILE $$path_or_stringref;
        close FILE;
    } elsif( -d $path_or_stringref ) {
          # perms will be fixed further down
        mkpath($target, 0, 0755) unless -d $target;
    } else {
        copy $path_or_stringref, $target or
            LOGDIE "Can't copy $path_or_stringref to $target ($!)";
    }

    if(defined $uid) {
        chown $uid, -1, $target or
            LOGDIE "Can't chown $target uid to $uid ($!)";
    }

    if(defined $gid) {
        chown -1, $gid, $target or
            LOGDIE "Can't chown $target gid to $gid ($!)";
    }

    if(defined $perm) {
        chmod $perm, $target or 
                LOGDIE "Can't chmod $target to $perm ($!)";
    }

    if(!defined $uid and 
       !defined $gid and 
       !defined $perm and
       !ref($path_or_stringref)) {
        perm_cp($path_or_stringref, $target) or
            LOGDIE "Can't perm_cp $path_or_stringref to $target ($!)";
    }

    1;
}

######################################
sub perm_cp {
######################################
    my($source, $target) = @_;

    # Lifted from Ben Okopnik's
    # http://www.linuxgazette.com/issue87/misc/tips/cpmod.pl.txt

    my $perms = perm_get($source);
    perm_set($target, $perms);
}

######################################
sub perm_get {
######################################
    my($filename) = @_;

    my @stats = (stat $filename)[2,4,5] or
        LOGDIE "Cannot stat $filename ($!)";

    return \@stats;
}

######################################
sub perm_set {
######################################
    my($filename, $perms) = @_;

      # ignore errors here, as we can't change uid/gid unless we're
      # the superuser (see LIMITATIONS section)
    chown($perms->[1], $perms->[2], $filename);

    chmod($perms->[0] & 07777,    $filename) or
        LOGDIE "Cannot chmod $filename ($!)";
}

###########################################
sub remove {
###########################################
    my($self, $rel_path) = @_;

    my $target = File::Spec->catfile($self->{tardir}, $rel_path);

    rmtree($target) or LOGDIE "Can't rmtree $target ($!)";
}

###########################################
sub list_all {
###########################################
    my($self) = @_;

    my @entries = ();

    $self->list_reset();

    while(my $entry = $self->list_next()) {
        push @entries, $entry;
    }

    return \@entries;
}

###########################################
sub list_reset {
###########################################
    my($self) = @_;

    my $list_file = File::Spec->catfile($self->{objdir}, "list");
    open FILE, ">$list_file" or LOGDIE "Can't open $list_file";

    my $cwd = getcwd();
    chdir $self->{tardir} or LOGDIE "Can't chdir to $self->{tardir} ($!)";

    find(sub {
              my $entry = $File::Find::name;
              $entry =~ s#^\./##;
              my $type = (-d $_ ? "d" :
                          -l $_ ? "l" :
                                  "f"
                         );
              print FILE "$type $entry\n";
            }, ".");

    chdir $cwd or LOGDIE "Can't chdir to $cwd ($!)";

    close FILE;

    $self->offset(0);
}

###########################################
sub list_next {
###########################################
    my($self) = @_;

    my $offset = $self->offset();

    my $list_file = File::Spec->catfile($self->{objdir}, "list");
    open FILE, "<$list_file" or LOGDIE "Can't open $list_file";
    seek FILE, $offset, 0;

    { my $line = <FILE>;

      return undef unless defined $line;

      chomp $line;
      my($type, $entry) = split / /, $line, 2;
      redo if $type eq "d" and ! $self->{dirs};
      $self->offset(tell FILE);
      return [$entry, File::Spec->catfile($self->{tardir}, $entry), 
              $type];
    }
}

###########################################
sub offset {
###########################################
    my($self, $new_offset) = @_;

    my $offset_file = File::Spec->catfile($self->{objdir}, "offset");

    if(defined $new_offset) {
        open FILE, ">$offset_file" or LOGDIE "Can't open $offset_file";
        print FILE "$new_offset\n";
        close FILE;
    }

    open FILE, "<$offset_file" or LOGDIE "Can't open $offset_file (Did you call list_next() without a previous list_reset()?)";
    my $offset = <FILE>;
    chomp $offset;
    return $offset;
    close FILE;
}

###########################################
sub write {
###########################################
    my($self, $tarfile, $compress) = @_;

    my $cwd = getcwd();
    chdir $self->{tardir} or LOGDIE "Can't chdir to $self->{tardir} ($!)";

    unless(File::Spec::Functions::file_name_is_absolute($tarfile)) {
        $tarfile = File::Spec::Functions::rel2abs($tarfile, $cwd);
    }

    my $compr_opt = "";
    $compr_opt = "z" if $compress;

    opendir DIR, "." or LOGDIE "Cannot open $self->{tardir}";
    my @top_entries = grep { $_ !~ /^\.\.?$/ } readdir DIR;
    closedir DIR;

    my $cmd = [$self->{tar}, "${compr_opt}cf$self->{tar_write_options}",
               $tarfile, @{$self->{tar_gnu_write_options}}];

    if(@top_entries > $self->{max_cmd_line_args}) {
        my $filelist_file = $self->{tmpdir}."/file-list";
        open FLIST, ">$filelist_file" or 
            LOGDIE "Cannot open $filelist_file ($!)";
        for(@top_entries) {
            print FLIST "$_\n";
        }
        close FLIST;
        push @$cmd, "-T", $filelist_file;
    } else {
        push @$cmd, @top_entries;
    }

    DEBUG "Running @$cmd";
    my $rc = run($cmd, \my($in, $out, $err));

    if(!$rc) {
         ERROR "@$cmd failed: $err";
         chdir $cwd or LOGDIE "Cannot chdir to $cwd";
         return undef;
    }

    WARN $err if $err;

    chdir $cwd or LOGDIE "Cannot chdir to $cwd";

    return 1;
}

###########################################
sub DESTROY {
###########################################
    my($self) = @_;

    $self->ramdisk_unmount() if defined  $self->{ramdisk};

    rmtree($self->{objdir}) if defined $self->{objdir};
    rmtree($self->{tmpdir}) if defined $self->{tmpdir};
}

###########################################
sub is_gnu {
###########################################
    my($self) = @_;

    open PIPE, "$self->{tar} --version |" or 
        return 0;

    my $output = join "\n", <PIPE>;
    close PIPE;

    return $output =~ /GNU/;
}

###########################################
sub ramdisk_mount {
###########################################
    my($self, %options) = @_;

      # mkdir -p /mnt/myramdisk
      # mount -t tmpfs -o size=20m tmpfs /mnt/myramdisk

     $self->{mount}  = which("mount") unless $self->{mount};
     $self->{umount} = which("umount") unless $self->{umount};

     for (qw(mount umount)) {
         if(!defined $self->{$_}) {
             LOGWARN "No $_ command found in PATH";
             return undef;
         }
     }

     $self->{ramdisk} = { %options };
 
     $self->{ramdisk}->{size} = "100m" unless 
       defined $self->{ramdisk}->{size};
 
     if(! defined $self->{ramdisk}->{tmpdir}) {
         $self->{ramdisk}->{tmpdir} = tempdir( CLEANUP => 1 );
     }
 
     my @cmd = ($self->{mount}, 
                "-t", "tmpfs", "-o", "size=$self->{ramdisk}->{size}",
                "tmpfs", $self->{ramdisk}->{tmpdir});

     INFO "Mounting ramdisk: @cmd";
     my $rc = system( @cmd );
 
    if($rc) {
        LOGWARN "Mount command '@cmd' failed: $?";
        LOGWARN "Note that this only works on Linux and as root";
        return;
    }
 
    $self->{ramdisk}->{mounted} = 1;
 
    return 1;
}

###########################################
sub ramdisk_unmount {
###########################################
    my($self) = @_;

    return if !exists $self->{ramdisk}->{mounted};

    my @cmd = ($self->{umount}, $self->{ramdisk}->{tmpdir});

    INFO "Unmounting ramdisk: @cmd";

    my $rc = system( @cmd );
        
    if($rc) {
        LOGWARN "Unmount command '@cmd' failed: $?";
        return;
    }

    delete $self->{ramdisk};
    return 1;
}

1;

__END__

=head1 NAME

Archive::Tar::Wrapper - API wrapper around the 'tar' utility

=head1 SYNOPSIS

    use Archive::Tar::Wrapper;

    my $arch = Archive::Tar::Wrapper->new();

        # Open a tarball, expand it into a temporary directory
    $arch->read("archive.tgz");

        # Iterate over all entries in the archive
    $arch->list_reset(); # Reset Iterator
                         # Iterate through archive
    while(my $entry = $arch->list_next()) {
        my($tar_path, $phys_path) = @$entry;
        print "$tar_path\n";
    }

        # Get a huge list with all entries
    for my $entry (@{$arch->list_all()}) {
        my($tar_path, $real_path) = @$entry;
        print "Tarpath: $tar_path Tempfile: $real_path\n";
    }

        # Add a new entry
    $arch->add($logic_path, $file_or_stringref);

        # Remove an entry
    $arch->remove($logic_path);

        # Find the physical location of a temporary file
    my($tmp_path) = $arch->locate($tar_path);

        # Create a tarball
    $arch->write($tarfile, $compress);

=head1 DESCRIPTION

Archive::Tar::Wrapper is an API wrapper around the 'tar' command line
utility. It never stores anything in memory, but works on temporary
directory structures on disk instead. It provides a mapping between
the logical paths in the tarball and the 'real' files in the temporary
directory on disk.

It differs from Archive::Tar in two ways:

=over 4

=item *

Archive::Tar::Wrapper doesn't hold anything in memory. Everything is
stored on disk. 

=item *

Archive::Tar::Wrapper is 100% compliant with the platform's C<tar> 
utility, because it uses it internally.

=back

=head1 METHODS

=over 4

=item B<my $arch = Archive::Tar::Wrapper-E<gt>new()>

Constructor for the tar wrapper class. Finds the C<tar> executable
by searching C<PATH> and returning the first hit. In case you want
to use a different tar executable, you can specify it as a parameter:

    my $arch = Archive::Tar::Wrapper->new(tar => '/path/to/tar');

Since C<Archive::Tar::Wrapper> creates temporary directories to store
tar data, the location of the temporary directory can be specified:

    my $arch = Archive::Tar::Wrapper->new(tmpdir => '/path/to/tmpdir');

Tremendous performance increases can be achieved if the temporary 
directory is located on a ram disk. Check the "Using RAM Disks" 
section below for details.

Additional options can be passed to the C<tar> command by using the
C<tar_read_options> and C<tar_write_options> parameters. Example:

     my $arch = Archive::Tar::Wrapper->new(
                   tar_read_options => "p"
                );

will use C<tar xfp archive.tgz> to extract the tarball instead of just
C<tar xf archive.tgz>. Gnu tar supports even more options, these can
be passed in via

     my $arch = Archive::Tar::Wrapper->new(
                    tar_gnu_read_options => ["--numeric-owner"],
                );

Similarily, C<tar_gnu_write_options> can be used to provide additional
options for Gnu tar implementations. For example, the tar object

    my $tar = Archive::Tar::Wrapper->new(
                  tar_gnu_write_options => ["--exclude=foo"],
              );

will call the C<tar> utility internally like

    tar cf tarfile --exclude=foo ...

when the C<write> method gets called.

By default, the C<list_*()> functions will return only file entries. 
Directories will be suppressed. To have C<list_*()> 
return directories as well, use

     my $arch = Archive::Tar::Wrapper->new(
                   dirs  => 1
                );

If more files are added to a tarball than the command line can handle,
C<Archive::Tar::Wrapper> will switch from using the command

    tar cfv tarfile file1 file2 file3 ...

to

    tar cfv tarfile -T filelist

where C<filelist> is a file containing all file to be added. The default
for this switch is 512, but it can be changed by setting the parameter
C<max_cmd_line_args>:

     my $arch = Archive::Tar::Wrapper->new(
         max_cmd_line_args  => 1024
     );

=item B<$arch-E<gt>read("archive.tgz")>

C<read()> opens the given tarball, expands it into a temporary directory
and returns 1 on success und C<undef> on failure. 
The temporary directory holding the tar data gets cleaned up when C<$arch>
goes out of scope.

C<read> handles both compressed and uncompressed files. To find out if
a file is compressed or uncompressed, it tries to guess by extension,
then by checking the first couple of bytes in the tarfile.

If only a limited number of files is needed from a tarball, they
can be specified after the tarball name:

    $arch->read("archive.tgz", "path/file.dat", "path/sub/another.txt");

The file names are passed unmodified to the C<tar> command, make sure
that the file paths match exactly what's in the tarball, otherwise
C<read()> will fail.

=item B<$arch-E<gt>list_reset()>

Resets the list iterator. To be used before the first call to
B<$arch->list_next()>.

=item B<my($tar_path, $phys_path, $type) = $arch-E<gt>list_next()>

Returns the next item in the tarfile. It returns a list of three scalars:
the relative path of the item in the tarfile, the physical path
to the unpacked file or directory on disk, and the type of the entry
(f=file, d=directory, l=symlink). Note that by default, 
Archive::Tar::Wrapper won't display directories, unless the C<dirs>
parameter is set when running the constructor.

=item B<my $items = $arch-E<gt>list_all()>

Returns a reference to a (possibly huge) array of items in the
tarfile. Each item is a reference to an array, containing two
elements: the relative path of the item in the tarfile and the
physical path to the unpacked file or directory on disk.

To iterate over the list, the following construct can be used:

        # Get a huge list with all entries
    for my $entry (@{$arch->list_all()}) {
        my($tar_path, $real_path) = @$entry;
        print "Tarpath: $tar_path Tempfile: $real_path\n";
    }

If the list of items in the tarfile is big, use C<list_reset()> and
C<list_next()> instead of C<list_all>.

=item B<$arch-E<gt>add($logic_path, $file_or_stringref, [$options])>

Add a new file to the tarball. C<$logic_path> is the virtual path
of the file within the tarball. C<$file_or_stringref> is either
a scalar, in which case it holds the physical path of a file
on disk to be transferred (i.e. copied) to the tarball. Or it is
a reference to a scalar, in which case its content is interpreted
to be the data of the file.

If no additional parameters are given, permissions and user/group 
id settings of a file to be added are copied. If you want different
settings, specify them in the options hash:

    $arch->add($logic_path, $stringref, 
               { perm => 0755, uid => 123, gid => 10 });

If $file_or_stringref is a reference to a Unicode string, the C<binmode>
option has to be set to make sure the string gets written as proper UTF-8
into the tarfile:

    $arch->add($logic_path, $stringref, { binmode => ":utf8" });

=item B<$arch-E<gt>remove($logic_path)>

Removes a file from the tarball. C<$logic_path> is the virtual path
of the file within the tarball.

=item B<$arch-E<gt>locate($logic_path)>

Finds the physical location of a file, specified by C<$logic_path>, which
is the virtual path of the file within the tarball. Returns a path to 
the temporary file C<Archive::Tar::Wrapper> created to manipulate the
tarball on disk.

=item B<$arch-E<gt>write($tarfile, $compress)>

Write out the tarball by tarring up all temporary files and directories
and store it in C<$tarfile> on disk. If C<$compress> holds a true value,
compression is used.

=item B<$arch-E<gt>tardir()>

Return the directory the tarball was unpacked in. This is sometimes useful
to play dirty tricks on C<Archive::Tar::Wrapper> by mass-manipulating
unpacked files before wrapping them back up into the tarball.

=item B<$arch-E<gt>is_gnu()>

Checks if the tar executable is a GNU tar by running 'tar --version'
and parsing the output for "GNU".

=back

=head1 Using RAM Disks

On Linux, it's quite easy to create a RAM disk and achieve tremendous
speedups while untarring or modifying a tarball. You can either
create the RAM disk by hand by running

   # mkdir -p /mnt/myramdisk
   # mount -t tmpfs -o size=20m tmpfs /mnt/myramdisk

and then feeding the ramdisk as a temporary directory to 
Archive::Tar::Wrapper, like

   my $tar = Archive::Tar::Wrapper->new( tmpdir => '/mnt/myramdisk' );

or using Archive::Tar::Wrapper's built-in option 'ramdisk':

   my $tar = Archive::Tar::Wrapper->new( 
       ramdisk => { 
           type => 'tmpfs',
           size => '20m',   # 20 MB
       },
   );

Only drawback with the latter option is that creating the RAM disk needs
to be performed as root, which often isn't desirable for security reasons.
For this reason, Archive::Tar::Wrapper offers a utility functions that
mounts the ramdisk and returns the temporary directory it's located in:

      # Create new ramdisk (as root):
    my $tmpdir = Archive::Tar::Wrapper->ramdisk_mount(
        type => 'tmpfs',
        size => '20m',   # 20 MB
    );

      # Delete a ramdisk (as root):
    Archive::Tar::Wrapper->ramdisk_unmount();

Optionally, the C<ramdisk_mount()> command accepts a C<tmpdir> parameter
pointing to a temporary directory for the ramdisk if you wish to set it
yourself instead of letting Archive::Tar::Wrapper create it automatically.

=head1 KNOWN LIMITATIONS

=over 4

=item *

Currently, only C<tar> programs supporting the C<z> option (for 
compressing/decompressing) are supported. Future version will use
C<gzip> alternatively.

=item *

Currently, you can't add empty directories to a tarball directly.
You could add a temporary file within a directory, and then
C<remove()> the file.

=item *

If you delete a file, the empty directories it was located in 
stay in the tarball. You could try to C<locate()> them and delete
them. This will be fixed, though.

=item *

Filenames containing newlines are causing problems with the list
iterators. To be fixed.

=item *

If you ask Archive::Tar::Wrapper to add a file to a tarball, it copies it into
a temporary directory and then calls the system tar to wrap up that directory
into a tarball.

This approach has limitations when it comes to file permissions: If the file to
be added belongs to a different user/group, Archive::Tar::Wrapper will adjust
the uid/gid/permissions of the target file in the temporary directory to
reflect the original file's settings, to make sure the system tar will add it
like that to the tarball, just like a regular tar run on the original file
would. But this will fail of course if the original file's uid is different
from the current user's, unless the script is running with superuser rights.
The tar program by itself (without Archive::Tar::Wrapper) works differently:
It'll just make a note of a file's uid/gid/permissions in the tarball (which it
can do without superuser rights) and upon extraction, it'll adjust the
permissions of newly generated files if the -p option is given (default for
superuser).

=back

=head1 BUGS

Archive::Tar::Wrapper doesn't currently handle filenames with embedded
newlines.

=head1 LEGALESE

Copyright 2005 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <cpan@perlmeister.com>
