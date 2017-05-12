package App::SimplenoteSync;
{
  $App::SimplenoteSync::VERSION = '0.2.0';
}

# ABSTRACT: Synchronise text notes with simplenoteapp.com

use v5.10;
use open qw(:std :utf8);
use Moose;
use MooseX::Types::Path::Class;
use Log::Any qw//;
use DateTime;
use Try::Tiny;
use File::ExtAttr ':all';
use Proc::InvokeEditor;
use App::SimplenoteSync::Note;
use WebService::Simplenote;
use Method::Signatures;
use namespace::autoclean;

has ['email', 'password'] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has notes => (
    is      => 'rw',
    traits  => ['Hash'],
    isa     => 'HashRef[App::SimplenoteSync::Note]',
    default => sub { {} },
    handles => {
        set_note    => 'set',
        has_note    => 'exists',
        num_notes   => 'count',
        remove_note => 'delete',
        note_kvs    => 'kv',
    },
);

has stats => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        {
            new_local     => 0,
            new_remote    => 0,
            update_local  => 0,
            update_remote => 0,
            deleted_local => 0,
            trash         => 0,
            local_files   => 0,
        };
    },
);

has simplenote => (
    is      => 'rw',
    isa     => 'WebService::Simplenote',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return WebService::Simplenote->new(
            email             => $self->email,
            password          => $self->password,
            no_server_updates => $self->no_server_updates,
        );
    },
);

has ['no_server_updates', 'no_local_updates'] => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => 0,
);

has editor => (
    is      => 'ro',
    isa     => 'Undef|Str',
    lazy    => 1,
    default => undef,
);

has logger => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    default => sub { return Log::Any->get_logger },
);

has notes_dir => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    required => 1,
    coerce   => 1,
    builder  => '_build_notes_dir',
    trigger  => \&_check_notes_dir,
);

method _build_notes_dir {

    my $notes_dir = Path::Class::Dir->new($ENV{HOME}, 'Notes');

    if (!-e $notes_dir) {
        $notes_dir->mkpath
          or die "Failed to create notes dir: '$notes_dir': $!\n";
    }

    return $notes_dir;
}

method _check_notes_dir($path) {
    if (-d $self->notes_dir) {
        return;
    }
    $self->notes_dir->mkpath
      or die "Sync directory ["
      . $self->notes_dir
      . "] does not exist and could not be created: $!\n";
}

method _read_note_metadata(App::SimplenoteSync::Note $note) {
    $self->logger->debugf('Looking for metadata for [%s]',
        $note->file->basename);

    my @attrs = listfattr($note->file);
    if (!@attrs) {

        # no attrs probably means a new file
        $self->logger->debug('No metadata found');
        return;
    }

    my $has_simplenote_key = 0;
    foreach my $attr (@attrs) {
        $self->logger->debugf("Examining attr: $attr");
        next if $attr !~ /^simplenote\.(\w+)$/;
        my $key = $1;
        my $value = getfattr($note->file, $attr);

        given ($key) {
            when ('key') {
                $note->key($value);
                $has_simplenote_key = 1;
            }
            when ([qw/systemtags tags/]) {
                my @tags = split ',', $value;
                $note->$key(\@tags);
            }
            default {
                $self->logger->debug('Mystery simplenote tag found: ' . $key);
            }
        }
    }

    if (!$has_simplenote_key) {
        $self->logger->debug(
            'No simplenote.key tag found in ' . $note->file->stringify);
        return;
    }

    return 1;
}

method _write_note_metadata(App::SimplenoteSync::Note $note) {
    if ($self->no_local_updates) {
        return;
    }

    $self->logger->debugf('Writing note metadata for [%s]',
        $note->file->basename);

    # XXX only write if changed? Add a dirty attr?
    # should always be a key
    my $metadata = {'simplenote.key' => $note->key,};

    if ($note->has_systags) {
        $metadata->{'simplenote.systemtags'} = $note->join_systags(',');
    }

    if ($note->has_tags) {
        $metadata->{'simplenote.tags'} = $note->join_tags(',');
    }

    foreach my $key (keys %$metadata) {
        setfattr($note->file, $key, $metadata->{$key})
          or $self->logger->errorf('Error writing note metadata for [%s]',
            $note->file->basename);
    }

    return 1;
}

