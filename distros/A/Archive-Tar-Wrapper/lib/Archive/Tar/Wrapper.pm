package Archive::Tar::Wrapper;

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
use Config;
use IPC::Open3;
use Symbol 'gensym';
use Carp;

our $VERSION = '0.38';
my $logger = get_logger();

=pod

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

B<Archive::Tar::Wrapper> is an API wrapper around the C<tar> command line
program. It never stores anything in memory, but works on temporary
directory structures on disk instead. It provides a mapping between
the logical paths in the tarball and the 'real' files in the temporary
directory on disk.

It differs from L<Archive::Tar> in two ways:

=over 4

=item *

B<Archive::Tar::Wrapper> almost doesn't hold anything in memory (see C<write> method),
instead using disk as storage.

=item *

B<Archive::Tar::Wrapper> is 100% compliant with the platform's C<tar>
utility because it uses it internally.

=back

=head1 METHODS

=head2 new

    my $arch = Archive::Tar::Wrapper->new();

Constructor for the C<tar> wrapper class. Finds the C<tar> executable
by searching C<PATH> and returning the first hit. In case you want
to use a different tar executable, you can specify it as a parameter:

    my $arch = Archive::Tar::Wrapper->new(tar => '/path/to/tar');

Since B<Archive::Tar::Wrapper> creates temporary directories to store
C<tar> data, the location of the temporary directory can be specified:

    my $arch = Archive::Tar::Wrapper->new(tmpdir => '/path/to/tmpdir');

Tremendous performance increases can be achieved if the temporary
directory is located on a RAM disk. Check the L<Archive::Tar::Wrapper/Using RAM Disks>
section for details.

Additional options can be passed to the C<tar> command by using the
C<tar_read_options> and C<tar_write_options> parameters. Example:

     my $arch = Archive::Tar::Wrapper->new(
                   tar_read_options => 'p'
                );

will use C<tar xfp archive.tgz> to extract the tarball instead of just
C<tar xf archive.tgz>. GNU tar supports even more options, these can
be passed in via

     my $arch = Archive::Tar::Wrapper->new(
                    tar_gnu_read_options => ["--numeric-owner"],
                );

Similarly, C<tar_gnu_write_options> can be used to provide additional
options for GNU tar implementations. For example, the tar object

    my $tar = Archive::Tar::Wrapper->new(
                  tar_gnu_write_options => ["--exclude=foo"],
              );

will call the C<tar> utility internally like

    tar cf tarfile --exclude=foo ...

when the C<write> method gets called.

By default, the C<list_*()> functions will return only file entries:
directories will be suppressed. To have C<list_*()> return directories
as well, use

     my $arch = Archive::Tar::Wrapper->new(
                   dirs  => 1
                );

If more files are added to a tarball than the command line can handle,
B<Archive::Tar::Wrapper> will switch from using the command

    tar cfv tarfile file1 file2 file3 ...

to

    tar cfv tarfile -T filelist

where C<filelist> is a file containing all file to be added. The default
for this switch is 512, but it can be changed by setting the parameter
C<max_cmd_line_args>:

     my $arch = Archive::Tar::Wrapper->new(
         max_cmd_line_args  => 1024
     );

The expectable parameters are:

=over

=item *

tar

=item *

tmpdir

=item *

tar_read_options

=item *

tar_write_options

=item *

tar_gnu_read_options

=item *

tar_gnu_write_options

=item *

max_cmd_line_args: defaults to 512

=item *

ramdisk

=back

Returns a new instance of the class.

=cut

