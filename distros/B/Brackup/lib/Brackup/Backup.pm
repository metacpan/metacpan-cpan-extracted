package Brackup::Backup;
use strict;
use warnings;
use Carp qw(croak);
use Brackup::ChunkIterator;
use Brackup::CompositeChunk;
use Brackup::GPGProcManager;
use Brackup::GPGProcess;
use File::Basename;
use File::Temp qw(tempfile);

sub new {
    my ($class, %opts) = @_;
    my $self = bless {}, $class;

    $self->{root}    = delete $opts{root};     # Brackup::Root
    $self->{target}  = delete $opts{target};   # Brackup::Target
    $self->{dryrun}  = delete $opts{dryrun};   # bool
    $self->{verbose} = delete $opts{verbose};  # bool
    $self->{inventory} = delete $opts{inventory};  # bool
    $self->{savefiles} = delete $opts{savefiles};  # bool
    $self->{zenityprogress} = delete $opts{zenityprogress};  # bool

    $self->{modecounts} = {}; # type -> mode(octal) -> count
    $self->{idcounts}   = {}; # type -> uid/gid -> count

    $self->{_uid_map} = {};   # uid -> username
    $self->{_gid_map} = {};   # gid -> group

    $self->{saved_files} = [];   # list of Brackup::File objects backed up
    $self->{unflushed_files} = [];   # list of Brackup::File objects not in backup_file

    croak("Unknown options: " . join(', ', keys %opts)) if %opts;

    return $self;
}

