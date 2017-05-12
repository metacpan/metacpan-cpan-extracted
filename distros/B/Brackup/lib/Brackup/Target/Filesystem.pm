package Brackup::Target::Filesystem;
use strict;
use warnings;
use base 'Brackup::Target::Filebased';
use File::Basename;
use File::Find ();
use File::Path;
use File::stat ();
use Brackup::Util qw(io_print_to_fh);


sub new {
    my ($class, $confsec) = @_;
    my $self = $class->SUPER::new($confsec);

    $self->{path} = $confsec->path_value("path");
    $self->{nocolons} = $confsec->value("no_filename_colons");

    # LAME: Make it work on Windows
    $self->{nocolons} = ($^O eq 'MSWin32') unless defined $self->{nocolons};

    # see if we're operating in a pre-1.06 environment
    if (opendir(my $dh, $self->{path})) {
        $self->{_no_four_hex_dirs_in_root} = 1;
        while (my $file = readdir($dh)) {
            if ($file =~ /^[0-9a-f]{4}$/) {
                $self->{_no_four_hex_dirs_in_root} = 0;
            }
        }
    }

    if ($ENV{BRACKUP_REARRANGE_FS_TARGET}) {
        $self->_upgrade_layout;
    }

    return $self;
}

sub new_from_backup_header {
    my ($class, $header) = @_;
    my $self = bless {}, $class;
    $self->{path} = $header->{"BackupPath"} or
        die "No BackupPath specified in the backup metafile.\n";
    $self->{nocolons} = $header->{"NoColons"} or 0;
    unless (-d $self->{path}) {
        die "Restore path $self->{path} doesn't exist.\n";
    }
    return $self;
}

sub nocolons {
    my ($self) = @_;
    return $self->{nocolons};
}

sub backup_header {
    my $self = shift;
    return {
        "BackupPath" => $self->{path},
        "NoColons" => $self->{nocolons}?"1":"0",
    };
}

# 1.05 and before stored files on disk as: xxxx/xxxx/xxxxxxxxxx.brackup
# (that is, two levels of directories, each 4 hex digits long, or 65536
# files per directory, which is 2x what ext3 can store, leading to errors.
# in 1.06 and above, xx/xx/xxxxxx is used.  that is, two levels of 2 hex
# digits.  this function
sub _upgrade_layout {
    my $self = shift;
    my $clean_limit = shift; # optional; if set, max top-level dirs to clean

    my $root = $self->{path};

    opendir(my $dh, $root) or die "Error opening $root: $!";

    # read the current state of things in the root directory
    # (which is presumably maxed out on files, at 32k or whatnot)
    my %exist_twodir;    # two_dir -> 1 (which two-letter directories exist)
    my %exist_fourdir;   # four_dir -> 1 (which four-letter directories exist)
    my %four_of_two;     # two_dir -> [ four_dir, four_dir, ... ]
    while (my $dir = readdir($dh)) {
        next unless -d "$root/$dir";
        if ($dir =~ /^[0-9a-f]{2}$/) {
            $exist_twodir{$dir} = 1;
            next;
        }
        if ($dir =~ /^([0-9a-f]{2})([0-9a-f]{2})$/) {
            $exist_fourdir{"$1$2"} = 1;
            push @{ $four_of_two{$1} ||= [] }, "$1$2";
        }
    }

    # for each 4-digit directory, sorted by number of four-digit directories
    # that exist for their leading 2-digit prefix (to most quickly free up
    # a link in root, in 2 iterations),
    # see if the "01/" directory exists (the leading two bytes).
    # if not,
    #    move it to some random other 'xxxx' directory,
    #    as, say, "abcd/tmp-was-root-0123".
    # now, for either the "0123" directory or "tmp-was-root-0123"
    # directory, file all chunks, and move them to the
    # right locations "01/23/*.chunk", making "01/23" if needed.
    # (shouldn't be any out-of-link problems down one level)
    my @four_dirs = map {
        sort @{ $four_of_two{$_} }
    }
    sort {
        scalar(@{ $four_of_two{$b} }) <=> scalar(@{ $four_of_two{$a} })
    } keys %four_of_two;
    my $n_done;
    while (my $four_dir = shift @four_dirs) {
        my $leading_two = substr($four_dir, 0, 2);
        my $migrate_source;
        if ($exist_twodir{$leading_two}) {
            # top-level destination already exists.  no need for more
            # links in the top-level
            $migrate_source = $four_dir;
        } elsif (@four_dirs) {
            # we need to move four_dir away, into another four_dir,
            # to make room to create a new two_dir in the root
            my $holder_four_dir = $four_dirs[0];
            $migrate_source = "$holder_four_dir/tmp-was-root-$four_dir";
            my $temp_dir = "$root/$migrate_source";
            rename "$root/$four_dir", $temp_dir
                or die "Rename of $root/$four_dir -> $temp_dir failed: $!";
        } else {
            # no four_dirs left?  then I bet we aren't out of links
            # anymore.  just migrate.
            $migrate_source = $four_dir;
        }

        $self->_upgrade_chunks_in_directory($four_dir, $migrate_source);
        if (-e "$root/$four_dir") {
            die "Upgrade of $root/$four_dir/* didn't seem to have worked.";
        }
        $n_done++;
        last if $clean_limit && $n_done >= $clean_limit;
    }
}