sub new {
    my ( $class, %options ) = @_;

    my $self = {
        tar                   => delete $options{tar} || undef,
        tmpdir                => undef,
        tar_read_options      => '',
        tar_write_options     => '',
        tar_error_msg         => undef,
        tar_gnu_read_options  => [],
        tar_gnu_write_options => [],
        dirs                  => 0,
        max_cmd_line_args     => 512,
        ramdisk               => undef,
        _os_names             => { openbsd => 'openbsd', mswin => 'MSWin32' },

        # hack used to enable unit testing
        osname      => delete $options{osname} || $Config{osname},
        bzip2_regex => qr/\.bz2$/ix,
        gzip_regex  => qr/\.t? # an optional t for matching tgz
                                    gz$ # ending with gz, which means compressed by gzip
                                    /ix,
        tar_error_msg => undef,
        version_info  => undef,
        tar_exit_code => undef,
        is_gnu        => undef,
        is_bsd        => undef,
        version_info  => undef,
        tar_exit_code => undef,
        %options,
    };

    bless $self, $class;

    unless ( defined $self->{tar} ) {

        if ( ( $self->_is_openbsd ) and ( $self->{tar_read_options} ) ) {
            $self->{tar_read_options} = '-' . $self->{tar_read_options};
        }

        if ( $self->{osname} eq 'MSWin32' ) {
            $self->_setup_mswin();
        }
        else {
            $self->{tar} = which('tar') || which('gtar');
        }

        unless ( defined $self->{tar} ) {

# this is specific for testing under MS Windows smokers without tar installed
# "OS unsupported" will mark the testing as NA instead of failure as convention.
            if ( $self->{osname} eq 'MSWin32' ) {
                LOGDIE 'tar not found in PATH, OS unsupported';
            }
            else {
                LOGDIE 'tar not found in PATH, please specify location';
            }
        }

    }

    $self->_acquire_tar_info();

    if ( defined $self->{ramdisk} ) {
        my $rc = $self->ramdisk_mount( %{ $self->{ramdisk} } );
        unless ($rc) {
            LOGDIE "Mounting ramdisk failed";
        }
        $self->{tmpdir} = $self->{ramdisk}->{tmpdir};
    }
    else {
        $self->{tmpdir} =
          tempdir( $self->{tmpdir} ? ( DIR => $self->{tmpdir} ) : () );
    }

    $self->{tardir} = File::Spec->catfile( $self->{tmpdir}, 'tar' );
    mkpath [ $self->{tardir} ], 0, oct(755)
      or LOGDIE 'Cannot create the path ' . $self->{tardir} . ": $!";
    $logger->debug( 'tardir location: ' . $self->{tardir} )
      if ( $logger->is_debug );
    $self->{objdir} = tempdir();

    return $self;
}

=head2 read

    $arch->read("archive.tgz");

C<read()> opens the given tarball, expands it into a temporary directory
and returns 1 on success or C<undef> on failure.
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

=cut

sub _is_openbsd {
    my $self = shift;
    return ( $self->{osname} eq $self->{_os_names}->{openbsd} );
}

sub _read_openbsd_opts {
    my ( $self, $compress_opt ) = @_;
    my @cmd;
    push( @cmd, $self->{tar} );

    if ($compress_opt) {

        # actually, prepending '-' would work with any modern GNU tar
        $compress_opt = '-' . $compress_opt;
        push( @cmd, $compress_opt );
    }

    push( @cmd, '-x' );
    push( @cmd, $self->{tar_read_options} )
      if ( $self->{tar_read_options} ne '' );
    push( @cmd, @{ $self->{tar_gnu_read_options} } )
      if ( scalar( @{ $self->{tar_gnu_read_options} } ) > 0 );
    return \@cmd;

}

sub read {    ## no critic (ProhibitBuiltinHomonyms)
    my ( $self, $tarfile, @files ) = @_;

    my $cwd = getcwd();

    unless ( File::Spec::Functions::file_name_is_absolute($tarfile) ) {
        $tarfile = File::Spec::Functions::rel2abs( $tarfile, $cwd );
    }

    chdir $self->{tardir}
      or LOGDIE "Cannot chdir to $self->{tardir}";

    my $compr_opt = '';    # sane value
    $compr_opt = $self->is_compressed($tarfile);

    my @cmd;

    if ( $self->_is_openbsd ) {
        @cmd = @{ $self->_read_openbsd_opts($compr_opt) };
    }
    else {
        @cmd = (
            $self->{tar},
            "${compr_opt}x$self->{tar_read_options}",
            @{ $self->{tar_gnu_read_options} },
        );
    }

    push( @cmd, '-f', $tarfile, @files );

    $logger->debug("Running @cmd") if ( $logger->is_debug );
    my $error_code = run( \@cmd, \my ( $in, $out, $err ) );

    unless ($error_code) {
        ERROR "@cmd failed: $err";
        chdir $cwd or LOGDIE "Cannot chdir to $cwd";
        return;
    }

    $logger->warn($err) if ( $logger->is_warn and $err );
    chdir $cwd or LOGDIE "Cannot chdir to $cwd: $!";
    return ( $error_code == 0 ) ? undef : $error_code;
}

=head2 list_reset

    $arch->list_reset()

Resets the list iterator. To be used before the first call to C<list_next()>.

