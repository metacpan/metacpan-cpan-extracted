# ABSTRACT: Ref-backed board storage for karr

package App::karr::BoardStore;
our $VERSION = '0.500';
use Moo;
use Path::Tiny qw( path );
use YAML::XS qw( DumpFile LoadFile );
use Time::Piece;
use App::karr::Config;
use App::karr::Task;

has git => (
    is       => 'ro',
    required => 1,
);


sub board_exists {
    my ($self) = @_;
    return $self->git->ref_exists('refs/karr/config');
}


sub has_board_refs {
    my ($self) = @_;
    my @refs = $self->list_karr_refs;
    return @refs ? 1 : 0;
}


sub load_config_overrides {
    my ($self) = @_;
    my $data = $self->git->read_config_ref;
    return ref $data eq 'HASH' ? $data : {};
}


sub load_config {
    my ($self) = @_;
    return App::karr::Config->effective_config( $self->load_config_overrides );
}


sub effective_config {
    my ($self) = @_;
    return $self->{_effective_config} //= $self->load_config;
}


sub all_status_names {
    my ($self) = @_;
    my $ec = $self->effective_config;
    return map { ref $_ ? $_->{name} : $_ } @{$ec->{statuses} // []};
}


sub status_requires_claim {
    my ($self, $status_name) = @_;
    return App::karr::Config->from_merged( $self->effective_config )
        ->status_requires_claim($status_name);
}


sub is_terminal_status {
    my ($self, $status_name) = @_;
    # Through the board's own config, not the class default: an imported
    # kanban-md board names its final column whatever it likes (ticket #67).
    return App::karr::Config->from_merged( $self->effective_config )
        ->is_terminal_status($status_name);
}


sub foundation_enabled {
    my ($self) = @_;
    return App::karr::Config->from_merged( $self->effective_config )
        ->foundation_enabled;
}


sub foundation_reason {
    my ($self) = @_;
    return App::karr::Config->from_merged( $self->effective_config )
        ->foundation_reason;
}


sub set_foundation_enabled {
    my ( $self, $enabled, $reason ) = @_;
    my $effective = $self->effective_config;
    $effective->{foundation} = {} unless ref $effective->{foundation} eq 'HASH';
    $effective->{foundation}{enabled} = $enabled ? 1 : 0;
    if ( defined $reason && length $reason ) {
        $effective->{foundation}{reason} = $reason;
    } else {
        delete $effective->{foundation}{reason};
    }
    return $self->save_config($effective);
}


sub save_config {
    my ( $self, $effective ) = @_;
    # The single write choke point for refs/karr/config, so validating here is
    # what makes `karr config set`, `karr import` and `karr disable` all refuse
    # a broken schema (ticket #78). Callers hand in either a full effective
    # config or the sparse contents of a config.yml, so merge first -- merging
    # an already-effective config with the defaults is a no-op.
    App::karr::Config->validate(
        App::karr::Config->effective_config($effective) );
    my $defaults = App::karr::Config->default_config;
    my $overrides = _diff_hashes( $defaults, $effective );
    $overrides->{version} = $effective->{version} // 1;
    delete $self->{_effective_config};  # invalidate cache
    return $self->git->write_config_ref($overrides);
}


sub peek_next_id {
    my ($self) = @_;
    return $self->git->read_next_id_ref;
}


sub allocate_next_id {
    my ($self) = @_;
    return $self->git->allocate_next_id_ref;
}


sub set_next_id {
    my ( $self, $next_id ) = @_;
    return $self->git->write_next_id_ref($next_id);
}


sub ensure_next_id {
    my ($self) = @_;
    my ($max) = sort { $b <=> $a } $self->git->list_task_refs;
    my $floor = defined $max ? $max + 1 : 1;

    # A board with no counter yet gets one; a board that already has one only
    # ever moves forward.
    return $self->set_next_id($floor)
        unless $self->git->ref_exists('refs/karr/meta/next-id');
    return 1 if $self->peek_next_id >= $floor;
    return $self->set_next_id($floor);
}


sub stamp_encoding_version {
    my ($self) = @_;
    return $self->git->write_encoding_version;
}


sub board_id {
    my ($self) = @_;
    return $self->git->read_board_id_ref;
}


sub ensure_board_id {
    my ($self) = @_;
    return $self->git->ensure_board_id_ref;
}


# The grep is not redundant with the /data-only match in list_task_refs: a ref
# that exists but holds no parseable card still loads as undef, and every
# consumer of this list calls methods on each element. One undef in here took
# out list, board, materialize and pick at once (#45), so the board list is
# filtered at the single point that produces it rather than at each of them.
sub load_tasks {
    my ($self) = @_;
    my @ids = $self->git->list_task_refs;
    return grep { defined } map { $self->git->load_task_ref($_) } @ids;
}


sub find_task {
    my ( $self, $id ) = @_;
    return $self->git->load_task_ref($id);
}


sub find_task_with_oid {
    my ( $self, $id ) = @_;
    return $self->git->load_task_ref_with_oid($id);
}


sub save_task {
    my ( $self, $task ) = @_;
    # Bump `updated` centrally on every mutation of an existing task, so
    # move/edit/pick/handoff/archive get a fresh timestamp for free. A brand
    # new task keeps its own `updated` (== created); the restore/import path in
    # serialize_from bypasses this via git->save_task_ref to preserve stamps.
    my $ref = "refs/karr/tasks/" . $task->id . "/data";
    $task->updated( gmtime->datetime . 'Z' ) if $self->git->ref_exists($ref);
    return $self->git->save_task_ref($task);
}


sub save_task_cas {
    my ( $self, $task, $expected_oid ) = @_;
    # The card came from find_task_with_oid, so the ref exists by construction
    # and the `updated` bump is unconditional (see save_task above).
    $task->updated( gmtime->datetime . 'Z' );
    return $self->git->save_task_ref_cas( $task, $expected_oid );
}


sub delete_task {
    my ( $self, $id ) = @_;
    return $self->git->delete_ref("refs/karr/tasks/$id/data");
}


sub list_karr_refs {
    my ($self) = @_;
    return $self->git->list_refs('refs/karr/');
}


sub delete_all_karr_refs {
    my ($self) = @_;
    return $self->git->delete_refs('refs/karr/');
}


sub materialize_to {
    my ( $self, $board_dir, %args ) = @_;
    $board_dir = path($board_dir);
    my $tasks_dir   = $board_dir->child('tasks');
    my $config_file = $board_dir->child('config.yml');

    my @stale = $self->_materialized_cards($tasks_dir);

    # Ticket #48: the view is written into the working tree, and `tasks/` and
    # `config.yml` at a repository root are perfectly ordinary names for a
    # project to already use. Overwriting or deleting a file Git tracks is data
    # loss from a command that only reads the board, so check before writing
    # anything at all -- not even the directories are created on this path.
    unless ( $args{force} ) {
        my @tracked = grep { $self->git->is_tracked($_) } $config_file, @stale;
        die "Refusing to materialize into $board_dir: "
            . scalar(@tracked)
            . " file(s) there are tracked by git and would be overwritten or deleted:\n"
            . join( '', map { '  ' . $_->relative($board_dir) . "\n" } @tracked )
            . "The file view is disposable board state, not project content. Move those files\n"
            . "aside, or re-run with --force to replace them.\n"
            if @tracked;
    }

    $board_dir->mkpath;
    $tasks_dir->mkpath;

    {
        # kanban-md's schema types several config keys as Go bools and rejects
        # the integers Perl uses for them; JSON::PP is YAML::XS's mode name for
        # "dump JSON::PP::Boolean as a real YAML boolean" (ticket #60).
        local $YAML::XS::Boolean = 'JSON::PP';
        DumpFile(
            $config_file->stringify,
            App::karr::Config->file_view_config(
                $self->load_config,
                next_id => $self->peek_next_id,
            ),
        );
    }

    $_->remove for @stale;

    for my $task ( $self->load_tasks ) {
        $task->save($tasks_dir);
    }

    return $board_dir;
}


# The files in tasks/ that a previous materialization could have written, i.e.
# everything shaped like App::karr::Task::filename -- which is also kanban-md's
# own task-filename prefix (`^(\d+)-` in internal/task/find.go). Anything else
# in the directory belongs to the project, not to karr, and is never swept
# (ticket #48).
sub _materialized_cards {
    my ( $self, $tasks_dir ) = @_;
    return () unless $tasks_dir->exists;
    return sort { $a->basename cmp $b->basename }
        $tasks_dir->children(qr/\A\d+-.*\.md\z/);
}

sub file_view_gitignore_entries {
    # The disposable file view materialize_to writes: config.yml + tasks/*.md.
    # These must always be gitignored -- refs/karr/* is the canonical state and
    # the view is never committed. Mirror the exact names used by materialize_to.
    return ( 'tasks/', 'config.yml' );
}


sub project_owned_view_paths {
    my ( $self, $board_dir ) = @_;
    $board_dir = path($board_dir);
    return grep { $self->git->is_tracked_under( $board_dir->child( $_ =~ s{/\z}{}r ) ) }
        $self->file_view_gitignore_entries;
}


sub ensure_gitignore {
    my ( $self, $board_dir ) = @_;
    $board_dir = path($board_dir);
    my $gitignore = $board_dir->child('.gitignore');

    my @entries  = $self->file_view_gitignore_entries;
    my $existing = $gitignore->exists ? $gitignore->slurp_utf8 : '';

    # Line-exact presence (whitespace-insensitive), so we never duplicate an
    # entry -- or our header -- that is already there.
    my %present;
    for my $line ( split /\n/, $existing ) {
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        $present{$line} = 1 if length $line;
    }

    my @missing = grep { !$present{$_} } @entries;
    return () unless @missing;

    my $header         = '# karr materialized task view -- never commit';
    my $header_present = $present{$header} ? 1 : 0;

    # Idempotent append that keeps the existing file intact: terminate a
    # dangling last line, separate a fresh karr block with a blank line, and
    # only emit the header when starting one.
    my $append = '';
    if ( length $existing ) {
        $append .= "\n" unless $existing =~ /\n\z/;
        $append .= "\n" unless $header_present;
    }
    $append .= "$header\n" unless $header_present;
    $append .= "$_\n" for @missing;

    $gitignore->append_utf8($append);
    return @missing;
}


sub serialize_from {
    my ( $self, $board_dir ) = @_;
    $board_dir = path($board_dir);

    # Whether this import is the board's birth or a write into one that was
    # already here. Asked before anything below writes a ref, since every write
    # would answer it "already here"; the encoding marker at the bottom hangs
    # on the difference (#132).
    my $born_here = !$self->has_board_refs;

    # Ticket #70: parse the entire view before a single ref is touched, so one
    # malformed card leaves the board exactly as it was instead of half
    # imported with the prune never reached. Reading the config here rather
    # than writing it keeps that promise for the config too.
    my $tasks_dir = $board_dir->child('tasks');
    my @files     = $tasks_dir->exists
        ? sort { $a->basename cmp $b->basename } $tasks_dir->children(qr/\.md$/)
        : ();

    my ( @tasks, @rejected );
    for my $file (@files) {
        my $task = eval { App::karr::Task->from_file($file) };
        if   ($task) { push @tasks, $task }
        else         { push @rejected, ( $@ || "unknown error\n" ) }
    }
    # kanban-md skips malformed files and carries on, but import cannot: a
    # skipped card's ref would be pruned below, turning an unreadable file into
    # a deleted task. All or nothing -- and every rejected file is named, which
    # a bare "Invalid task format" never was.
    if (@rejected) {
        die "Refusing to import from $board_dir: "
            . scalar(@rejected)
            . " of " . scalar(@files) . " task file(s) could not be parsed:\n"
            . join( '', map { my $why = $_; chomp $why; "  $why\n" } @rejected )
            . "No refs were changed. Fix or remove those files and import again.\n";
    }

    my $config_file = $board_dir->child('config.yml');
    my $config = $config_file->exists
        ? ( LoadFile( $config_file->stringify ) // {} )
        : undef;
    # A config.yml that is not a mapping is a broken view, and the import path
    # names what is wrong with a view rather than dying inside a dereference --
    # the same promise it already makes for a malformed card above. Reaching
    # the delete below with a list here died with a bare "Not a HASH reference"
    # and a line number.
    die "Refusing to import from $board_dir: "
        . "its config.yml is not a mapping.\nNo refs were changed.\n"
        if defined $config && ref $config ne 'HASH';

    my $view_next_id;
    if ( defined $config ) {
        # next_id belongs to refs/karr/meta/next-id, not to the config; the
        # seeding below owns it. materialize writes it into the view purely
        # because kanban-md refuses a config without it (ticket #60) -- but the
        # value still carries information, so keep it for the floor below.
        my $raw = delete $config->{next_id};
        $view_next_id = $raw
            if defined $raw && !ref $raw && $raw =~ /\A\d+\z/ && $raw >= 1;
    }

    # Nothing above this line wrote anything.
    if ( defined $config ) {
        # Reconcile against what refs/karr/config already says instead of
        # replacing it (tickets #87, #88). The file view is a lossy projection:
        # kanban-md rewrites config.yml as soon as it loads one and drops every
        # key its Go schema does not know, so a replace silently un-did
        # `karr disable` and recorded kanban-md's migrated defaults as
        # deliberate per-board overrides.
        $self->save_config(
            App::karr::Config->reconcile_view_config(
                $self->load_config_overrides, $config ) );
    }
    elsif ( !$self->board_exists ) {
        # Import is a bootstrap path (#30), so it has to leave a board karr
        # will actually write to. A kanban-md tasks/ view with no config.yml
        # otherwise produced tasks and a counter but no refs/karr/config --
        # exactly the half-board every write command now refuses (#62), which
        # made `karr create` right after a successful import impossible.
        $self->save_config( App::karr::Config->default_config );
    }

    my %seen;
    for my $task (@tasks) {
        # Restore/import path: persist verbatim so the original `updated`
        # timestamps survive, even when overwriting pre-existing refs.
        $self->git->save_task_ref($task);
        $seen{ $task->id } = 1;
    }

    for my $id ( $self->git->list_task_refs ) {
        next if $seen{$id};
        $self->delete_task($id);
    }

    # Bootstrap fix (#30): import does not require a pre-existing board, so on a
    # fresh repo meta/next-id is missing and a following `karr create` would
    # re-allocate an already-imported id. Seed next-id past the highest imported
    # id when the stored next-id is missing or stale, but never lower a next-id
    # that is already ahead of the view (an existing healthy board is untouched).
    #
    # The view's own next_id is part of that floor (ticket #90). Seeding from
    # the highest card alone retired ids the other side of the bridge had
    # already burned: a kanban-md board whose next_id ran ahead of its highest
    # card -- which is every board that ever lost one -- handed the next
    # `karr create` an id kanban-md considers used. Forward only, in both
    # directions, which is kanban-md's own rule for this value
    # (internal/task/consistency.go, syncNextID: max(stored, highest id + 1)).
    my $floor = 1;
    if (%seen) {
        my ($max_id) = sort { $b <=> $a } keys %seen;
        $floor = $max_id + 1;
    }
    $floor = $view_next_id if defined $view_next_id && $view_next_id > $floor;
    $self->set_next_id($floor) if $self->peek_next_id < $floor;

    # Everything just written came from character-level file reads (LoadFile,
    # Task->from_file) and so satisfies the current encoding contract -- but the
    # marker speaks for the whole board, not for the refs this import happened
    # to rewrite. On a board that was already here, import replaces the task
    # refs and leaves the activity log under refs/karr/log/ alone (and the
    # config too, when the view carries no config.yml), so a pre-0.403 board
    # keeps double-encoded payloads that the marker would then declare clean:
    # every old log entry read as mojibake and `karr repair` reported the board
    # as up to date (#132, the same defect as `karr init` on a half-board).
    # Only a board born in this import gets the claim; on any other, the
    # read-path repair keeps running and `karr repair --yes` stays the one
    # command that may stamp, because it is the one that rewrites every ref.
    $self->stamp_encoding_version if $born_here;

    # Import is a board-birth path like init (#30), so it stamps the board
    # identity too (#95) rather than waiting for the first pull to notice the
    # board has none. Read-before-write inside, same as the encoding marker
    # above: an existing board keeps the id it has.
    $self->ensure_board_id;

    return 1;
}


sub snapshot {
    my ($self) = @_;
    my %snapshot;
    for my $ref ( $self->list_karr_refs ) {
        $snapshot{$ref} = $self->git->read_ref($ref);
    }
    return {
        version => 1,
        refs => \%snapshot,
    };
}


sub restore_snapshot {
    my ( $self, $snapshot ) = @_;
    my $refs = $snapshot->{refs} || {};
    # A snapshot taken before board identities existed carries no board-id
    # ref, and replace_board_refs makes the board exactly the snapshot -- so
    # installing one verbatim would strip this board's identity, and the push
    # that follows would prune it off the remote too, disarming the
    # swapped-remote guard (#95) on every clone. Keep the standing id across
    # such a content restore. A snapshot that does carry an id -- the board's
    # own, or a foreign board's in a deliberate takeover -- is installed as is.
    my $standing = $self->git->read_board_id_ref;
    my $ok = $self->git->replace_board_refs($refs);
    $self->git->write_board_id_ref($standing)
        if defined $standing && !exists $refs->{'refs/karr/meta/board-id'};
    return $ok;
}


sub _diff_hashes {
    my ( $defaults, $effective ) = @_;
    my %diff;
    for my $key ( keys %{ $effective // {} } ) {
        next if $key eq 'next_id';
        my $have_default = exists $defaults->{$key};
        my $default = $defaults->{$key};
        my $value   = $effective->{$key};

        if ( ref($value) eq 'HASH' && ref($default) eq 'HASH' ) {
            my $nested = _diff_hashes( $default, $value );
            $diff{$key} = $nested if keys %$nested;
        } elsif ( !$have_default || !_same_value( $default, $value ) ) {
            $diff{$key} = $value;
        }
    }
    return \%diff;
}

sub _same_value {
    my ( $left, $right ) = @_;
    return 0 if ref($left) ne ref($right);
    if ( ref($left) eq 'HASH' ) {
        return 0 unless keys(%$left) == keys(%$right);
        for my $key ( keys %$left ) {
            return 0 unless exists $right->{$key};
            return 0 unless _same_value( $left->{$key}, $right->{$key} );
        }
        return 1;
    }
    if ( ref($left) eq 'ARRAY' ) {
        return 0 unless @$left == @$right;
        for my $i ( 0 .. $#$left ) {
            return 0 unless _same_value( $left->[$i], $right->[$i] );
        }
        return 1;
    }
    return ( defined $left ? $left : '' ) eq ( defined $right ? $right : '' );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::BoardStore - Ref-backed board storage for karr

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    my $store = App::karr::BoardStore->new( git => $git );
    my $config = $store->load_config;
    my $id = $store->allocate_next_id;
    my @tasks = $store->load_tasks;

=head1 DESCRIPTION

L<App::karr::BoardStore> treats C<refs/karr/*> as the canonical board state.
It can merge sparse config overrides with code defaults, allocate numeric task
ids through a dedicated metadata ref, and materialize or serialize temporary
board views for command handlers that still work with files internally.

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Git>, L<App::karr::Task>,
L<App::karr::Config>

=head2 board_exists

True when this repository holds an initialized board, which means exactly one
thing: C<refs/karr/config> is there. It used to accept C<refs/karr/meta/next-id>
on its own as well, and that is how a stray C<karr create> in the wrong
directory produced a board that C<karr init> then refused to touch for good --
the half-board counted as existing, so the name, the statuses and the
F<.gitignore> entries could never be written (#62).

    my $whole = $store->board_exists;

Callers state the refusal through L<App::karr::Role::BoardDiscovery/require_board>
rather than testing this themselves: a repository that fails this check may
still hold a half-board's tasks, and the two cases need different words (#133).

=head2 has_board_refs

True when anything at all lives under C<refs/karr/>, initialized board or not.
This is the question the commands that clean up or read raw refs
(C<backup>, C<destroy>, C<materialize>, C<repair>) actually have: refusing them
on a half-board would strand the refs a pre-fix karr already left behind, with
no way to remove them from inside karr.

    my $anything_here = $store->has_board_refs;

=head2 load_config_overrides

Returns the board's raw config overrides -- whatever C<refs/karr/config>
currently holds, decoded but not merged with the code defaults. A board with
no config ref yet, or one whose ref does not decode to a mapping, answers
C<{}> rather than C<undef> or dying.

    my $overrides = $store->load_config_overrides;   # sparse, not effective

This is the input L</load_config> merges over
L<App::karr::Config/default_config>; see that method for the merged result,
and L</effective_config> for its cached form.

=head2 load_config

Reads L</load_config_overrides> and merges them over the code defaults via
L<App::karr::Config/effective_config>, returning a plain hash reference --
not a blessed L<App::karr::Config> object. Every call re-reads the config
ref; L</effective_config> is the cached wrapper most callers want instead.

    my $ec = $store->load_config;

=head2 effective_config

The board's merged config, cached for the lifetime of this C<$store>
instance. The first call runs L</load_config>; every call after returns the
same hash reference until L</save_config> invalidates the cache. This is the
entry point almost every command and role uses --
C<< App::karr::Config->from_merged( $store->effective_config ) >> is the
standard way to get a queryable L<App::karr::Config> object for the current
board (see L<App::karr::Config/from_merged>).

Not to be confused with the class method
L<App::karr::Config/effective_config>, which does the actual default/override
merge and takes no board at all; this method is the per-store cache built on
top of it.

    my $ec = $store->effective_config;
    my $config = App::karr::Config->from_merged($ec);

=head2 all_status_names

Returns a list of all status names from the effective config.

    my @statuses = $store->all_status_names;

=head2 status_requires_claim

Returns true if the given status requires a claim.

    if ($store->status_requires_claim('in-progress')) {
        # must use --claim to move here
    }

=head2 is_terminal_status

Returns true if the status is terminal for this board -- its final configured
status, or C<archived>.

    unless ($store->is_terminal_status($task->status)) {
        # task is still active
    }

=head2 foundation_enabled

Returns true when automated agent runs are allowed on this board
(C<foundation.enabled> in C<refs/karr/config>; boards default to enabled).

    unless ($store->foundation_enabled) {
        # karr-foundation skips this board entirely
    }

=head2 foundation_reason

Returns the reason recorded with the disable flag, or undef when none was
given.

    my $why = $store->foundation_reason;

=head2 set_foundation_enabled

Writes the board-level agent switch and its optional reason back into
C<refs/karr/config>. Re-enabling drops the reason, and because C<enabled> then
matches the code default the whole C<foundation> key disappears from the sparse
overrides again.

    $store->set_foundation_enabled( 0, 'abandoned driver' );
    $store->set_foundation_enabled( 1 );

=head2 save_config

Validates a config and writes it back to C<refs/karr/config> as sparse
overrides. C<$effective> may be a full effective config or the sparse
contents of a F<config.yml> -- both are merged over the defaults first (a
no-op for an already-effective config), then validated with
L<App::karr::Config/validate> (dies on a broken schema), then diffed against
L<App::karr::Config/default_config> so only the keys that differ from the
code defaults are actually stored. This is the single write choke point for
the config ref, so every writer (C<karr config set>, C<karr init>, C<karr
disable>/C<karr enable>, C<karr import>) shares one validation gate (ticket
#78).

Invalidates this store's L</effective_config> cache before writing, so the
next read reflects what was just saved.

    $store->save_config($effective);

=head2 peek_next_id

Returns the board's next-id counter as it currently stands, without
allocating or advancing it. Contrast with L</allocate_next_id>, which hands
out the value and moves the counter past it atomically.

    my $next = $store->peek_next_id;

=head2 allocate_next_id

Returns the next free task id and moves the counter past it, atomically. Two
agents running C<karr create> at the same time are guaranteed different ids;
before this was a compare-and-swap they could both be handed the same one and
the second task overwrote the first (#44).

    my $id = $store->allocate_next_id;

=head2 set_next_id

Writes the next-id counter directly to C<$next_id>, with no compare-and-swap
and no check that the value only moves forward -- callers that need either of
those guarantees provide them themselves (see L</ensure_next_id> and
L</serialize_from>, the only two callers). Prefer L</allocate_next_id> for
ordinary id allocation.

    $store->set_next_id(42);

=head2 ensure_next_id

Seeds the id counter without ever handing out an id that is already taken. On a
fresh board that is C<1>; on a board C<init> is completing rather than creating
it is one past the highest task ref, and an existing counter that is already
further ahead is left alone. C<init> used to write C<1> unconditionally, which
on a half-board (see L</board_exists>) meant the next C<karr create> reused id 1
and overwrote the task that was already there.

    $store->ensure_next_id;

=head2 stamp_encoding_version

Records in C<refs/karr/meta/encoding> that this board's payloads follow the
current character-encoding contract, so nothing reading it applies the
legacy-mojibake repair (see L<App::karr::Encoding>).

    $store->stamp_encoding_version;

The claim covers every ref under C<refs/karr/>, so only a caller that can
vouch for all of them may make it: C<karr repair --yes>, which rewrites them,
and the two board-birth paths -- C<karr init> and L</serialize_from> -- but
in their case B<only> when the board really was born there, i.e. when nothing
lived under C<refs/karr/> beforehand. Neither may stamp a board it is merely
adding to: the refs it did not write may be a 0.402 board's double-encoded
ones, and the marker would silently turn off the repair that still reads them
correctly, while making C<karr repair> report the board as up to date (#132).

=head2 board_id

The board's identity from C<refs/karr/meta/board-id>, or undef when the board
predates identities (or does not exist). The id is what a pull compares
against the remote's to tell "this board, changed" apart from "a different
board entirely" (#95).

    my $id = $store->board_id;

=head2 ensure_board_id

Stamps the board's identity ref when it is missing and returns the id,
existing or new. It never re-keys a board: changing the id under a live board
would make every other clone read it as a foreign one (#95). Called by
C<karr init> and the import path below, the two board-birth paths; boards
from before identities existed are stamped by the first pull that finds no id
on either side.

    $store->ensure_board_id;

=head2 load_tasks

Returns every task on the board as a list of L<App::karr::Task> objects, in
ascending id order (L<App::karr::Git/list_task_refs> sorts numerically). Any
ref that resolves to no C<data> blob -- see L</find_task> -- is silently
skipped rather than returned as C<undef>; a single undef in this list once
took out C<list>, C<board>, C<materialize> and C<pick> at once, since every
consumer calls methods on each element (ticket #45). A ref whose C<data> blob
is present but fails to parse still dies, propagating out of this call.

    my @tasks = $store->load_tasks;

=head2 find_task

Returns the L<App::karr::Task> for C<$id>, or C<undef> when its ref does not
exist or resolves to no C<data> blob at all -- the same tolerant case
L</load_tasks> filters out of a whole-board read. A ref that does exist and
does carry a C<data> blob but fails to parse as a task still dies, the same
as L<App::karr::Task/from_string> would.

    my $task = $store->find_task(7) or die "No such task\n";

=head2 find_task_with_oid

Returns C<< ($oid, $task) >> for one task: the card, plus the OID of the commit
it was read from. Pair it with L</save_task_cas> to write the card back only if
nobody else has touched it in between.

    my ( $oid, $task ) = $store->find_task_with_oid(7);

=head2 save_task

Writes C<$task> to its ref (C<refs/karr/tasks/ID/data>), unconditionally --
no compare-and-swap, so a concurrent writer's change can be lost under it;
see L</save_task_cas> when that matters. Bumps C<updated> to now first, but
only when the ref already exists: a brand new task keeps the C<updated>
value it was constructed with (which for a fresh L<App::karr::Task> equals
C<created>). The restore/import path bypasses this bump entirely by calling
L<App::karr::Git/save_task_ref> directly, to preserve original timestamps --
see L</serialize_from>.

    $store->save_task($task);

=head2 save_task_cas

Writes a card back only if its ref still points at C<$expected_oid>, the OID
L</find_task_with_oid> read it from. Returns true when the write landed and
false when another agent changed the card first -- at which point the caller
must re-read and decide again, never retry with the value that already lost.

This is what makes C<karr pick> exclusive. The lock ref serialises agents but
cannot bind them: its holder identity is the clone's C<user.email>, which every
agent on one machine shares, so twelve parallel picks were all told they owned
the lock and all wrote their claim over each other's (#86). The compare-and-swap
is on the card itself and does not care who thinks it holds what.

    my ( $oid, $task ) = $store->find_task_with_oid(7);
    $task->claimed_by('agent-fox');
    $store->save_task_cas( $task, $oid ) or ...;  # someone else got there first

=head2 delete_task

Deletes the ref for task C<$id> (C<refs/karr/tasks/ID/data>). Returns C<1>
when this call removed it and C<0> when there was no such task -- deleting a
card that is not there is not an error. A removal that is attempted and
refused C<die>s rather than returning C<0>, so a false answer here always
means "no such card", never "it may still be on the board" (see
L<App::karr::Git/delete_ref>).

    $store->delete_task(7);

=head2 list_karr_refs

Returns every ref name under C<refs/karr/>, board and metadata refs alike --
the same broad question L</has_board_refs> asks with just a boolean answer.

    my @refs = $store->list_karr_refs;

=head2 delete_all_karr_refs

Deletes every ref under C<refs/karr/> -- the whole board, metadata included.
Used only by C<karr destroy>; there is no per-piece variant, because a board
is what is being removed, not a task.

    $store->delete_all_karr_refs;

=head2 materialize_to

Writes the board out to C<$board_dir> as a kanban-md file view: a F<config.yml>
plus a F<tasks/> directory of cards. Stale cards from an earlier run are swept
first, but only files named the way karr and kanban-md name them
(C<NNN-slug.md>) -- anything else in F<tasks/> belongs to the project.

Dies without writing anything when the view would overwrite or delete a file
Git tracks, naming each one; C<< force => 1 >> proceeds anyway (ticket #48).

    $store->materialize_to( $git_root );
    $store->materialize_to( $git_root, force => 1 );

=head2 file_view_gitignore_entries

Returns the exact two path entries the materialized file view claims --
C<tasks/> and C<config.yml>, named exactly as L</materialize_to> writes them.
The single source of truth for those two strings, shared by
L</ensure_gitignore> (what to append) and L</project_owned_view_paths> (what
to check for project-tracked content) so the two can never drift apart -- see
that method for why the check matters (tickets #48, #89, #100, #104).

    my @entries = $store->file_view_gitignore_entries;   # ('tasks/', 'config.yml')

=head2 project_owned_view_paths

Which of the C<file_view_gitignore_entries> the project already has content of
its own at, named exactly as F<.gitignore> would have named them. Empty is the
ordinary case, and means the file view owns those paths.

    my @owned = $store->project_owned_view_paths($git_root);
    $store->ensure_gitignore($git_root) unless @owned;

F<tasks/> and F<config.yml> at a repository root are perfectly ordinary names
for a project to already use, and git applies no ignore rule to a file it
already tracks. An entry for such a path would therefore change nothing at all
while telling every later reader that karr owns a path the project owns -- and
it would say so right where L</materialize_to> refuses to write, for that very
reason (tickets #48, #89). C<init> asks before writing the entries, and
C<materialize> asks before topping them up (#100).

L<App::karr::Git/is_tracked_under> answers the whole question in one index
read, for a file or a directory alike -- F<tasks/notes/old.md> makes
F<tasks/> just as owned as F<tasks/README.md> would. It used to be answered by
walking the working tree and asking L<App::karr::Git/is_tracked> per file
found, which cost one status call per card and, more importantly, could not
find a path git tracks but that is currently missing from the working tree --
there is no file there to walk onto. Both are fixed by asking the index
directly instead (#104).

=head2 ensure_gitignore

Idempotently appends any of L</file_view_gitignore_entries> missing from
F<$board_dir/.gitignore> (creating the file, and a header comment, on first
use). Returns the list of entries actually added -- empty when the file
already covers everything.

This method does B<not> itself check whether the project already tracks
content at those paths; it only ever appends. The check is
L</project_owned_view_paths>, a separate call so a caller can ask before
writing anything: C<karr init> and C<karr materialize> both call it first and
skip C<ensure_gitignore> entirely when it returns anything, because appending
an entry for a path git already tracks would be inert at best and misleading
at worst (tickets #48, #89, #100, #104, #107).

    my @owned = $store->project_owned_view_paths($board_dir);
    my @added = @owned ? () : $store->ensure_gitignore($board_dir);

=head2 serialize_from

Reads a file view at C<$board_dir> back into C<refs/karr/*>: task refs are
replaced by the cards, refs the view does not mention are pruned, and the id
counter is moved up to whichever is higher, the highest imported id plus one or
the view's own C<next_id>. It is never moved down -- an id another tool has
already handed out must not be handed out again (ticket #90).

The config is reconciled rather than replaced. Tasks are the whole truth of the
file view; its F<config.yml> is not, because anything that loads the view may
rewrite it into a schema of its own. So the view speaks only for the keys it
carries and karr models, and C<refs/karr/config> keeps the rest -- see
L<App::karr::Config/reconcile_view_config>.

All or nothing. Every card is parsed before the first ref is written, so a
malformed file aborts the whole import -- listing each rejected file and its
reason -- with the board left exactly as it was (ticket #70). Refusing an empty
view is the caller's job; see L<App::karr::Cmd::Import>.

Importing into a repository that held nothing under C<refs/karr/> also creates
the board: it writes a config when the view has none, seeds the counter, stamps
the board identity, and stamps the encoding marker. Importing into a board that
was already there does B<not> stamp the marker -- see
L</stamp_encoding_version>.

    $store->serialize_from( $git_root );

=head2 snapshot

Reads every ref under C<refs/karr/> into a plain hash reference:
C<< { version => 1, refs => { $ref_name => $content, ... } } >>, where
C<$content> is that ref's raw stored text (config YAML, a task's Markdown
document, or a bare id/hex string for the meta refs) via
L<App::karr::Git/read_ref>. C<karr backup> writes this straight to YAML; pair
with L</restore_snapshot> to write one back onto C<refs/karr/*>.

    my $snapshot = $store->snapshot;

=head2 restore_snapshot

Makes the board consist of exactly the refs in the snapshot. Every ref name is
checked and every commit object built before the first ref moves, so a snapshot
karr cannot write is refused with the board untouched instead of destroying it
on the way through (#47). See L<App::karr::Git/replace_board_refs>.

    $store->restore_snapshot( $snapshot );

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/karr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