sub _upgrade_chunks_in_directory {
    my $self = shift;
    my $four_dig = shift;  # first four hex digits of all files being moved
    my $rel_dir = shift;   # directory (relative to root) to move files from, and then remove
    die "not relative" unless $rel_dir =~ m!^[^/]!;

    my $root = $self->{path};

    my ($hex12, $hex34) = $four_dig =~ /^([0-9a-f]{2})([0-9a-f]{2})$/
        or die "four_dig not four hex digits";

    my $dest_dir0 = "$root/$hex12";
    my $dest_dir  = "$root/$hex12/$hex34";
    for ($dest_dir0, $dest_dir) {
        next if -d $_;
        mkdir $_ or die "Failed to mkdir $_: $!";
    }

    my @dirs;
    File::Find::find({wanted => sub {
        my $name = $File::Find::name;
        if (-f $name) {
            my $basefile = $_;  # stupid File::Find conventions
            rename $name, "$dest_dir/$basefile" or die
                "Failed to move $name to $dest_dir: $!";
        } elsif (-d $name) {
            return if $_ eq "." || $_ eq "..";
            push @dirs, $name;
        }
    }}, "$root/$rel_dir");

    my $final_dir = "$root/$four_dig";
    for my $dir (reverse(@dirs), $final_dir) {
        if (!rmdir($dir) && -d $dir) {
            warn "Directory not empty? $dir.  Skipping cleanup.\n";
            return;
        }
    }
    warn "Rearranged & removed $four_dig\n";
}

# version <= 1.05: 0123/4567/89ab/cdef/0123456789abcdef...xxx.chunk
# this is totally stupid.  65k files in root (twice ext3's historical/common
# maximum), and the leaves were always containing but one file.
sub _old_diskpath {
    my ($self, $dig) = @_;
    my @parts;
    my $fulldig = $dig;
    $dig =~ s/^\w+://; # remove the "hashtype:" from beginning
    $fulldig =~ s/:/./g if $self->nocolons; # Convert colons to dots if we've been asked to
    while (length $dig && @parts < 4) {
        $dig =~ s/^([0-9a-f]{4})// or die "Can't get 4 hex digits of $fulldig";
        push @parts, $1;
    }
    return $self->{path} . "/" . join("/", @parts) . "/$fulldig.chunk";
}

sub chunkpath {
    my ($self, $dig) = @_;

    # if the old (version <= 1.05) chunk still exists,
    # just use that, unless we know (from initial scan)
    # that such paths can't exist, thus avoiding a
    # bunch of stats()
    unless ($self->{_no_four_hex_dirs_in_root}) {
        my $old = $self->_old_diskpath($dig);
        return $old if -e $old;
    }

    # else, use the new (version >= 1.06) location, which
    # is much more sensible
    return $self->{path} . '/' . $self->SUPER::chunkpath($dig);
}

sub metapath {
    my ($self, $name) = @_;
    return $self->{path} . '/' . $self->SUPER::metapath($name);
}

sub size {
    my ($self, $path) = @_;
    return -s $path;
}

sub has_chunk_of_handle {
    my ($self, $handle) = @_;
    my $dig = $handle->digest;  # "sha1:sdfsdf" format scalar
    my $path = $self->chunkpath($dig);
    return -e $path;
}

sub load_chunk {
    my ($self, $dig) = @_;
    my $path = $self->chunkpath($dig);
    open (my $fh, $path) or die "Error opening $path to load chunk: $!";
    my $chunk = do { local $/; <$fh>; };
    return \$chunk;
}

sub has_chunk {
    my ($self, $chunk) = @_;
    my $dig = $chunk->backup_digest;
    my $blen = $chunk->backup_length;
    my $path = $self->chunkpath($dig);
    my $exist_size = -s $path;
    if ($exist_size && $exist_size == $blen) {
        return 1;
    }
    return 0;
}