=cut

sub list_reset {
    my ($self) = @_;

    #TODO: keep the file list as a fixed attribute of the instance
    my $list_file = File::Spec->catfile( $self->{objdir}, 'list' );
    my $cwd       = getcwd();
    chdir $self->{tardir} or LOGDIE "Can't chdir to $self->{tardir}: $!";
    open( my $fh, '>', $list_file ) or LOGDIE "Can't open $list_file: $!";

    if ( $logger->is_debug ) {
        $logger->debug('List of all files identified inside the tar file');
    }

    find(
        sub {
            my $entry = $File::Find::name;
            $entry =~ s#^\./##o;
            my $type = (
                  -d $_ ? 'd'
                : -l $_ ? 'l'
                :         'f'
            );
            print $fh "$type $entry\n";
            $logger->debug("$type $entry") if ( $logger->is_debug );
        },
        '.'
    );

    $logger->debug('All entries listed') if ( $logger->is_debug );
    close($fh);
    chdir $cwd or LOGDIE "Can't chdir to $cwd: $!";
    $self->_offset(0);
    return 1;
}

sub _read_from_tar {
    my $self = shift;
    my ( $wtr, $rdr, $err ) = ( gensym, gensym, gensym );
    my $pid = open3( $wtr, $rdr, $err, "$self->{tar} --version" );
    my ( $output, $error );

    {
        local $/ = undef;
        $output = <$rdr>;
        $error  = <$err>;
    }

    close($rdr);
    close($err);
    close($wtr);
    waitpid( $pid, 0 );
    chomp $error;
    chomp $output;
    $self->{tar_error_msg} = $error;
    $self->{version_info}  = $output;
    $self->{tar_exit_code} = $? >> 8;
    return 1;
}

sub _acquire_tar_info {
    my ( $self, $skip ) = @_;
    $self->_read_from_tar() unless ($skip);
    my $bsd_regex = qr/bsd/i;
    $self->{is_gnu} = 0;
    $self->{is_bsd} = 0;

    if ( $self->_is_openbsd() ) {

# there is no way to acquire version information from default tar program on OpenBSD
        $self->{version_info}  = "Information not available on $Config{osname}";
        $self->{tar_exit_code} = 0;
        $self->{is_bsd}        = 1;
    }
    elsif ( ( $self->{tar} =~ $bsd_regex ) and ( $self->{tar_exit_code} == 1 ) )
    {
# bsdtar exit code is 1 when asking for version, forcing to zero since is not an error
        $self->{tar_exit_code} = 0;
        $self->{is_bsd}        = 1;
    }

    $self->{version_info} = 'Information not available. Search for errors'
      unless ( $self->{tar_exit_code} == 0 );
    $self->{is_gnu} = 1 if ( $self->{version_info} =~ /GNU/ );
    return 1;
}

sub _setup_mswin {
    my $self = shift;

    # bsdtar is always preferred on Windows
    my $tar_path = which('bsdtar');
    $tar_path = which('tar') unless ( defined($tar_path) );

    if ( $tar_path =~ /\s/ ) {

        # double quoting will be required is there is a space
        $tar_path = qq($tar_path);
    }
    $self->{tar} = $tar_path;
}

=head2 tardir

    $arch->tardir();

Return the directory the tarball was unpacked in. This is sometimes useful
to play dirty tricks on B<Archive::Tar::Wrapper> by mass-manipulating
unpacked files before wrapping them back up into the tarball.

=cut

sub tardir {
    my ($self) = @_;
    return $self->{tardir};
}

=head2 is_compressed

Returns a string to identify if the tarball is compressed or not.

Expect as parameter a string with the path to the tarball.

Returns:

=over

=item *

a "z" character if the file is compressed with gzip.

=item *

a "j" character if the file is compressed with bzip2.

=item *

a "" character if the file is not compressed at all.

=back

=cut

sub is_compressed {
    my ( $self, $tarfile ) = @_;

    return 'z' if $tarfile =~ $self->{gzip_regex};
    return 'j' if $tarfile =~ $self->{bzip2_regex};

    # Sloppy check for gzip files
    open( my $fh, '<', $tarfile ) or croak("Cannot open $tarfile: $!");
    binmode($fh);
    my $read = sysread( $fh, my $two, 2, 0 )
      or croak("Cannot sysread $tarfile: $!");
    close($fh);

    return 'z'
      if (  ( ( ord( substr( $two, 0, 1 ) ) ) == 0x1F )
        and ( ( ord( substr( $two, 1, 1 ) ) ) == 0x8B ) );

    return q{};
}