method _get_note(Str $key) {
    my $original_note = $self->simplenote->get_note($key);

    # 'cast' to our note type
    my $note = App::SimplenoteSync::Note->new(
        {%{$original_note}, notes_dir => $self->notes_dir});

    if ($self->no_local_updates) {
        return;
    }

    $note->save_content or return;

    # Set created and modified time
    # XXX: Not sure why this has to be done twice, but it seems to on Mac OS X
    utime $note->createdate->epoch, $note->modifydate->epoch, $note->file;

    #utime $create, $modify, $filename;
    $self->notes->{$note->key} = $note;

    $self->_write_note_metadata($note);

    $self->stats->{new_remote}++;

    return 1;
}

method _delete_note(App::SimplenoteSync::Note $note) {
    if ($self->no_local_updates) {
        $self->logger->warn('no_local_updates is set, not deleting note');
        return;
    }

    my $removed = $note->file->remove;
    if ($removed) {
        $self->logger->debugf('Deleted [%s]', $note->file->stringify);
        $self->stats->{deleted_local}++;
    } else {
        $self->logger->errorf("Failed to delete [%s]: $!",
            $note->file->stringify);
    }

    delete $self->notes->{$note->key};

    return 1;
}

method _put_note(App::SimplenoteSync::Note $note) {

    if (!defined $note->content) {
        $note->load_content || return;
    }

    $self->logger->infof('Uploading file: [%s]', $note->file->stringify);
    my $key = $self->simplenote->put_note($note);

    if (!$key) {
        return;
    }

    $note->key($key);

    return 1;
}

method merge_conflicts {

    # Both the local copy and server copy were changed since last sync
    # We'll merge the changes into a new master file, and flag any conflicts

}

method _merge_local_and_remote_lists(HashRef $remote_notes) {
    $self->logger->debug("Comparing local and remote lists");

    while (my ($key, $remote_note) = each %$remote_notes) {
        if ($self->has_note($key)) {
            my $local_note = $self->notes->{$key};

            if ($local_note->ignored) {
                $self->logger->debug("[$key] is being ignored");
                next;
            }

            $self->logger->debug("[$key] exists locally and remotely");

            if ($remote_note->deleted) {
                $self->logger->warnf(
                    "[$key] has been trashed remotely. Deleting local copy in [%s]",
                    $local_note->file->stringify
                );
                $self->_delete_note($local_note);
                next;
            }

            # which is newer?
            # utime doesn't use nanoseconds
            $remote_note->modifydate->set_nanosecond(0);
            $self->logger->debugf(
                'Comparing dates: remote [%s] // local [%s]',
                $remote_note->modifydate->iso8601,
                $local_note->modifydate->iso8601
            );
            given (
                DateTime->compare_ignore_floating(
                    $remote_note->modifydate, $local_note->modifydate
                ))
            {
                when (0) {
                    $self->logger->debug("[$key] not modified");
                }
                when (1) {
                    $self->logger->debug("[$key] remote note is newer");
                    $self->_get_note($key);
                    $self->stats->{update_remote}++;
                }
                when (-1) {
                    $self->logger->debug("[$key] local note is newer");
                    $self->_put_note($local_note);
                    $self->stats->{update_local}++;
                }
            }
        } else {
            $self->logger->debug("[$key] does not exist locally");
            if (!$remote_note->deleted) {
                $self->_get_note($key);
            } else {
                $self->stats->{trash}++;
            }
        }
    }

    # try the other way to catch deleted notes
    while (my ($key, $local_note) = each %{$self->notes}) {
        if (!exists $remote_notes->{$key}) {

            # if a local file has metadata, specifically simplenote.key
            # but doesn't exist remotely it must have been deleted there
            $self->logger->warnf(
                "[$key] does not exist remotely. Deleting local copy in [%s]",
                $local_note->file->stringify
            );
            $self->_delete_note($local_note);
        }
    }

    return 1;
}

# TODO: check ctime
# XXX: this isn't called anywhere?!?
method _update_dates(App::SimplenoteSync::Note $note, Path::Class::File $file)
{
    my $mod_time = DateTime->from_epoch(epoch => $file->stat->mtime);

    given (DateTime->compare($mod_time, $note->modifydate)) {
        when (0) {

            # no change
            return;
        }
        when (1) {

            # file has changed
            $note->modifydate($mod_time);
        }
        when (-1) {
            die "File is older than sync db record?? Don't know what to do!\n";
        }
    }

    return 1;
}

