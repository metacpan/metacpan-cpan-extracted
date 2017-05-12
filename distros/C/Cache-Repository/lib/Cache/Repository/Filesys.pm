package Cache::Repository::Filesys;

use base 'Cache::Repository';

our $VERSION = '0.04';

use strict;
use warnings;
use File::Spec;
use File::Path;
use File::Basename;
use File::stat;
use File::Find;
use Fcntl qw(:flock);
use Carp;

=head1 NAME

Cache::Repository::Filesys - Filesystem driver for Cache::Repository

=head1 SYNOPSIS

  my $rep = Cache::Repository->new(
      style => 'Filesys',
      # options for the F::R driver
    );
  $rep->add_files(tag => 'groupname',
                  files => \@filenames,
                  basedir => '/tmp',
                  move => 1,
                 );
  $rep->add_filehandle(tag => 'anothergroup',
                       filename => 'blah',
                       filehandle => $fh,
                       mode => 0755);
  $rep->set_meta(tag => 'groupname',
                 meta => {
                     title => 'blah',
                     author => 'foo',
                 });

  $rep->retrieve(tag => 'groupname', dest => '/newdir');
  my $data = $rep->get_meta(tag => 'groupname');

=head1 DESCRIPTION

Caching in a locally-mounted filesystem.  Eventually, this will include
NFS-level locking, but for now, this module assuming only a single process
accessing the repository in write mode at a time.

=head1 FUNCTIONS

=over 4

=item new

Cache::Repository::Filesys constructor.

    my $r = Cache::Repository::Filesys->new(
                                            path => '/some/path/with/enough/space',
                                           );

or

    my $r = Cache::Repository->new(
                                   style => 'Filesys',
                                   path => '/some/path/with/enough/space',
                                  );

Parameters:

=over 4

=item path

The path in which to store the repository.

=item clear

If true, clear the repository (if it exists) to start anew.  Existing files
and meta information will all be removed.

=item compress

The compress option is ignored in the current version.

=item dir_mapping

This is a code ref which is given a tag name, and maps it to a relative
directory that should contain the tag.  The default is to use an MD5 hash of
the tag, and use that to create a directory hierarchy for the tag's contents.
You can override this to, for example, provide a more-easily-debuggable
path such as:

    dir_mapping => sub {
        my $tag = shift;
        $tag =~ s:/:_:;
        $tag;
    },

=item sector_size

=item symlink_size

Options for L<Filesys::DiskUsage>.  Defaults to the blocksize of the
directory holding the repository if L<Filesys::Statvfs> is installed,
or just simply 1024 if L<Filesys::Statvfs> is not installed.

