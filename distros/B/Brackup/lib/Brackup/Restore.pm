package Brackup::Restore;
use strict;
use warnings;
use Carp qw(croak);
use Digest::SHA1;
use POSIX qw(mkfifo);
use Fcntl qw(O_RDONLY O_CREAT O_WRONLY O_TRUNC);
use String::Escape qw(unprintable);
use Brackup::DecryptedFile;
use Brackup::Decrypt;

sub new {
    my ($class, %opts) = @_;
    my $self = bless {}, $class;

    $self->{to}      = delete $opts{to};      # directory we're restoring to
    $self->{prefix}  = delete $opts{prefix};  # directory/file filename prefix, or "" for all
    $self->{filename}= delete $opts{file};    # filename we're restoring from
    $self->{config}  = delete $opts{config};  # brackup config (if available)
    $self->{verbose} = delete $opts{verbose};

    $self->{_local_uid_map} = {};  # remote/metafile uid -> local uid
    $self->{_local_gid_map} = {};  # remote/metafile gid -> local gid

    $self->{prefix} =~ s/\/$// if $self->{prefix};

    $self->{_stats_to_run} = [];  # stack (push/pop) of subrefs to reset stat info on

    die "Destination directory doesn't exist" unless $self->{to} && -d $self->{to};
    croak("Unknown options: " . join(', ', keys %opts)) if %opts;

    $self->{metafile} = Brackup::DecryptedFile->new(filename => $self->{filename});

    return $self;
}

# returns a hashref of { "foo" => "bar" } from { ..., "Driver-foo" => "bar" }
sub _driver_meta {
    my $src = shift;
    my $ret = {};
    foreach my $k (keys %$src) {
        next unless $k =~ /^Driver-(.+)/;
        $ret->{$1} = $src->{$k};
    }
    return $ret;
}

sub restore {
    my ($self) = @_;
    my $parser = $self->parser;
    my $meta = $parser->readline;
    my $driver_class = $meta->{BackupDriver};
    die "No driver specified" unless $driver_class;

    my $driver_meta = _driver_meta($meta);

    my $confsec;
    if ($self->{config} && $meta->{TargetName}) {
        $confsec = eval { $self->{config}->get_section('TARGET:' . $meta->{TargetName}) };
    }
    # If no config section, use an empty one up with no keys to simplify Target handling
    $confsec ||= Brackup::ConfigSection->new('fake');

    eval "use $driver_class; 1;" or die
        "Failed to load driver ($driver_class) to restore from: $@\n";
    my $target = eval {"$driver_class"->new_from_backup_header($driver_meta, $confsec); };
    if ($@) {
        die "Failed to instantiate target ($driver_class) for restore. Perhaps it doesn't support restoring yet?\n\nThe error was: $@";
    }
    $self->{_target} = $target;
    $self->{_meta}   = $meta;

    # handle absolute prefixes by stripping off RootPath to relativise
    if ($self->{prefix} && $self->{prefix} =~ m/^\//) {
        $self->{prefix} =~ s/^\Q$meta->{RootPath}\E\/?//;
    }

    # we first process directories, then files sorted by their first chunk,
    # then the rest. The file sorting allows us to avoid loading composite 
    # chunks and identical single chunk files multiple times from the target
    # (see _restore_file)
    my (@dirs, @files, @rest);
    while (my $it = $parser->readline) {
        my $type = $it->{Type} || 'f';
        if($type eq 'f') {
            # find dig of first chunk
            ($it->{Chunks} || '') =~ /^(\S+)/;
            my ($offset, $len, $enc_len, $dig) = split(/;/, $1 || '');
            $it->{fst_dig} = $dig || '';
            push @files, $it;
        } elsif($type eq 'd') {
            push @dirs, $it;
        } else {
            push @rest, $it;
        }
    }
    @files = sort { $a->{fst_dig} cmp $b->{fst_dig} } @files;

    my $restore_count = 0;
    for my $it (@dirs, @files, @rest) {
        my $type = $it->{Type} || "f";
        my $path = unprintable($it->{Path});
        my $path_escaped = $it->{Path};
        my $path_escaped_stripped = $it->{Path};
        die "Unknown filetype: type=$type, file: $path_escaped" unless $type =~ /^[ldfp]$/;

        if ($self->{prefix}) {
            next unless $path =~ m/^\Q$self->{prefix}\E(?:\/|$)/;
            # if non-dir and $path eq $self->{prefix}, strip all but last component
            if ($type ne 'd' && $path =~ m/^\Q$self->{prefix}\E\/?$/) {
                if (my ($leading_prefix) = ($self->{prefix} =~ m/^(.*\/)[^\/]+\/?$/)) {
                    $path =~ s/^\Q$leading_prefix\E//;
                    $path_escaped_stripped =~ s/^\Q$leading_prefix\E//;
                }
            }
            else {
                $path =~ s/^\Q$self->{prefix}\E\/?//;
                $path_escaped_stripped =~ s/^\Q$self->{prefix}\E\/?//;
            }
        }

        $restore_count++;
        my $full = $self->{to} . "/" . $path;
        my $full_escaped = $self->{to} . "/" . $path_escaped_stripped;

        # restore default modes/user/group from header
        $it->{Mode} ||= ($type eq 'd' ? $meta->{DefaultDirMode} : $meta->{DefaultFileMode});
        $it->{UID}  ||= $meta->{DefaultUID};
        $it->{GID}  ||= $meta->{DefaultGID};

        warn " * restoring $path_escaped to $full_escaped\n" if $self->{verbose};
        $self->_restore_link     ($full, $it) if $type eq "l";
        $self->_restore_directory($full, $it) if $type eq "d";
        $self->_restore_fifo     ($full, $it) if $type eq "p";
        $self->_restore_file     ($full, $it) if $type eq "f";

        $self->_chown($full, $it, $type, $meta) if $it->{UID} || $it->{GID};
    }

    # clear chunk cached by _restore_file
    delete $self->{_cached_dig};
    delete $self->{_cached_dataref};

    if ($restore_count) {
        warn " * fixing stat info\n" if $self->{verbose};
        $self->_exec_statinfo_updates;
        warn " * done\n" if $self->{verbose};
        return 1;
    } else {
        die "nothing found matching '$self->{prefix}'.\n" if $self->{prefix};
        die "nothing found to restore.\n";
    }
}