# returns true (a Brackup::BackupStats object) on success, or dies with error
sub backup {
    my ($self, $backup_file) = @_;

    my $root   = $self->{root};
    my $target = $self->{target};

    my $stats  = Brackup::BackupStats->new;

    my @gpg_rcpts = $self->{root}->gpg_rcpts;

    my $n_kb         = 0.0; # num:  kb of all files in root
    my $n_files      = 0;   # int:  # of files in root
    my $n_kb_done    = 0.0; # num:  kb of files already done with (uploaded or skipped)

    # if we're pre-calculating the amount of data we'll
    # actually need to upload, store it here.
    my $n_files_up   = 0;
    my $n_kb_up      = 0.0;
    my $n_kb_up_need = 0.0; # by default, not calculated/used.

    my $n_files_done = 0;   # int
    my @files;         # Brackup::File objs

    $self->debug("Discovering files in ", $root->path, "...\n");
    $self->report_progress(0, "Discovering files in " . $root->path . "...");
    $root->foreach_file(sub {
        my ($file) = @_;  # a Brackup::File
        push @files, $file;
        $self->record_mode_ids($file);
        $n_files++;
        $n_kb += $file->size / 1024;
    });

    $self->debug("Number of files: $n_files\n");
    $stats->timestamp('File Discovery');
    $stats->set('Number of Files' => $n_files);
    $stats->set('Total File Size' => sprintf('%0.01f MB', $n_kb / 1024));

    # calc needed chunks
    if ($ENV{CALC_NEEDED}) {
        my $fn = 0;
        foreach my $f (@files) {
            $fn++;
            if ($fn % 100 == 0) { warn "$fn / $n_files ...\n"; }
            foreach my $pc ($f->chunks) {
                if ($target->stored_chunk_from_inventory($pc)) {
                    $pc->forget_chunkref;
                    next;
                }
                $n_kb_up_need += $pc->length / 1024;
                $pc->forget_chunkref;
            }
        }
        warn "kb need to upload = $n_kb_up_need\n";
        $stats->timestamp('Calc Needed');
    }


    my $chunk_iterator = Brackup::ChunkIterator->new(@files);
    undef @files;
    $stats->timestamp('Chunk Iterator');

    my $gpg_iter;
    my $gpg_pm;   # gpg ProcessManager
    if (@gpg_rcpts) {
        ($chunk_iterator, $gpg_iter) = $chunk_iterator->mux_into(2);
        $gpg_pm = Brackup::GPGProcManager->new($gpg_iter, $target);
    }

    # begin temp backup_file
    my ($metafh, $meta_filename);
    unless ($self->{dryrun}) {
        ($metafh, $meta_filename) = tempfile(
                                             '.' . basename($backup_file) . 'XXXXX',
                                             DIR => dirname($backup_file),
        );
        if (! @gpg_rcpts) {
            if (eval { require IO::Compress::Gzip }) {
                close $metafh;
                $metafh = IO::Compress::Gzip->new($meta_filename)
                    or die "Cannot open tempfile with IO::Compress::Gzip: $IO::Compress::Gzip::GzipError";
            }
        }
        print $metafh $self->backup_header;
    }

    my $cur_file; # current (last seen) file
    my @stored_chunks;
    my $file_has_shown_status = 0;

    my $merge_under = $root->merge_files_under;
    my $comp_chunk  = undef;

    my $end_file = sub {
        return unless $cur_file;
        if ($merge_under && $comp_chunk) {
            # defer recording to backup_file until CompositeChunk finalization
            $self->add_unflushed_file($cur_file, [ @stored_chunks ]);
        }
        else {
            print $metafh $cur_file->as_rfc822([ @stored_chunks ], $self) if $metafh;
        }
        $self->add_saved_file($cur_file, [ @stored_chunks ]) if $self->{savefiles};
        $n_files_done++;
        $n_kb_done += $cur_file->size / 1024;
        $cur_file = undef;
    };
    my $show_status = sub {
        # use either size of files in normal case, or if we pre-calculated
        # the size-to-upload (by looking in inventory, then we'll show the
        # more accurate percentage)
        my $percdone = 100 * ($n_kb_up_need ?
                              ($n_kb_up / $n_kb_up_need) :
                              ($n_kb_done / $n_kb));
        my $mb_remain = ($n_kb_up_need ?
                         ($n_kb_up_need - $n_kb_up) :
                         ($n_kb - $n_kb_done)) / 1024;

        $self->debug(sprintf("* %-60s %d/%d (%0.02f%%; remain: %0.01f MB)",
                             $cur_file->path, $n_files_done, $n_files, $percdone,
                             $mb_remain));

        $self->report_progress($percdone);
    };
    my $start_file = sub {
        $end_file->();
        $cur_file = shift;
        @stored_chunks = ();
        $show_status->() if $cur_file->is_dir;
        if ($gpg_iter) {
            # catch our gpg iterator up.  we want it to be ahead of us,
            # nothing iteresting is behind us.
            $gpg_iter->next while $gpg_iter->behind_by > 1;
        }
        $file_has_shown_status = 0;
    };

    # records are either Brackup::File (for symlinks, directories, etc), or
    # PositionedChunks, in which case the file can asked of the chunk
    while (my $rec = $chunk_iterator->next) {
        if ($rec->isa("Brackup::File")) {
            $start_file->($rec);
            next;
        }
        my $pchunk = $rec;
        if ($pchunk->file != $cur_file) {
            $start_file->($pchunk->file);
        }

        # have we already stored this chunk before?  (iterative backup)
        my $schunk;
        if ($schunk = $target->stored_chunk_from_inventory($pchunk)) {
            $pchunk->forget_chunkref;
            push @stored_chunks, $schunk;
            next;
        }

        # weird case... have we stored this same pchunk digest in the
        # current comp_chunk we're building?  these aren't caught by
        # the above inventory check, because chunks in a composite
        # chunk aren't added to the inventory until after the the composite
        # chunk has fully grown (because it's not until it's fully grown
        # that we know the handle for it, its digest)
        if ($comp_chunk && ($schunk = $comp_chunk->stored_chunk_from_dup_internal_raw($pchunk))) {
            $pchunk->forget_chunkref;
            push @stored_chunks, $schunk;
            next;
        }

        unless ($file_has_shown_status++) {
            $show_status->();
            $n_files_up++;
        }
        $self->debug("  * storing chunk: ", $pchunk->as_string, "\n");
        $self->report_progress(undef, $pchunk->file->path . " (" . $pchunk->offset . "," . $pchunk->length . ")");

        unless ($self->{dryrun}) {
            $schunk = Brackup::StoredChunk->new($pchunk);

            # encrypt it
            if (@gpg_rcpts) {
                $schunk->set_encrypted_chunkref($gpg_pm->enc_chunkref_of($pchunk));
            }

            # see if we should pack it into a bigger blob
            my $chunk_size = $schunk->backup_length;

            # see if we should merge this chunk (in this case, file) together with
            # other small files we encountered earlier, into a "composite chunk",
            # to be stored on the target in one go.

            # Note: no technical reason for only merging small files (is_entire_file),
            # and not the tails of larger files.  just don't like the idea of files being
            # both split up (for big head) and also merged together (for little end).
            # would rather just have 1 type of magic per file.  (split it or join it)
            if ($merge_under && $chunk_size < $merge_under && $pchunk->is_entire_file) {
                if ($comp_chunk && ! $comp_chunk->can_fit($chunk_size)) {
                    $self->debug("Finalizing composite chunk $comp_chunk...");
                    $comp_chunk->finalize;
                    $comp_chunk = undef;
                    $self->flush_files($metafh);
                }
                $comp_chunk ||= Brackup::CompositeChunk->new($root, $target);
                $comp_chunk->append_little_chunk($schunk);
            } else {
                # store it regularly, as its own chunk on the target
                $target->store_chunk($schunk)
                    or die "Chunk storage failed.\n";
                $target->add_to_inventory($pchunk => $schunk);
            }

            # if only this worked... (LWP protocol handler seems to
            # get confused by its syscalls getting interrupted?)
            #local $SIG{CHLD} = sub {
            #    print "some child finished!\n";
            #    $gpg_pm->start_some_processes;
            #};


            $n_kb_up += $pchunk->length / 1024;
            $schunk->forget_chunkref;
            push @stored_chunks, $schunk;
        }

        #$stats->note_stored_chunk($schunk);

        # DEBUG: verify it got written correctly
        if ($ENV{BRACKUP_PARANOID}) {
            die "FIX UP TO NEW API";
            #my $saved_ref = $target->load_chunk($handle);
            #my $saved_len = length $$saved_ref;
            #unless ($saved_len == $chunk->backup_length) {
            #    warn "Saved length of $saved_len doesn't match our length of " . $chunk->backup_length . "\n";
            #    die;
            #}
        }

        $stats->check_maxmem;
        $pchunk->forget_chunkref;
    }
    $end_file->();
    $comp_chunk->finalize if $comp_chunk;
    $self->flush_files($metafh);
    $stats->timestamp('Chunk Storage');
    $stats->set('Number of Files Uploaded:', $n_files_up);
    $stats->set('Total File Size Uploaded:', sprintf('%0.01f MB', $n_kb_up / 1024));

    unless ($self->{dryrun}) {
        close $metafh or die "Close on metafile '$backup_file' failed: $!";
        rename $meta_filename, $backup_file
            or die "Failed to rename temporary backup_file: $!\n";

        my ($store_fh, $store_filename);
        my $is_encrypted = 0;

        # store the metafile, encrypted, on the target
        if (@gpg_rcpts) {
            my $encfile = $backup_file . ".enc";
            my @recipients = map {("--recipient", $_)} @gpg_rcpts;
            system($self->{root}->gpg_path, $self->{root}->gpg_args,
                   @recipients,
                   "--trust-model=always",
                   "--batch",
                   "--encrypt", 
                   "--output=$encfile", 
                   "--yes", 
                   $backup_file)
                and die "Failed to run gpg while encryping metafile: $!\n";
            open ($store_fh, $encfile) or die "Failed to open encrypted metafile '$encfile': $!\n";
            $store_filename = $encfile;
            $is_encrypted = 1;
        } else {
            # Reopen $metafh to reset file pointer (no backward seek with IO::Compress::Gzip)
            open($store_fh, $backup_file) or die "Failed to open metafile '$backup_file': $!\n";
            $store_filename = $backup_file;
        }

        # store it on the target
        $self->debug("Storing metafile to " . ref($target));
        my $name = $self->{root}->publicname . "-" . $self->backup_time;
        $target->store_backup_meta($name, $store_fh, { filename => $store_filename, is_encrypted => $is_encrypted });
        $stats->timestamp('Metafile Storage');

        # cleanup encrypted metafile
        if ($is_encrypted) {
            close $store_fh or die "Close on encrypted metafile failed: $!";
            unlink $store_filename;
        }
    }
    $self->report_progress(100, "Backup complete.");

    return $stats;
}