=head2 locate

    $arch->locate($logic_path);

Finds the physical location of a file, specified by C<$logic_path>, which
is the virtual path of the file within the tarball. Returns a path to
the temporary file B<Archive::Tar::Wrapper> created to manipulate the
tarball on disk.

=cut

sub locate {
    my ( $self, $rel_path ) = @_;

    my $real_path = File::Spec->catfile( $self->{tardir}, $rel_path );

    if ( -e $real_path ) {
        $logger->debug("$real_path exists") if ( $logger->is_debug );
        return $real_path;
    }
    else {
        $logger->warn("$rel_path not found in tarball") if ( $logger->is_warn );
        return;
    }
}

=head2 add

    $arch->add($logic_path, $file_or_stringref, [$options]);

Add a new file to the tarball. C<$logic_path> is the virtual path
of the file within the tarball. C<$file_or_stringref> is either
a scalar, in which case it holds the physical path of a file
on disk to be transferred (i.e. copied) to the tarball, or it is
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

=cut

sub add {
    my ( $self, $rel_path, $path_or_stringref, $opts ) = @_;

    if ($opts) {
        unless ( ( ref($opts) ) and ( ref($opts) eq 'HASH' ) ) {
            LOGDIE "Option parameter given to add() not a hashref.";
        }
    }

    my ( $perm, $uid, $gid, $binmode );
    $perm    = $opts->{perm}    if defined $opts->{perm};
    $uid     = $opts->{uid}     if defined $opts->{uid};
    $gid     = $opts->{gid}     if defined $opts->{gid};
    $binmode = $opts->{binmode} if defined $opts->{binmode};

    my $target     = File::Spec->catfile( $self->{tardir}, $rel_path );
    my $target_dir = dirname($target);

    unless ( -d $target_dir ) {
        if ( ref($path_or_stringref) ) {
            $self->add( dirname($rel_path), dirname($target_dir) );
        }
        else {
            $self->add( dirname($rel_path), dirname($path_or_stringref) );
        }
    }

    if ( ref($path_or_stringref) ) {
        open my $fh, '>', $target or LOGDIE "Can't open $target: $!";
        if ( defined $binmode ) {
            binmode $fh, $binmode;
        }
        print $fh $$path_or_stringref;
        close $fh;
    }
    elsif ( -d $path_or_stringref ) {

        # perms will be fixed further down
        mkpath( $target, 0, oct(755) ) unless -d $target;
    }
    else {
        copy $path_or_stringref, $target
          or LOGDIE "Can't copy $path_or_stringref to $target ($!)";
    }

    if ( defined $uid ) {
        chown $uid, -1, $target
          or LOGDIE "Can't chown $target uid to $uid ($!)";
    }

    if ( defined $gid ) {
        chown -1, $gid, $target
          or LOGDIE "Can't chown $target gid to $gid ($!)";
    }

    if ( defined $perm ) {
        chmod $perm, $target
          or LOGDIE "Can't chmod $target to $perm ($!)";
    }

    if (    not defined $uid
        and not defined $gid
        and not defined $perm
        and not ref($path_or_stringref) )
    {
        perm_cp( $path_or_stringref, $target )
          or LOGDIE "Can't perm_cp $path_or_stringref to $target ($!)";
    }

    return 1;
}

=head2 perm_cp

Copies the permissions from a file to another.

Expects as parameters:

=over

=item 1.

string of the path to the file which permissions will be copied from.

=item 2.

string of the path to the file which permissions will be copied to.

=back

Returns 1 if everything works as expected.

=cut

sub perm_cp {
    my ( $source, $target ) = @_;
    perm_set( $target, perm_get($source) );
    return 1;
}

=head2 perm_get

Gets the permissions from a file.

Expects as parameter the path to the source file.

Returns an array reference with only the permissions values, as returned by C<stat>.

=cut

sub perm_get {
    my ($filename) = @_;
    my @stats = ( stat $filename )[ 2, 4, 5 ]
      or LOGDIE "Cannot stat $filename ($!)";
    return \@stats;
}

=head2 perm_set

Sets the permission on a file.

Expects as parameters:

=over

=item 1.

The path to the file where the permissions should be applied to.

=item 2.

An array reference with the permissions (see C<perm_set>)