sub _lookup_remote_uid {
    my ($self, $remote_uid, $meta) = @_;

    return $self->{_local_uid_map}->{$remote_uid} 
        if defined $self->{_local_uid_map}->{$remote_uid};

    # meta remote user map - remote_uid => remote username
    $self->{_remote_user_map} ||= { map { split /:/, $_, 2 } split /\s+/, $meta->{UIDMap} };

    # try and lookup local uid using remote username
    if (my $remote_user = $self->{_remote_user_map}->{$remote_uid}) {
        my $local_uid = getpwnam($remote_user);
        return $self->{_local_uid_map}->{$remote_uid} = $local_uid
            if defined $local_uid;
    }

    # if remote username missing locally, fallback to $remote_uid
    return $self->{_local_uid_map}->{$remote_uid} = $remote_uid;
}

sub _lookup_remote_gid {
    my ($self, $remote_gid, $meta) = @_;

    return $self->{_local_gid_map}->{$remote_gid} 
        if defined $self->{_local_gid_map}->{$remote_gid};

    # meta remote group map - remote_gid => remote group
    $self->{_remote_group_map} ||= { map { split /:/, $_, 2 } split /\s+/, $meta->{GIDMap} };

    # try and lookup local gid using remote group
    if (my $remote_group = $self->{_remote_group_map}->{$remote_gid}) {
        my $local_gid = getgrnam($remote_group);
        return $self->{_local_gid_map}->{$remote_gid} = $local_gid
            if defined $local_gid;
    }

    # if remote group missing locally, fallback to $remote_gid
    return $self->{_local_gid_map}->{$remote_gid} = $remote_gid;
}

sub _chown {
    my ($self, $full, $it, $type, $meta) = @_;

    my $uid = $self->_lookup_remote_uid($it->{UID}, $meta) if $it->{UID};
    my $gid = $self->_lookup_remote_gid($it->{GID}, $meta) if $it->{GID};

    if ($type eq 'l') {
        if (! defined $self->{_lchown}) {
            no strict 'subs';
            $self->{_lchown} = eval { require Lchown } && Lchown::LCHOWN_AVAILABLE;
        }
        if ($self->{_lchown}) {
            Lchown::lchown($uid, -1, $full) if defined $uid;
            Lchown::lchown(-1, $gid, $full) if defined $gid;
        }
    } else {
        # ignore errors, but change uid and gid separately to sidestep unprivileged failures
        chown $uid, -1, $full if defined $uid;
        chown -1, $gid, $full if defined $gid;
    }
}

sub _update_statinfo {
    my ($self, $full, $it) = @_;

    push @{ $self->{_stats_to_run} }, sub {
        if (defined $it->{Mode}) {
            chmod(oct $it->{Mode}, $full) or
                die "Failed to change mode of $full: $!";
        }

        if ($it->{Mtime} || $it->{Atime}) {
            utime($it->{Atime} || $it->{Mtime},
                  $it->{Mtime} || $it->{Atime},
                  $full) or
                die "Failed to change utime of $full: $!";
        }
    };
}