sub default_file_mode {
    my $self = shift;
    return $self->{_def_file_mode} ||= $self->_default_mode('f');
}

sub default_directory_mode {
    my $self = shift;
    return $self->{_def_dir_mode} ||= $self->_default_mode('d');
}

sub _default_mode {
    my ($self, $type) = @_;
    my $map = $self->{modecounts}{$type} || {};
    return (sort { $map->{$b} <=> $map->{$a} } keys %$map)[0];
}

sub default_uid {
    my $self = shift;
    return $self->{_def_uid} ||= $self->_default_id('u');
}

sub default_gid {
    my $self = shift;
    return $self->{_def_gid} ||= $self->_default_id('g');
}

sub _default_id {
    my ($self, $type) = @_;
    my $map = $self->{idcounts}{$type} || {};
    return (sort { $map->{$b} <=> $map->{$a} } keys %$map)[0];
}

# space-separated list of local uid:username mappings
sub uid_map {
    my $self = shift;
    my @map;
    my $uidcounts = $self->{idcounts}{u};
    for my $uid (sort { $a <=> $b } keys %$uidcounts) {
      if (my $name = getpwuid($uid)) {
        push @map, "$uid:$name";
      }
    }
    return join(' ', @map);
}

# space-separated list of local gid:group mappings
sub gid_map {
    my $self = shift;
    my @map;
    my $gidcounts = $self->{idcounts}{g};
    for my $gid (sort { $a <=> $b } keys %$gidcounts) {
      if (my $name = getgrgid($gid)) {
        push @map, "$gid:$name";
      }
    }
    return join(' ', @map);
}