=back

Returns 1 if everything goes fine.

Ignore errors here, as we can't change uid/gid unless we're the superuser (see LIMITATIONS section).

=cut

sub perm_set {
    my ( $filename, $perms ) = @_;
    chown( $perms->[1], $perms->[2], $filename );
    chmod( $perms->[0] & oct(777), $filename )
      or LOGDIE "Cannot chmod $filename ($!)";
    return 1;
}

=head2 remove

    $arch->remove($logic_path);

Removes a file from the tarball. C<$logic_path> is the virtual path
of the file within the tarball.

=cut

sub remove {
    my ( $self, $rel_path ) = @_;
    my $target = File::Spec->catfile( $self->{tardir}, $rel_path );
    rmtree($target) or LOGDIE "Can't rmtree $target: $!";
    return 1;
}

=head2 list_all

    my $items = $arch->list_all();

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

=cut

sub list_all {
    my ($self) = @_;
    my @entries = ();
    $self->list_reset();

    while ( my $entry = $self->list_next() ) {
        push @entries, $entry;
    }

    return \@entries;
}

=head2 list_next

    my ($tar_path, $phys_path, $type) = $arch->list_next();

Returns the next item in the tarfile. It returns a list of three scalars:
the relative path of the item in the tarfile, the physical path
to the unpacked file or directory on disk, and the type of the entry
(f=file, d=directory, l=symlink). Note that by default,
B<Archive::Tar::Wrapper> won't display directories, unless the C<dirs>
parameter is set when running the constructor.

=cut

sub list_next {
    my ($self) = @_;
    my $offset = $self->_offset();
    my $list_file = File::Spec->catfile( $self->{objdir}, 'list' );
    open my $fh, '<', $list_file or LOGDIE "Can't open $list_file: $!";
    seek $fh, $offset, 0;
    my $data;

  REDO: {
        my $line = <$fh>;

        unless ( defined($line) ) {
            close($fh);
        }
        else {
            chomp $line;
            my ( $type, $entry ) = split / /, $line, 2;
            redo if ( ( $type eq 'd' ) and ( not $self->{dirs} ) );
            $self->_offset( tell $fh );
            close($fh);
            $data =
              [ $entry, File::Spec->catfile( $self->{tardir}, $entry ), $type ];
        }
    }

    return $data;
}

sub _offset {
    my ( $self, $new_offset ) = @_;
    my $offset_file = File::Spec->catfile( $self->{objdir}, "offset" );

    if ( defined $new_offset ) {
        open my $fh, '>', $offset_file or LOGDIE "Can't open $offset_file: $!";
        print $fh "$new_offset\n";
        close $fh;
    }

    open my $fh, '<', $offset_file
      or LOGDIE
"Can't open $offset_file: $! (Did you call list_next() without a previous list_reset()?)";
    my $offset = <$fh>;
    chomp $offset;
    close $fh;
    return $offset;
}

=head2 write

    $arch->write($tarfile, $compress);

Write out the tarball by tarring up all temporary files and directories
and store it in C<$tarfile> on disk. If C<$compress> holds a true value,
compression is used.

=cut

sub write {    ## no critic (ProhibitBuiltinHomonyms)
    my ( $self, $tarfile, $compress ) = @_;

    my $cwd = getcwd();
    chdir $self->{tardir} or LOGDIE "Can't chdir to $self->{tardir}: $!";

    unless ( File::Spec::Functions::file_name_is_absolute($tarfile) ) {
        $tarfile = File::Spec::Functions::rel2abs( $tarfile, $cwd );
    }

    my $compr_opt = '';
    $compr_opt = 'z' if $compress;

    opendir( my $dir, '.' ) or LOGDIE "Cannot open $self->{tardir}: $!";
    my @top_entries = readdir($dir);
    closedir($dir);

    $self->_rem_dots( \@top_entries );

    my $cmd = [
        $self->{tar}, "${compr_opt}cf$self->{tar_write_options}",
        $tarfile,     @{ $self->{tar_gnu_write_options} }
    ];

    if ( @top_entries > $self->{max_cmd_line_args} ) {
        my $filelist_file = $self->{tmpdir} . "/file-list";
        open( my $fh, '>', $filelist_file )
          or LOGDIE "Cannot write to $filelist_file: $!";

        for my $entry (@top_entries) {
            print $fh "$entry\n";
        }

        close($fh);
        push @$cmd, "-T", $filelist_file;
    }
    else {
        push @$cmd, @top_entries;
    }

    $logger->debug("Running @$cmd") if ( $logger->is_debug );
    my $rc = run( $cmd, \my ( $in, $out, $err ) );

    unless ($rc) {
        ERROR "@$cmd failed: $err";
        chdir $cwd or LOGDIE "Cannot chdir to $cwd";
        return;
    }

    WARN $err if $err;
    chdir $cwd or LOGDIE "Cannot chdir to $cwd";
    return 1;
}