method _process_local_notes {
    my $num_files = scalar $self->notes_dir->children(no_hidden => 1);

    $self->logger->infof('Scanning [%d] items in [%s]',
        $num_files, $self->notes_dir->stringify);

    while (my $f = $self->notes_dir->next) {
        next unless -f $f;

        $self->logger->debug("Checking local file [$f]");
        $self->stats->{local_files}++;

        next if $f !~ /\.(txt|mkdn)$/;

        my $note = App::SimplenoteSync::Note->new(
            createdate => $f->stat->ctime,
            modifydate => $f->stat->mtime,
            file       => $f,
        );

        if (!$self->_read_note_metadata($note)) {

            $self->logger->info(
                "Don't have a key for [$f], assuming it is new");
            $self->_put_note($note);
            $self->_write_note_metadata($note);
            $self->stats->{new_local}++;
        }

        if (!defined $note->key) {
            $self->logger->error("Skipping [%s]: failed to find a key");
            next;
        }

        my $key = $note->key;

        if ($self->has_note($key)) {

            $self->logger->error(
                "[$key] Already have this key: title/filename clash??");
            $self->logger->errorf('[%s] vs [%s]', $note->file->basename,
                $self->notes->{$key}->file->basename);
            $self->logger->error('Ignoring this key for this run');
            $self->notes->{$key}->ignored(1);

        } else {

            # add note to list
            $self->notes->{$note->key} = $note;
        }

    }

    return 1;
}

method sync_notes {
                    #  look for status of local notes
    $self->_process_local_notes;

    # get list of remote notes
    my $remote_notes = $self->simplenote->get_remote_index;
    if (defined $remote_notes) {

        # if there are any notes, they will need to be merged
        # as simplenote doesn't store title or filename info
        $self->_merge_local_and_remote_lists($remote_notes);
    }

}

method sync_report {
    $self->logger->infof(
        'Examined local files: ' . $self->stats->{local_files});

    $self->logger->infof('New local files: ' . $self->stats->{new_local});
    $self->logger->infof(
        'Updated local files: ' . $self->stats->{update_local});

    $self->logger->infof('New remote files: ' . $self->stats->{new_remote});
    $self->logger->infof(
        'Updated remote files: ' . $self->stats->{update_remote});

    $self->logger->infof(
        'Deleted local files: ' . $self->stats->{deleted_local});
    $self->logger->infof('Ignored remote trash: ' . $self->stats->{trash});

}

method edit($file) {
    my $ext = '.txt';
    my $note = App::SimplenoteSync::Note->new(file => $file);
    $self->logger->infof('Editing file: [%s]', $note->file->stringify);

    if (!-e $note->file) {
        require File::Basename;
        my ($title) = File::Basename::fileparse($file, qr/\.[^.]*/);
        $self->logger->info('Creating new file');

        if ($note->is_markdown) {
            $title = "# $title";
        }
        $note->content("$title\n\n");
    } else {
        $self->_read_note_metadata($note);
        $note->load_content;
    }

    # make sure we get correct highlighting
    if ($note->is_markdown) {
        $ext = '.markdown';
    }

    my $editor = Proc::InvokeEditor->new;

    if (defined $self->editor) {
        $self->logger->debugf('Overriding editor to [%s]', $self->editor);
        $editor->editors([$self->editor]);
    }

    my $new_content = $editor->edit($note->content, $ext);

    if ($new_content eq $note->content) {
        $self->logger->info('No changes made');
        return 1;
    }

    $note->content($new_content);
    $note->save_content
      or return;

    $self->logger->infof('Saved new content to [%s]', $note->file->basename);

    # set times
    $note->createdate($note->file->stat->ctime);
    $note->modifydate($note->file->stat->mtime);

    $self->_put_note($note);
    $self->_write_note_metadata($note);

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=for :stopwords Ioan Rogers Fletcher T. Penney github

=head1 NAME

App::SimplenoteSync - Synchronise text notes with simplenoteapp.com

=head1 VERSION

version 0.2.0

=head1 AUTHORS

=over 4

=item *

Ioan Rogers <ioanr@cpan.org>

=item *

Fletcher T. Penney <owner@fletcherpenney.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Ioan Rogers.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/ioanrogers/App-SimplenoteSync/issues>.

=head1 SOURCE

The development version is on github at L<http://github.com/ioanrogers/App-SimplenoteSync>
and may be cloned from L<git://github.com/ioanrogers/App-SimplenoteSync.git>

=cut