sub _exec_statinfo_updates {
    my $self = shift;

    # change the modes/times in backwards order, going from deep
    # files/directories to shallow ones.  (so we can reliably change
    # all the directory mtimes without kernel doing it for us when we
    # modify files deeper)
    while (my $sb = pop @{ $self->{_stats_to_run} }) {
        $sb->();
    }
}

sub _restore_directory {
    my ($self, $full, $it) = @_;

    unless (-d $full) {
        mkdir $full or    # FIXME: permissions on directory
            die "Failed to make directory: $full ($it->{Path})";
    }

    $self->_update_statinfo($full, $it);
}

sub _restore_link {
    my ($self, $full, $it) = @_;

    if (-e $full) {
        # TODO: add --conflict={skip,overwrite} option, defaulting to nothing: which dies
        die "Link $full ($it->{Path}) already exists.  Aborting.";
    }
    symlink $it->{Link}, $full
        or die "Failed to link";
}

sub _restore_fifo {
    my ($self, $full, $it) = @_;

    if (-e $full) {
        die "Named pipe/fifo $full ($it->{Path}) already exists.  Aborting.";
    }

    mkfifo($full, $it->{Mode}) or die "mkfifo failed: $!";

    $self->_update_statinfo($full, $it);
}

sub _restore_file {
    my ($self, $full, $it) = @_;

    if (-e $full && -s $full) {
        # TODO: add --conflict={skip,overwrite} option, defaulting to nothing: which dies
        die "File $full ($it->{Path}) already exists.  Aborting.";
    }

    sysopen(my $fh, $full, O_CREAT|O_WRONLY|O_TRUNC) or die "Failed to open '$full' for writing: $!";
    binmode($fh);
    my @chunks = grep { $_ } split(/\s+/, $it->{Chunks} || "");
    foreach my $ch (@chunks) {
        my ($offset, $len, $enc_len, $dig) = split(/;/, $ch);

        # we process files sorted by the dig of their first chunk, caching
        # the last seen chunk to avoid loading composite chunks multiple 
        # times (all files included in composite chunks are single-chunk 
        # files, by definition). Even for non-composite chunks there is a 
        # speedup if we have single-chunk identical files.
        my $dataref;
        if($dig eq ($self->{_cached_dig} || '')) {
            warn "   ** using cached chunk $dig\n" if $self->{verbose};
            $dataref = $self->{_cached_dataref};
        } else {
            warn "   ** loading chunk $dig from target\n" if $self->{verbose};
            $dataref = $self->{_target}->load_chunk($dig) or
                die "Error loading chunk $dig from the restore target\n";
            $self->{_cached_dig} = $dig;
            $self->{_cached_dataref} = $dataref;
        }

        my $len_chunk = length $$dataref;

        # using just a range of the file
        if ($enc_len =~ /^(\d+)-(\d+)$/) {
            my ($from, $to) = ($1, $2);
            # file range.  gotta be at least as big as bigger number
            unless ($len_chunk >= $to) {
                die "Backup chunk $dig isn't at least as big as range: got $len_chunk, needing $to\n";
            }
            my $region = substr($$dataref, $from, $to-$from);
            $dataref = \$region;
        } else {
            # using the whole chunk, so make sure fetched size matches
            # expected size
            unless ($len_chunk == $enc_len) {
                die "Backup chunk $dig isn't of expected length: got $len_chunk, expecting $enc_len\n";
            }
        }

        my $decrypted_ref = Brackup::Decrypt::decrypt_data($dataref, meta => $self->{_meta});
        print $fh $$decrypted_ref;
    }
    close($fh) or die "Close failed";

    if (my $good_dig = $it->{Digest}) {
        die "not capable of verifying digests of from anything but sha1"
            unless $good_dig =~ /^sha1:(.+)/;
        $good_dig = $1;

        sysopen(my $readfh, $full, O_RDONLY) or die "Failed to reopen '$full' for verification: $!";
        binmode($readfh);
        my $sha1 = Digest::SHA1->new;
        $sha1->addfile($readfh);
        my $actual_dig = $sha1->hexdigest;

        # TODO: support --onerror={continue,prompt}, etc, but for now we just die
        unless ($actual_dig eq $good_dig || $full =~ m!\.brackup-digest\.db\b!) {
            die "Digest of restored file ($full) doesn't match";
        }
    }

    $self->_update_statinfo($full, $it);
}

# returns iterator subref which returns hashrefs or undef on EOF
sub parser {
    my $self = shift;
    return Brackup::Metafile->open($self->{metafile}->name);
}

1;