sub backup_time {
    my $self = shift;
    return $self->{backup_time} ||= time();
}

sub backup_header {
    my $self = shift;
    my $ret = "";
    my $now = $self->backup_time;
    $ret .= "BackupTime: " . $now . " (" . localtime($now) . ")\n";
    $ret .= "BackupDriver: " . ref($self->{target}) . "\n";
    if (my $fields = $self->{target}->backup_header) {
        foreach my $k (sort keys %$fields) {
            die "Bogus header field from driver" unless $k =~ /^\w+$/;
            my $val = $fields->{$k};
            next if ! defined $val || $val eq '';   # skip keys with empty values
            die "Bogus header value from driver" if $val =~ /[\r\n]/;
            $ret .= "Driver-$k: $val\n";
        }
    }
    $ret .= "RootName: " . $self->{root}->name . "\n";
    $ret .= "RootPath: " . $self->{root}->path . "\n";
    $ret .= "TargetName: " . $self->{target}->name . "\n";
    $ret .= "DefaultFileMode: " . $self->default_file_mode . "\n";
    $ret .= "DefaultDirMode: " . $self->default_directory_mode . "\n";
    $ret .= "DefaultUID: " . $self->default_uid . "\n";
    $ret .= "DefaultGID: " . $self->default_gid . "\n";
    $ret .= "UIDMap: " . $self->uid_map . "\n";
    $ret .= "GIDMap: " . $self->gid_map . "\n";
    $ret .= "GPG-Recipient: $_\n" for $self->{root}->gpg_rcpts;
    $ret .= "\n";
    return $ret;
}

sub record_mode_ids {
    my ($self, $file) = @_;
    $self->{modecounts}{$file->type}{$file->mode}++;
    $self->{idcounts}{u}{$file->uid}++;
    $self->{idcounts}{g}{$file->gid}++;
}

sub add_unflushed_file {
    my ($self, $file, $handlelist) = @_;
    push @{ $self->{unflushed_files} }, [ $file, $handlelist ];
}   

sub flush_files {
    my ($self, $fh) = @_;
    while (my $rec = shift @{ $self->{unflushed_files} }) {
      next unless $fh;
      my ($file, $stored_chunks) = @$rec;
      print $fh $file->as_rfc822($stored_chunks, $self);
    }
}

sub add_saved_file {
    my ($self, $file, $handlelist) = @_;
    push @{ $self->{saved_files} }, [ $file, $handlelist ];
}   

sub foreach_saved_file {
    my ($self, $cb) = @_;
    foreach my $rec (@{ $self->{saved_files} }) {
        $cb->(@$rec);  # Brackup::File, arrayref of Brackup::StoredChunk
    }
}

sub debug {
    my ($self, @m) = @_;
    return unless $self->{verbose};
    my $line = join("", @m);
    chomp $line;
    print $line, "\n";
}

sub report_progress {
    my ($self, $percent, $message) = @_;

    if ($self->{zenityprogress}) {
        if (defined($message) && length($message) > 100) {
            $message = substr($message, 0, 100)."...";
        }
        print STDOUT "#", $message, "\n" if defined $message;
        print STDOUT $percent, "\n" if defined $percent;
    }
}

1;