sub _rem_dots {
    my ( $self, $entries_ref ) = @_;
    my ( $first, $second );
    my $index = 0;
    my $found = 0;

    for ( @{$entries_ref} ) {

        if (    ( length($_) <= 2 )
            and ( ( $_ eq '.' ) or ( $_ eq '..' ) ) )
        {
            if ( $found < 1 ) {
                $first = $index;
                $found++;
                $index++;
                next;
            }
            else {
                $second = $index;
                last;
            }

        }
        else {
            $index++;
        }
    }

    splice( @{$entries_ref}, $first, 1 );

    # array length is now shortened by one
    splice( @{$entries_ref}, ( $second - 1 ), 1 );
    return 1;

}

sub DESTROY {
    my ($self) = @_;
    $self->ramdisk_unmount()  if defined $self->{ramdisk};
    rmtree( $self->{objdir} ) if defined $self->{objdir};
    rmtree( $self->{tmpdir} ) if defined $self->{tmpdir};
    return 1;
}

=head2 is_gnu

    $arch->is_gnu();

Checks if the tar executable is a GNU tar by running 'tar --version'
and parsing the output for "GNU".

Returns true or false (in Perl terms).

=cut

sub is_gnu {
    return shift->{is_gnu};
}

=head2 is_bsd

    $arch->is_bsd();

Same as C<is_gnu()>, but for BSD.

=cut

sub is_bsd {
    return shift->{is_bsd};
}

=head2 ramdisk_mount

Mounts a RAM disk.

It executes the C<mount> program under the hood to mount a RAM disk.

Expects as parameter a hash with options to mount the RAM disk, like:

=over

=item *

size

=item *

type (most probably C<tmpfs>)

=item *

tmpdir

=back

Returns 1 if everything goes fine.

Be sure to check the L<Archive::Tar::Wrapper/Using RAM Disks> for full details on using RAM disks.

=cut

sub ramdisk_mount {
    my ( $self, %options ) = @_;

    # mkdir -p /mnt/myramdisk
    # mount -t tmpfs -o size=20m tmpfs /mnt/myramdisk

    $self->{mount}  = which("mount")  unless $self->{mount};
    $self->{umount} = which("umount") unless $self->{umount};

    for (qw(mount umount)) {
        unless ( defined $self->{$_} ) {
            LOGWARN "No $_ command found in PATH";
            return;
        }
    }

    $self->{ramdisk} = {%options};
    $self->{ramdisk}->{size} = "100m"
      unless defined $self->{ramdisk}->{size};

    if ( !defined $self->{ramdisk}->{tmpdir} ) {
        $self->{ramdisk}->{tmpdir} = tempdir( CLEANUP => 1 );
    }

    my @cmd = (
        $self->{mount}, "-t", "tmpfs", "-o", "size=$self->{ramdisk}->{size}",
        "tmpfs", $self->{ramdisk}->{tmpdir}
    );

    INFO "Mounting ramdisk: @cmd";
    my $rc = system(@cmd);

    if ($rc) {

        if ( $logger->is_info ) {
            $logger->info("Mount command '@cmd' failed: $?");
            $logger->info('Note that this only works on Linux and as root');
        }
        return;
    }

    $self->{ramdisk}->{mounted} = 1;
    return 1;
}

=head2 ramdisk_unmount

Unmounts the RAM disk already mounted with C<ramdisk_mount>.

Don't expect parameters and returns 1 if everything goes fine.

Be sure to check the L<Archive::Tar::Wrapper/Using RAM Disks> for full details on using RAM disks.

=cut

sub ramdisk_unmount {
    my ($self) = @_;

    return unless ( exists $self->{ramdisk}->{mounted} );
    my @cmd = ( $self->{umount}, $self->{ramdisk}->{tmpdir} );
    $logger->info("Unmounting ramdisk: @cmd") if ( $logger->is_info );
    my $rc = system(@cmd);

    if ($rc) {
        LOGWARN "Unmount command '@cmd' failed: $?";
        return;
    }

    delete $self->{ramdisk};
    return 1;
}