Use 1 to get exact numbers for total file size, but this is rarely what
you really want (unless you're planning to put it in a tarball).

=back

Returns: The Cache::Repository::Filesys object, or undef if the driver failed
to initialise.

=cut

sub new
{
    my $class = shift;
    $class = ref $class || $class || __PACKAGE__;
    my %opts = @_;

    my $self = \%opts;
    bless $self, $class;

    if (exists $self->{sector_size} and $self->{sector_size} < 1)
    {
        require Carp;
        croak "sector_size must be > 0";
    }
    if (exists $self->{symlink_size} and $self->{symlink_size} < 1)
    {
        require Carp;
        croak "symlink_size must be > 0";
    }

    $self->{sector_size}  ||= $self->_default_blocksize();
    $self->{symlink_size} ||= $self->_default_blocksize();

    if (delete $self->{clear})
    {
        $self->_clear_repository();
    }
    $self;
}

my $_has_statvfs = -1;
sub _default_blocksize
{
    my $self = shift;
    eval {
        require Filesys::Statvfs;
        $_has_statvfs = 1;
        my ($bsize) = Filesys::Statvfs::statvfs($self->{path});
        return $bsize;
    } if $_has_statvfs;
    $_has_statvfs = 0;
    1024;
}

sub _clear_repository
{
    my $self = shift;
    my $path = $self->{path};

    # since $path could be a symlink, we can't blow it away.  Thus,
    # we must find everything under it, and blow those away.
    require File::Path;

    if (-d $path)
    {
        rmtree([glob File::Spec->catfile($path, '*')]);
    }
    else
    {
        mkpath([$path]);
    }
}

# figuring out the dir from the tag - that's something we would like to
# be able to change - so we'll put all such constructs here to keep it
# malleable.
sub _dir
{
    my $self = shift;
    my $tag  = shift;

    croak "No tag given" unless $tag;

    my $subdir;
    if ($self->{dir_mapping})
    {
        $subdir = $self->{dir_mapping}->($tag);
    }
    else
    {
        require Digest::MD5;
        $tag = Digest::MD5::md5_hex($tag);
        $subdir = File::Spec->catdir(
                                     substr($tag,0,2),
                                     substr($tag,2,2),
                                     $tag
                                    );
    }
    File::Spec->catdir(
                       $self->{path},
                       $subdir,
                      );
}

# when we add a file to a tag, we may want to store meta-info about it.
# filter all completed requests through here.
sub _add_file
{
    my $self = shift;
    my %opts = @_;

    #$self->{r}{$opts{tag}}{$opts{filename}} = undef;
    $self->set_meta(tag => '_r',
                    meta => { 
                        $opts{tag} => {
                            $opts{filename} => {
                                dir => $self->_dir(%opts),
                            },
                        },
                    },
                   );
}

sub _remove_tag
{
    my $self = shift;
    my %opts = @_;

    my $data = $self->get_meta(tag => '_r');
    delete $data->{$opts{tag}};
    $self->set_meta(tag => '_r',
                    reset => 1,
                    meta => $data);
}

sub _lock_meta
{
    my $self = shift;
    my $mode = shift || 'r';

    my $meta_name = do {
        unless (exists $self->{metaname})
        {
            $self->{metaname} = File::Spec->catfile($self->{path}, 'meta.info');
        }
        $self->{metaname};
    };

    my $fh = IO::File->new($meta_name, $mode);
    if ($fh)
    {
        flock($fh, $mode eq 'r' ? LOCK_SH : LOCK_EX);
    }
    $fh;
}

sub _load_meta
{
    my $self = shift;
    my $fh   = $self->_lock_meta();

    # only load it if it's been changed since the last load.
    my $s = stat($self->{metaname});
    if ($s and
        $s->mtime() >= ($self->{metastamp} || 0) and
        $fh)
    {
        local $/;
        my $data = join '', $fh->getlines();
        $self->{metastamp} = time();
        $fh->close(); # release lock

        $self->{meta} = $self->_thaw($data);
    }
}

sub _save_meta
{
    my $self = shift;
    my $fh   = $self->_lock_meta('w');

    $fh->print($self->_freeze($self->{meta}));
    $fh->close();
}

sub _thaw
{
    my $self = shift;
    my $data = shift;
    eval 'my ' . $data;
}

sub _freeze
{
    my $self = shift;
    my $data = shift;
    require Data::Dumper;
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Purity = 1;
    join '', Data::Dumper::Dumper($data);
}

=item get_meta

Overrides L<Cache::Repository>'s get_meta function

=cut

sub get_meta
{
    my $self = shift;
    my %opts = @_;

    $self->_load_meta();
    unless (exists $self->{meta}{$opts{tag}})
    {
        $self->{meta}{$opts{tag}} = {}
    }
    $self->{meta}{$opts{tag}};
}

=item set_meta

Overrides L<Cache::Repository>'s set_meta function

=cut

sub set_meta
{
    my $self = shift;
    my %opts = @_;

    #my $fh = $self->_lock_meta('w');

    $self->_load_meta();
    if ($opts{'reset'})
    {
        $self->{meta}{$opts{tag}} = {};
    }

    $self->{meta}{$opts{tag}} = {
        $self->{meta}{$opts{tag}} ? %{$self->{meta}{$opts{tag}}} : (),
        $opts{meta} ? %{$opts{meta}} : (),
    };
    $self->_save_meta();
}

=item clear_tag

=cut

sub clear_tag
{
    my $self = shift;
    my %opts = @_;

    my $path = $self->_dir($opts{tag});

    rmtree([glob ($path . '*')]);
}

=item add_symlink

=cut

sub add_symlink
{
    my $self = shift;
    my %opts = @_;

    return 0 unless $self->_is_filename_ok($opts{filename});

    my $dir  = $self->_dir($opts{tag});
    my $dstfile = File::Spec->catdir($dir, $opts{filename});
    mkpath(dirname($dstfile));

    if (symlink($opts{target}, $dstfile))
    {
        $self->_add_file(%opts);
        return 1;
    }
    undef;
}

=item add_files
=item add_filehandle

=cut

sub add_filehandle
{
    my $self = shift;
    my %opts = @_;
    my $dir  = $self->_dir($opts{tag});

    return 0 unless $self->_is_filename_ok($opts{filename});

    my $dstfile = File::Spec->catdir($dir, $opts{filename});

    mkpath(dirname($dstfile));
    #my $rc = copy($opts{filehandle}, $dstfile);
    my $rc = 0;
    {
        local $/ = \32768;
        local $_;

        if (open my $dst_h, '>', $dstfile)
        {
            binmode $dst_h;
            my $in_h = $opts{filehandle};
            print $dst_h $_ while <$in_h>;
            $rc = 1;
        }
    }

    chmod $opts{mode}, $dstfile if exists $opts{mode};
    chown $opts{owner}, $opts{group}, $dstfile
        if exists $opts{owner} and exists $opts{group};
    if ($rc)
    {
        $self->_add_file(%opts);
    }
    $rc;
}

=item retrieve_with_callback

=cut

sub retrieve_with_callback
{
    my $self = shift;
    my %opts = @_;

    my $callback = $opts{callback};
    my @files_to_extract;

    my $repos_dir = $self->_dir($opts{tag});
    return undef unless -d $repos_dir;

    if (exists $opts{files})
    {
        @files_to_extract = ref $opts{files} ? @{$opts{files}} : ($opts{files});
    }
    else
    {
        @files_to_extract = $self->list_files(%opts);
    }

    foreach my $file (@files_to_extract)
    {
        my $srcname = File::Spec->catfile($repos_dir, $file);
        my $s = stat($srcname);

        return 0 unless $s;

        my %cb_opts = (
                       mode => $s->mode(),
                       owner => $s->uid(),
                       group => $s->gid(),
                       filename => $file,
                       start => 1,
                      );
        if (-l $srcname)
        {
            $callback->(%cb_opts, target => readlink($srcname)) or return 0;
        }
        else
        {
            my $fh = IO::File->new($srcname, 'r') or return 0;
            binmode $fh;

            my $buf;
            while (my $r = sysread($fh, $buf, 32 * 1024))
            {
                $callback->(%cb_opts, data => $buf) or return 0;
                delete $cb_opts{start};
            }
            $buf = undef;
            $callback->(%cb_opts, data => undef, end => 1) or return 0;
        }
    }
    return 1;
}

=item get_size

=cut

sub get_size
{
    my $self = shift;
    my %opts = @_;

    my $repos_dir = $self->_dir($opts{tag});
    return 0 unless -d $repos_dir;

    my @files;

    if (exists $opts{files})
    {
        @files = ref $opts{files} ? @{$opts{files}} : ($opts{files});
    }
    else
    {
        @files = $self->list_files(%opts);
    }

    my $size;
    my $dir = $self->_dir($opts{tag});
    foreach my $f (@files)
    {
        my $s;
        my $fullname = File::Spec->catdir($dir, $f);
        if (-l $fullname)
        {
            $s = 1024;
        }
        else
        {
            $s = -s _;
            if ($s % 1024)
            {
                $s -= $s % 1024;
                $s += 1024;
            }
        }
        $size += $s;
    }
    $size;
}

=item list_files

=cut

sub list_files
{
    my $self = shift;
    my %opts = @_;

    my $dir = $self->_dir($opts{tag});
    my @files;

    find(
         {
             wanted => sub {
                 return unless -f $File::Find::name;
                 my $name = substr(
                                   $File::Find::name,
                                   length($dir) + 1
                                  );
                 push @files, $name;
             },
             no_chdir => 1,
         },
         $dir
        ) if -d $dir;
    wantarray ? @files : \@files;
}

=item list_tags

See L<Cache::Repository> for documentation on these.

=cut

sub list_tags
{
    my $self = shift;
    my %opts = @_;

    my $r = $self->get_meta(tag=>'_r');
    my @t = keys %$r;
    wantarray ? @t : \@t;
}

=back

=head1 AUTHOR

Darin McBride - dmcbride@cpan.org

=head1 COPYRIGHT

Copyright 2005 Darin McBride.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 BUGS

See TODO file.

=cut

1;