sub store_chunk {
    my ($self, $chunk) = @_;
    my $dig = $chunk->backup_digest;
    my $blen = $chunk->backup_length;

    my $path = $self->chunkpath($dig);

    # is it already there?  then do nothing.
    my $exist_size = -s $path;
    if ($exist_size && $exist_size == $blen) {
        return 1;
    }

    my $dir = dirname($path);

    unless (-d $dir) {
        unless (eval { File::Path::mkpath($dir) }) {
            if ($!{EMLINK}) {
                warn "Too many directories in one directory; doing partial cleanup before proceeding...\n";
                # NOTE: 2 directories is key to freeing up one link.  imagine upgrading one:
                # it'd remove "0000" but possibly (likely) create "00".  so we do two,
                # because, following the example, "0001" would also go into "00", so we'd have one
                # link left in the root.  _upgrade_layout orders the directories to clean in
                # an order such that 2 will succeed or fail, but no higher will succeed when
                # 2 won't.
                $self->_upgrade_layout(2);
                unless (eval { File::Path::mkpath($dir) }) {
                    die "Still can't create directory $dir: $!\n";
                }
            } else {
                die "Failed to mkdir: $dir: $!\n";
            }
        }
    }

    my $partial = "$path.partial";
    open (my $fh, '>', $partial) or die "Failed to open $partial for writing: $!\n";
    binmode($fh);
    io_print_to_fh($chunk->chunkref, $fh);
    close($fh) or die "Failed to close $path\n";

    unlink $path;
    rename $partial, $path or die "Failed to rename $partial to $path: $!\n";

    my $actual_size   = -s $path;
    my $expected_size = $chunk->backup_length;
    unless (defined($actual_size)) {
        die "Chunk output file $path does not exist. Do you need to set no_filename_colons=1?";
    }
    unless ($actual_size == $expected_size) {
        die "Chunk $path was written to disk wrong:  size is $actual_size, expecting $expected_size\n";
    }

    return 1;
}

sub delete_chunk {
    my ($self, $dig) = @_;
    my $path = $self->chunkpath($dig);
    unlink $path;
}


# returns a list of names of all chunks
sub chunks {
    my $self = shift;

    my @chunks = ();
    my $found_chunk = sub {
        m/\.chunk$/ or return;
        my $chunk_name = basename($_);
        $chunk_name =~ s/\.chunk$//;
        $chunk_name =~ s/\./:/g if $self->nocolons;
        push @chunks, $chunk_name;
    };
    File::Find::find({ wanted => $found_chunk, no_chdir => 1}, $self->{path});
    return @chunks;
}

sub store_backup_meta {
    my ($self, $name, $fh) = @_;

    my $dir = $self->metapath();
    unless (-d $dir) {
        mkdir $dir or die "Failed to mkdir $dir: $!\n";
    }

    my $out_filepath = "$dir/$name.brackup";
    open (my $out_fh, '>', $out_filepath)
      or die "Failed to open metafile '$out_filepath': $!\n";
    io_print_to_fh($fh, $out_fh);
    close $out_fh or die "Failed to close metafile '$out_filepath': $!\n";

    return 1;
}

sub backups {
    my ($self) = @_;

    my $dir = $self->metapath();
    return () unless -d $dir;

    opendir(my $dh, $dir) or
        die "Failed to open $dir: $!\n";

    my @ret = ();
    while (my $fn = readdir($dh)) {
        next unless $fn =~ s/\.brackup$//;
        my $stat = File::stat::stat("$dir/$fn.brackup");
        push @ret, Brackup::TargetBackupStatInfo->new($self, $fn,
                                                      time => $stat->mtime,
                                                      size => $stat->size);
    }
    closedir($dh);

    return @ret;
}

# downloads the given backup name to the current directory (with
# *.brackup extension) or to the specified location
sub get_backup {
    my ($self, $name, $output_file) = @_;
    my $file = $self->metapath("$name.brackup");

    die "File doesn't exist: $file" unless -e $file;

    $output_file ||= "$name.brackup";

    open(my $in,  $file) or die "Failed to open $file: $!\n";
    open(my $out, '>', $output_file) or die "Failed to open $output_file: $!\n";

    my $buf;
    my $rv;
    while ($rv = sysread($in, $buf, 128*1024)) {
        my $outv = syswrite($out, $buf);
        die "copy error" unless $outv == $rv;
    }
    die "copy error" unless defined $rv;

    return 1;
}

sub delete_backup {
    my $self = shift;
    my $name = shift;

    my $file = $self->metapath("$name.brackup");
    die "File doesn't exist: $file" unless -e $file;
    unlink $file;
    return 1;
}

1;


=head1 NAME

Brackup::Target::Filesystem - backup to a locally mounted filesystem

=head1 DESCRIPTION

Back up to an NFS or Samba server, another disk array (external storage), etc.

=head1 EXAMPLE

In your ~/.brackup.conf file:

  [TARGET:nfs_in_garage]
  type = Filesystem
  path = /mnt/nfs-garage/brackup/

=head1 CONFIG OPTIONS

=over

=item B<type>

Must be "B<Filesystem>".

=item B<path>

Path to backup to.

=back

=head1 SEE ALSO

L<Brackup::Target>