1;

__END__


=head1 Using RAM Disks

On Linux, it's quite easy to create a RAM disk and achieve tremendous
speedups while untarring or modifying a tarball. You can either
create the RAM disk by hand by running

   # mkdir -p /mnt/myramdisk
   # mount -t tmpfs -o size=20m tmpfs /mnt/myramdisk

and then feeding the ramdisk as a temporary directory to
B<Archive::Tar::Wrapper>, like

   my $tar = Archive::Tar::Wrapper->new( tmpdir => '/mnt/myramdisk' );

or using B<Archive::Tar::Wrapper>'s built-in option C<ramdisk>:

   my $tar = Archive::Tar::Wrapper->new(
       ramdisk => {
           type => 'tmpfs',
           size => '20m',   # 20 MB
       },
   );

Only drawback with the latter option is that creating the RAM disk needs
to be performed as root, which often isn't desirable for security reasons.
For this reason, B<Archive::Tar::Wrapper> offers a utility functions that
mounts the RAM disk and returns the temporary directory it's located in:

    # Create new ramdisk (as root):
    my $tmpdir = Archive::Tar::Wrapper->ramdisk_mount(
        type => 'tmpfs',
        size => '20m',   # 20 MB
    );

    # Delete a ramdisk (as root):
    Archive::Tar::Wrapper->ramdisk_unmount();

Optionally, the C<ramdisk_mount()> command accepts a C<tmpdir> parameter
pointing to a temporary directory for the RAM disk if you wish to set it
yourself instead of letting B<Archive::Tar::Wrapper> create it automatically.

=head1 KNOWN LIMITATIONS

=over

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

If you ask B<Archive::Tar::Wrapper> to add a file to a tarball, it copies it
into a temporary directory and then calls the system tar to wrap up that
directory into a tarball.

This approach has limitations when it comes to file permissions: If the file to
be added belongs to a different user/group, B<Archive::Tar::Wrapper> will adjust
the uid/gid/permissions of the target file in the temporary directory to
reflect the original file's settings, to make sure the system tar will add it
like that to the tarball, just like a regular tar run on the original file
would. But this will fail of course if the original file's uid is different
from the current user's, unless the script is running with superuser rights.
The tar program by itself (without B<Archive::Tar::Wrapper>) works differently:
It'll just make a note of a file's uid/gid/permissions in the tarball (which it
can do without superuser rights) and upon extraction, it'll adjust the
permissions of newly generated files if the -p option is given (default for
superuser).

=back

=head1 BUGS

B<Archive::Tar::Wrapper> doesn't currently handle filenames with embedded
newlines.

=head2 Microsoft Windows support

Support on Microsoft Windows is limited.

Versions below Windows 10 will not be supported for desktops, and for servers
only Windows 2012 and above.

The GNU C<tar.exe> program doesn't work properly with the current interface of
B<Archive::Tar::Wrapper>.

You must use the C<bsdtar.exe> and make sure it appears first in the C<PATH>
environment variable than the GNU tar (if it is installed). See
L<http://libarchive.org/> for details about how to download and
install C<bsdtar.exe>, or go to L<http://gnuwin32.sourceforge.net/packages.html>
for a direct download. Be sure to look for the C<bzip2> program package to
install it as well.

Windows 10 might come already with C<bsdtar> program already installed. Please
search for that on the appropriate page (Microsoft keeps changing the link to
keep track of it here).

Having spaces in the path string to the tar program might be an issue too.
Although there is some effort in terms of workaround it, you best might avoid it
completely by installing in a different path than C<C:\Program Files>.
Installing both C<bsdtar> and C<bzip2> in C<C:\GnuWin32> will probably be enough
when running the installers.

=head1 LEGALESE

This software is copyright (c) 2005 of Mike Schilli.

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
Archive-Tar-Wrapper. If not, see L<http://www.gnu.org/licenses/>.

=head1 SEE ALSO

=over

=item *

Linux Gazette article from Ben Okopnik, L<issue 87|https://linuxgazette.net/87/okopnik.html>.

=back

=head1 AUTHOR

2005, Mike Schilli <cpan@perlmeister.com>

=head1 MAINTAINER

2018, Alceu Rodrigues de Freitas Junior <arfreitas@cpan.org>

=cut
