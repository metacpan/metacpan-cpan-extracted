package BoardStreams::Transaction;

use Mojo::Base -base, -signatures;

use Mojo::JSON 'from_json', 'to_json', 'encode_json';
use Mojo::IOLoop;
use Struct::Diff 'diff';
use List::AllUtils 'each_array', 'indexes';
use Storable 'dclone';
use Carp 'croak';

our $VERSION = "v0.0.23";

has bs_prefix => sub { die "bs_prefix is required" };
has c => sub { die "c is required" };
has notify_payload_size_limit => sub { die "notify_payload_size_limit is required" };
has event_patch_sequence_name => sub { die "event_patch_sequence_name is required" };
has 'db';
has 'pg_tx';

my $WORKERS_CHANNEL = '_bs:workers';

sub new ($class, @args) {
    my $self = $class->SUPER::new(@args);

    my $bs_prefix = $self->bs_prefix;

    # fill-in db
    my $db = $self->c->$bs_prefix->db;
    $self->db($db);

    # fill-in pg_tx
    my $pg_tx = $db->begin;
    $self->pg_tx($pg_tx);

    return $self;
}

sub commit ($self) {
    $self->pg_tx->commit;
}

sub lock_state ($self, $channel_names, $sub, %opts) {
    # opts can be: no_ban

    my $bs_prefix = $self->bs_prefix;
    my $worker_uuid = $self->c->$bs_prefix->worker_uuid;
    my $notify_payload_size_limit = $self->notify_payload_size_limit;
    my $event_patch_sequence_name = $self->event_patch_sequence_name;

    my $multi_mode = ref $channel_names eq 'ARRAY';
    $channel_names = [$channel_names] if not $multi_mode;
    my $db = $self->db;
    my $tx = $self->pg_tx;
    my $rows = $db->select('channel',
        [qw/ id name state keep_events /],
        { name => {-in => $channel_names} },
        { for => 'update' },
    )->hashes;

    if (! $opts{no_ban} and Mojo::IOLoop->is_running) {
        my $workers_state = $self->c->$bs_prefix->get_state($WORKERS_CHANNEL);
        $workers_state->{$worker_uuid}
            and ! $workers_state->{$worker_uuid}{banned}
            or die "worker is banned from lock_state";
    }

    my %rows = map {( $_->{name}, $_ )} @$rows;
    my @rows = @rows{@$channel_names};
    # TODO: IMPORTANT! throw a machine-readable, JSON-able exception if any of the @rows are undef.
    {
        my @indexes = indexes { ! defined $_ } @rows;
        @indexes or last;
        my @missing_names = @$channel_names[@indexes];
        local $" = ', ';
        my $error = "lock_state error: Channel(s) @missing_names do not exist";
        $self->c->app->log->error($error); # TODO: What happens if $self->c is already the app?
        croak $error;
    }
    my @orig_states = map { from_json $_->{state} } @rows;
    my @clone_states = map { dclone([$_])->[0] } @orig_states;

    my @answers = $sub->($multi_mode ? \@clone_states : $clone_states[0]);
    @answers = ([@answers]) if not $multi_mode;

    my sub do_notifications ($channel_name, $event_id, $event, $diff) {
        my $bytes = encode_json({
            id   => int $event_id,
            data => {
                event => $event,
                patch => $diff,
            },
        });
        my $bytes_length = length($bytes);

        if ($bytes_length <= $notify_payload_size_limit) {
            $db->notify($channel_name, $bytes);
            return;
        }

        # my $i = 0;
        my $ending_bytes_prefix = ":$event_id end: ";
        my $sent_ending = 0;
        for (my ($i, $cursor) = (0, 0); ! $sent_ending; $i++) {
            my $remaining_length = $bytes_length - $cursor;
            my $bytes_prefix;
            if (length($ending_bytes_prefix) + $remaining_length <= $notify_payload_size_limit) {
                $bytes_prefix = $ending_bytes_prefix;
                $sent_ending = 1;
            } else {
                $bytes_prefix = ":$event_id $i: ";
            }

            my $sublength = $notify_payload_size_limit - length $bytes_prefix;
            my $substring = $remaining_length >= 0 ? substr($bytes, $cursor, $sublength) : '';
            $cursor += $sublength;

            my $piece = $bytes_prefix . $substring;
            $db->notify($channel_name, $piece);
        }
    }

    my $ea = each_array(@rows, @answers, @orig_states);
    ANSWER:
    while( my ($row, $answer, $orig_state) = $ea->() ) {

        my ($event, $new_state, $guard_inc) = @$answer;
        my ($channel_id, $channel_name, $keep_events) = $row->@{qw/ id name keep_events /};

        {
            my @events = ref($event) eq 'REF' ? @$$event : ($event);
            @events = grep defined, @events;
            $event = pop @events;

            # for all but last event
            foreach my $event (@events) {
                my ($event_id, $dt);
                if ($keep_events) {
                    ($event_id, $dt) = $db->insert('event_patch',
                        {
                            channel_id => $channel_id,
                            event      => to_json($event),
                        },
                        { returning => ['id', 'datetime'] },
                    )->hash->@{qw/ id datetime /};
                } else {
                    ($event_id, $dt) =
                        $db->query(
                            "SELECT nextval(?), current_timestamp",
                            $event_patch_sequence_name
                        )->array->@*;
                }

                do_notifications($channel_name, $event_id, $event, undef);
            }
        }

        next ANSWER unless defined $event or defined $new_state;
        my $diff = defined $new_state ? diff($orig_state, $new_state, noO => 1, noU => 1) : undef;
        $diff = undef if $diff and ! %$diff;
        next ANSWER unless defined $event or defined $diff;
        my ($event_id, $dt);
        if ($keep_events and defined $event) {
            ($event_id, $dt) = $db->insert('event_patch',
                {
                    channel_id => $channel_id,
                    event      => to_json($event),
                },
                { returning => ['id', 'datetime'] },
            )->hash->@{qw/ id datetime /};
        } else {
            ($event_id, $dt) =
                $db->query(
                    "SELECT nextval(?), current_timestamp",
                    $event_patch_sequence_name
                )->array->@*;
        }
        $db->update('channel',
            {
                event_id => $event_id,
                last_dt  => $dt,
                defined $new_state ? (state => to_json $new_state) : (),
            },
            { id => $channel_id },
        );

        # update guards
        {
            $guard_inc = int($guard_inc // 0);
            if ($guard_inc > 0) {
                $db->insert('guards',
                    {
                        worker_uuid => $worker_uuid,
                        channel_id  => $channel_id,
                        counter     => $guard_inc,
                    },
                    {
                        on_conflict => [
                            [qw/ worker_uuid channel_id /],
                            { counter => \"guards.counter + $guard_inc" },
                        ],
                    },
                );
            } elsif ($guard_inc < 0) {
                $db->update('guards',
                    { counter => \"counter $guard_inc" }, # impl. minus
                    {
                        worker_uuid => $worker_uuid,
                        channel_id  => $channel_id,
                    },
                );
                $db->delete('guards',
                    {
                        worker_uuid => $worker_uuid,
                        channel_id  => $channel_id,
                        counter     => {'<=', 0},
                    },
                );
            }
        }

        do_notifications($channel_name, $event_id, $event, $diff);
    }

    # return
    my @new_states = map $_->[1], @answers;
    return $multi_mode ? \@new_states : $new_states[0];
}

1;