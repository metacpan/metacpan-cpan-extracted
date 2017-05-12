package BusyBird::Timeline;
use v5.8.0;
use strict;
use warnings;
use BusyBird::Util qw(set_param);
use BusyBird::Log qw(bblog);
use BusyBird::Flow;
use BusyBird::Watcher::Aggregator;
use BusyBird::DateTime::Format 0.04;
use BusyBird::Config;
use Async::Selector 1.0;
use Data::UUID;
use Carp;
use Storable qw(dclone);
use Scalar::Util qw(weaken looks_like_number);
use DateTime;

our @CARP_NOT = qw(BusyBird::Config);

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        filter_flow => BusyBird::Flow->new,
        selector => Async::Selector->new,
        unacked_counts => {total => 0},
        config => BusyBird::Config->new(type => "timeline", with_default => 0),
        id_generator => Data::UUID->new,
    }, $class;
    $self->set_param(\%args, 'name', undef, 1);
    $self->set_param(\%args, 'storage', undef, 1);
    $self->set_param(\%args, 'watcher_max', 512);
    croak 'name must not be empty' if $self->{name} eq '';
    $self->_init_selector();
    $self->_update_unacked_counts();
    return $self;
}

sub _log {
    my ($self, $level, $msg) = @_;
    bblog($level, $self->name . ": $msg");
}

sub _update_unacked_counts {
    my ($self) = @_;
    $self->get_unacked_counts(callback => sub {
        my ($error, $unacked_counts) = @_;
        if(defined($error)) {
            $self->_log('error', "error while updating unacked count: $error");
            return;
        }
        $self->{unacked_counts} = $unacked_counts;
        $self->{selector}->trigger('unacked_counts');
    });
}

sub _init_selector {
    my ($self) = @_;
    weaken $self;
    $self->{selector}->register(unacked_counts => sub {
        my ($exp_unacked_counts) = @_;
        if(!defined($exp_unacked_counts) || ref($exp_unacked_counts) ne 'HASH') {
            croak "unacked_counts watcher: condition input must be a hash-ref";
        }
        return { %{$self->{unacked_counts}} } if !%$exp_unacked_counts;
        foreach my $key (keys %$exp_unacked_counts) {
            my $exp_val = $exp_unacked_counts->{$key} || 0;
            my $got_val = $self->{unacked_counts}{$key} || 0;
            return { %{$self->{unacked_counts}} } if $exp_val != $got_val;
        }
        return undef;
    });
    $self->{selector}->register(watcher_quota => sub {
        my ($in) = @_;
        my @watchers = $self->{selector}->watchers('watcher_quota');
        if(int(@watchers) <= $self->{watcher_max}) {
            return undef;
        }
        my $watcher_age = $in->{age} || 0;
        return $watcher_age > $self->{watcher_max} ? 1 : undef;
    });
}

sub name {
    return shift->{name};
}

sub _get_from_storage {
    my ($self, $method, $args_ref) = @_;
    $args_ref->{timeline} = $self->name;
    local @CARP_NOT = (ref($self->{storage}));
    $self->{storage}->$method(%$args_ref);
}

sub get_statuses {
    my ($self, %args) = @_;
    $self->_get_from_storage("get_statuses", \%args);
}

sub get_unacked_counts {
    my ($self, %args) = @_;
    $self->_get_from_storage("get_unacked_counts", \%args);
}

sub _write_statuses {
    my ($self, $method, $args_ref) = @_;
    $args_ref->{timeline} = $self->name;
    local @CARP_NOT = (ref($self->{storage}));
    my $orig_callback = $args_ref->{callback};
    $self->{storage}->$method(%$args_ref, callback => sub {
        $self->_update_unacked_counts();
        goto $orig_callback if defined($orig_callback);
    });
}

sub put_statuses {
    my ($self, %args) = @_;
    $self->_write_statuses('put_statuses', \%args);
}

sub delete_statuses {
    my ($self, %args) = @_;
    $self->_write_statuses('delete_statuses', \%args);
}

sub ack_statuses {
    my ($self, %args) = @_;
    $self->_write_statuses('ack_statuses', \%args);
}

sub add_statuses {
    my ($self, %args) = @_;
    if(!defined($args{statuses})) {
        croak "statuses argument is mandatory";
    }
    my $ref = ref($args{statuses});
    if($ref eq "HASH") {
        $args{statuses} = [ $args{statuses} ];
    }elsif($ref ne "ARRAY") {
        croak "statuses argument must be a status or an array-ref of statuses";
    }
    my $statuses = dclone($args{statuses});
    my $final_callback = $args{callback};
    $self->{filter_flow}->execute($statuses, sub {
        my $filter_result = shift;
        my $cur_time;
        foreach my $status (@$filter_result) {
            next if !defined($status) || ref($status) ne 'HASH';
            if(!defined($status->{id})) {
                $status->{id} = sprintf('busybird://%s/%s', $self->name, $self->{id_generator}->create_str);
            }
            if(!defined($status->{created_at})) {
                $cur_time ||= DateTime->now;
                $status->{created_at} = BusyBird::DateTime::Format->format_datetime($cur_time);
            }
        }
        $self->_write_statuses('put_statuses', {
            mode => 'insert', statuses => $filter_result,
            callback => $final_callback
        });
    });
}

sub add {
    my ($self, $statuses, $callback) = @_;
    $self->add_statuses(statuses => $statuses, callback => $callback);
}

sub contains {
    my ($self, %args) = @_;
    $self->_get_from_storage("contains", \%args);
}

sub add_filter {
    my ($self, $filter, $is_async) = @_;
    if(!$is_async) {
        my $sync_filter = $filter;
        $filter = sub {
            my ($statuses, $done) = @_;
            @_ = $sync_filter->($statuses);
            goto $done;
        };
    }
    $self->{filter_flow}->add($filter);
}

sub add_filter_async {
    my ($self, $filter) = @_;
    $self->add_filter($filter, 1);
}

sub set_config {
    shift()->{config}->set_config(@_);
}

sub get_config {
    shift()->{config}->get_config(@_);
}

sub watch_unacked_counts {
    my ($self, %watch_args) = @_;
    my $callback = $watch_args{callback};
    my $assumed = $watch_args{assumed};
    if(!defined($callback) || ref($callback) ne 'CODE') {
        croak "watch_unacked_counts: callback must be a code-ref";
    }
    if(!defined($assumed) || ref($assumed) ne 'HASH') {
        croak "watch_unacked_counts: assumed must be a hash-ref";
    }
    $assumed = +{ %$assumed };
    foreach my $key (keys %$assumed) {
        next if $key eq 'total' || (looks_like_number($key) && int($key) == $key);
        delete $assumed->{$key};
    }
    my $watcher = BusyBird::Watcher::Aggregator->new();
    my $orig_watcher = $self->{selector}->watch(
        unacked_counts => $assumed, watcher_quota => { age => 0 }, sub {
            my ($orig_w, %res) = @_;
            if($res{watcher_quota}) {
                $watcher->cancel();
                $callback->("watcher cancelled because it is too old", $watcher);
                return;
            }
            if($res{unacked_counts}) {
                $callback->(undef, $watcher, $res{unacked_counts});
                return;
            }
            confess("Something terrible happened.");
        }
    );
    $watcher->add($orig_watcher);
    if($watcher->active) {
        my @quota_watchers = $self->{selector}->watchers('watcher_quota');
        foreach my $w (@quota_watchers) {
            my %cond = $w->conditions;
            $cond{watcher_quota}{age}++;
        }
        $self->{selector}->trigger('watcher_quota');
    }
    return $watcher;
}


1;

__END__

=pod

=head1 NAME

BusyBird::Timeline - a timeline object in BusyBird

=head1 SYNOPSIS


    use BusyBird::Timeline;
    use BusyBird::StatusStorage::SQLite;
    
    my $storage = BusyBird::StatusStorage::SQLite->new(
        path => ':memory:'
    );
    my $timeline = BusyBird::Timeline->new(
        name => "sample", storage => $storage
    );

    $timeline->set_config(
        time_zone => "+0900"
    );

    ## Add some statuses
    $timeline->add_statuses(
        statuses => [{text => "foo"}, {text => "bar"}],
        callback => sub {
            my ($error, $num) = @_;
            if($error) {
                warn("error: $error");
                return;
            }
            print "Added $num statuses.\n";
        }
    );

    ## Ack all statuses
    $timeline->ack_statuses(callback => sub {
        my ($error, $num) = @_;
        if($error) {
            warn("error: $error");
            return;
        }
        print "Acked $num statuses.\n";
    });

    ## Change acked statuses into unacked.
    $timeline->get_statuses(
        ack_state => 'acked', count => 10,
        callback => sub {
            my ($error, $statuses) = @_;
            if($error) {
                warn("error: $error");
                return;
            }
            foreach my $s (@$statuses) {
                $s->{busybird}{acked_at} = undef;
            }
            $timeline->put_statuses(
                mode => "update", statuses => $statuses,
                callback => sub {
                    my ($error, $num) = @_;
                    if($error) {
                        warn("error: $error");
                        return;
                    }
                    print "Updated $num statuses.\n";
                }
            );
        }
    );

    ## Delete all statuses
    $timeline->delete_statuses(
        ids => undef, callback => sub {
            my ($error, $num) = @_;
            if($error) {
                warn("error: $error");
                return;
            }
            print "Delete $num statuses.\n";
        }
    );

=head1 DESCRIPTION

L<BusyBird::Timeline> stores and manages a timeline, which is an ordered sequence of statuses.
You can add statuses to a timeline, and get statuses from the timeline.

This module uses L<BusyBird::Log> for logging.

=head2 Filters

You can set status filters to a timeline.
A status filter is a subroutine that is called when new statuses are added to the timeline
via C<add_statuses()> method.

Using status filters, you can modify or even drop the added statuses before they are
actually inserted to the timeline.
Status filters are executed in the same order as they are added.

L<BusyBird> comes with some pre-defined status filters. See L<BusyBird::Filter> for detail.

=head2 Status Storage

A timeline's statuses are actually saved in a L<BusyBird::StatusStorage> object.
When you create a timeline via C<new()> method, you have to specify a L<BusyBird::StatusStorage> object explicitly.

=head2 Callback-Style Methods

Some methods of L<BusyBird::Timeline> are callback-style, that is,
their results are not returned but given to the callback function you specify.

It depends on the underlying L<BusyBird::StatusStorage> object 
whether the callback-style methods are synchronous or asynchronous.
L<BusyBird::StatusStorage::SQLite>, for example, is synchronous.
If the status storage is synchronous, the callback is always called before the method returns.
If the status storage is asynchronous, it is possible for the method to return without calling the callback.
The callback will be called at a certain point later.

To handle callback-style methods, I recommend C<future_of()> function in L<BusyBird::Util>.
C<future_of()> function transforms callback-style methods into Future-style methods.

=head1 CLASS METHODS

=head2 $timeline = BusyBird::Timeline->new(%args)

Creates a new timeline.

You can also create a timeline via L<BusyBird::Main>'s C<timeline()> method.

Fields in C<%args> are as follows.

=over

=item C<name> => STRING (mandatory)

Specifies the name of the timeline.
If it includes Unicode characters, it must be a character string (decoded string), not a binary string (encoded string).

=item C<storage> => STATUS_STORAGE (mandatory)

Specifies a L<BusyBird::StatusStorage> object.
Statuses in C<$timeline> is saved to the C<storage>.

=back


=head1 OBJECT METHODS

=head2 $name = $timeline->name()

Returns the C<$timeline>'s name.

=head2 $timeline->add($statuses, [$callback])

=head2 $timeline->add_statuses(%args)

Adds new statuses to the C<$timeline>.

Note that statuses added by C<add_statuses()> method go through the C<$timeline>'s filters.
It is the filtered statuses that are actually inserted to the storage.

In addition to filtering, if statuses added to the C<$timeline> lack C<id> or C<created_at> field,
it automatically generates and sets these fields.
This auto-generation of IDs and timestamps are done after the filtering.

C<add()> method is a short-hand of C<< add_statuses(statuses => $statuses, callback => $callback) >>.

Fields in C<%args> are as follows.

=over

=item C<statuses> => {STATUS, ARRAYREF_OF_STATUSES} (mandatory)

Specifies a status object or an array-ref of status objects to be added.
See L<BusyBird::Manual::Status> about what status objects look like.

=item C<callback> => CODEREF($error, $added_num) (optional, default: C<undef>)

Specifies a subroutine reference that is called when the operation has completed.

In success, C<callback> is called with two arguments (C<$error> and C<$added_num>).
C<$error> is C<undef>, and C<$added_num> is the number of statuses actually added to the C<$timeline>.

In failure, C<$error> is a truthy value describing the error.

=back



=head2 $timeline->ack_statuses(%args)

Acknowledges statuses in the C<$timeline>, that is, changing 'unacked' statuses into 'acked'.

Acked status is a status whose C<< $status->{busybird}{acked_at} >> field evaluates to true.
Otherwise, the status is unacked.

Fields in C<%args> are as follows.

=over

=item C<ids> => {ID, ARRAYREF_OF_IDS} (optional, default: C<undef>)

Specifies the IDs of the statuses to be acked.

If it is a defined scalar, the status with the specified ID is acked.
If it is an array-ref of IDs, the statuses with those IDs are acked.

If both C<max_id> and C<ids> are omitted or set to C<undef>, all unacked statuses are acked.
If both C<max_id> and C<ids> are specified, both statuses older than or equal to C<max_id>
and statuses specifed by C<ids> are acked.

If Status IDs include Unicode characters, they should be character strings (decoded strings), not binary strings (encoded strings).

=item C<max_id> => ID (optional, default: C<undef>)

Specifies the latest ID of the statuses to be acked.

If specified, unacked statuses with IDs older than or equal to the specified C<max_id> are acked.
If there is no unacked status with ID C<max_id>, no status is acked.

If both C<max_id> and C<ids> are omitted or set to C<undef>, all unacked statuses are acked.
If both C<max_id> and C<ids> are specified, both statuses older than or equal to C<max_id>
and statuses specifed by C<ids> are acked.

If the Status ID includes Unicode characters, it should be a character string (decoded string), not a binary string (encoded string).


=item C<callback> => CODEREF($error, $acked_num) (optional, default: C<undef>)

Specifies a subroutine reference that is called when the operation completes.

In success, the C<callback> is called with two arguments (C<$error> and C<$acked_num>).
C<$error> is C<undef>, and C<$acked_num> is the number of acked statuses.

In failure, C<$error> is a truthy value describing the error.

=back



=head2 $timeline->get_statuses(%args)

Fetches statuses from the C<$timeline>.
The fetched statuses are given to the C<callback> function.

Fields in C<%args> are as follows.

=over

=item C<callback> => CODEREF($error, $arrayref_of_statuses) (mandatory)

Specifies a subroutine reference that is called upon completion of
fetching statuses.

In success, C<callback> is called with two arguments
(C<$error> and C<$arrayref_of_statuses>).
C<$error> is C<undef>, and C<$arrayref_of_statuses> is an array-ref of fetched status
objects.  The array-ref can be empty.

In failure, C<$error> is a truthy value describing the error.


=item C<ack_state> => {'any', 'unacked', 'acked'} (optional, default: 'any')

Specifies the acked/unacked state of the statuses to be fetched.

By setting it to C<'unacked'>, this method returns only
unacked statuses from the storage. By setting it to
C<'acked'>, it returns only acked statuses.  By setting it to
C<'any'>, it returns both acked and unacked statuses.


=item C<max_id> => STATUS_ID (optional, default: C<undef>)

Specifies the latest ID of the statuses to be fetched.  It fetches
statuses with IDs older than or equal to the specified C<max_id>.

If there is no such status that has the ID equal to C<max_id> in
specified C<ack_state>, the result is an empty array-ref.

If this option is omitted or set to C<undef>, statuses starting from
the latest status are fetched.

If the Status ID includes Unicode characters, it should be a character string (decoded string), not a binary string (encoded string).

=item C<count> => {'all', NUMBER} (optional)

Specifies the maximum number of statuses to be fetched.

If C<'all'> is specified, all statuses starting from C<max_id> in
specified C<ack_state> are fetched.

The default value of this option is up to implementation of the status storage
the C<$timeline> uses.

=back



=head2 $timeline->put_statuses(%args)

Inserts statuses to the C<$timeline> or updates statuses in the C<$timeline>.

Usually you should use C<add_statuses()> method to add new statuses to the C<$timeline>,
because statuses inserted by C<put_statuses()> bypasses the C<$timeline>'s filters.

Fields in C<%args> are as follows.

=over

=item C<mode> => {'insert', 'update', 'upsert'} (mandatory)

Specifies the mode of operation.

If C<mode> is C<"insert">, the statuses are inserted (added) to the
C<$timeline>.  If C<mode> is C<"update">, the statuses in the
C<$timeline> are updated to the given statuses.  If C<mode> is
C<"upsert">, statuses already in the C<$timeline> are updated while
statuses not in the C<$timeline> are inserted.

The statuses are identified by C<< $status->{id} >> field.  The
C<< $status->{id} >> field must be unique in the C<$timeline>.
So if C<mode> is C<"insert">, statuses whose ID is already in the C<$timeline>
are ignored and not inserted.

If C<< $status->{id} >> includes Unicode characters, it should be a character string (decoded string), not a binary string (encoded string).


=item C<statuses> => {STATUS, ARRAYREF_OF_STATUSES} (mandatory)

The statuses to be saved in the C<$timeline>.  It is either a status object
or an array-ref of status objects.

See L<BusyBird::Manual::Status> for specification of status objects.


=item C<callback> => CODEREF($error, $put_num) (optional, default: C<undef>)

Specifies a subroutine reference that is called when the operation completes.

In success, C<callback> is called with two arguments (C<$error> and C<$put_num>).
C<$error> is C<undef>, and C<$put_num> is the number of statuses inserted or updated.

In failure, C<$error> is a truthy value describing the error.


=back


=head2 $timeline->delete_statuses(%args)

Deletes statuses from the C<$timeline>.

Fields in C<%args> are as follows.

=over

=item C<ids> => {C<undef>, ID, ARRAYREF_OF_IDS} (mandatory)

Specifies the IDs (value of C<< $status->{id} >> field) of the
statuses to be deleted.

If it is a defined scalar, the status with the specified ID is
deleted.  If it is an array-ref of IDs, the statuses with those IDs
are deleted.  If it is explicitly set to C<undef>, all statuses in the C<$timeline> are deleted.

If Status IDs include Unicode characters, they should be character strings (decoded strings), not binary strings (encoded strings).


=item C<callback> => CODEREF($error, $deleted_num) (optional, default: C<undef>)

Specifies a subroutine reference that is called when the operation completes.

In success, the C<callback> is called with two arguments (C<$error> and C<$deleted_num>).
C<$error> is C<undef>, and C<$deleted_num> is the number of deleted statuses.

In failure, C<$error> is a truthy value describing the error.


=back


=head2 $timeline->get_unacked_counts(%args)

Fetches numbers of unacked statuses in the C<$timeline>.

Fields in C<%args> are as follows.

=over

=item C<callback> => CODEREF($error, $unacked_counts) (mandatory)

Specifies a subroutine reference that is called when the operation completes.

In success, the C<callback> is called with two arguments (C<$error> and C<$unacked_counts>).
C<$error> is C<undef>, and C<$unacked_counts> is a hash-ref describing numbers of unacked statuses in each level.

In failure, C<$error> is a truthy value describing the error.

=back

Fields in C<%$unacked_counts> are as follows.

=over

=item LEVEL => COUNT_OF_UNACKED_STATUSES_IN_THE_LEVEL

LEVEL is an integer key that represents the status level.
The value is the number of unacked statuses in the level.

A status's level is the C<< $status->{busybird}{level} >> field.
See L<BusyBird::Manual::Status> for detail.

LEVEL key-value pair is present for each level in which
there are some unacked statuses.


=item C<total> => COUNT_OF_ALL_UNACKED_STATUSES

The key C<"total"> represents the total number of unacked statuses
in the C<$timeline>.

=back

For example, C<$unacked_counts> is structured like:

    $unacked_counts = {
        total => 3,
        0     => 1,
        1     => 2,
    };

This means there are 3 unacked statuses in total, one of which is in level 0,
and the rest is in level 2.


=head2 $timeline->contains(%args)

Checks if the given statuses (or IDs) are contained in the C<$timeline>.

Fields in C<%args> are as follows.

=over

=item C<query> => {STATUS, ID, ARRAYREF_OF_STATUSES_OR_IDS} (mandatory)

Specifies the statuses or IDs to be checked.

If it is a scalar, that value is treated as a status ID.
If it is a hash-ref, that object is treated as a status object.
If it is an array-ref,
elements in the array-ref are treated as status objects or IDs.
Status objects and IDs can be mixed in a single array-ref.

If some statuses in C<query> don't have their C<id> field, those statuses are always treated as "not contained" in the C<$timeline>.

If Status IDs include Unicode characters, they should be character strings (decoded strings), not binary strings (encoded strings).


=item C<callback> => CODEREF($error, $contained, $not_contained) (mandatory)

Specifies a subroutine reference that is called when the check has completed.

In success, C<callback> is called with three arguments (C<$error>, C<$contained>, C<$not_contained>).
C<$error> is C<undef>.
C<$contained> is an array-ref of given statuses or IDs that are contained in the C<$timeline>.
C<$not_contained> is an array-ref of given statuses or IDs that are NOT contained in the C<$timeline>.

In failure, C<$error> is a truthy value describing the error.

=back


=head2 $timeline->add_filter($filter, [$is_async])

Add a status filter to the C<$timeline>.

C<$filter> is a subroutine reference that is called upon added statuses.
C<$is_async> specifies whether the C<$filter> is synchronous or asynchronous.

L<BusyBird::Filter> may help you create common status filters.


B<< Synchronous Filter >>

If C<$is_async> is false, C<$filter> is a synchronous filter. It is called like

    $result_arrayref = $filter->($arrayref_of_statuses);

where C<$arrayref_of_statuses> is an array-ref of statuses that is injected to the filter.

C<$filter> must return an array-ref of statuses (C<$result_arrayref>), which is going to be passed to the next filter
(or the status storage if there is no next filter).
C<$result_arrayref> may be either C<$arrayref_of_statuses> or a new array-ref.
If C<$filter> returns anything other than an array-ref,
a warning is logged and C<$arrayref_of_statuses> is passed to the next.

B<< Asynchronous Filter >>

If C<$is_async> is true, C<$filter> is a asynchronous filter. It is called like

    $filter->($arrayref_of_statuses, $done);

where C<$done> is a subroutine reference that C<$filter> is supposed to call when it completes its task.
C<$filter> must pass the result array-ref of statuses to the C<$done> callback.

    $done->($result_arrayref)

B<< Examples >>

    ## Synchronous filter
    $timeline->add_filter(sub {
        my ($statuses) = @_;
        return [ grep { some_predicate($_) } @$statuses ];
    });
    
    ## Asynchronous filter
    $timeline->add_filter(sub {
        my ($statuses, $done) = @_;
        some_async_processing(
            statuses => $statuses,
            callback => sub {
                my ($results) = @_;
                $done->($results);
            }
        );
    }, 1);

=head2 $timeline->add_filter_async($filter)

Add an asynchronous status filter. This is equivalent to C<< $timeline->add_filter($filter, 1) >>.


=head2 $timeline->set_config($key1 => $value1, $key2 => $value2, ...)

Sets config parameters to the C<$timeline>.

C<$key1>, C<$key2>, ... are the keys for the config parameters, and
C<$value1>, C<$value2>, ... are the values for them.

See L<BusyBird::Manual::Config> for the list of config parameters.

=head2 $value = $timeline->get_config($key)

Returns the value of config parameter whose key is C<$key>.

If there is no config parameter associated with C<$key>, it returns C<undef>.



=head2 $watcher = $timeline->watch_unacked_counts(%args)

Watch updates of unacked counts in the C<$timeline>.

Fields in C<%args> are as follows.

=over

=item C<assumed> => HASHREF (mandatory)

Specifies the unacked counts that the caller assumes.

=item C<callback> => CODEREF ($error, $w, $unacked_counts) (mandatory)

Specifies the callback function that is called when the unacked counts given in C<assumed> argument
are different from the current unacked counts.

=back

In C<assumed> argument, caller must describe numbers of unacked statuses (i.e. unacked counts) for each status level and/or in total.
If the assumed unacked counts is different from the current unacked counts in C<$timeline>,
C<callback> subroutine reference is called with the current unacked counts (C<$unacked_counts>).
If the assumed unacked counts is the same as the current unacked counts, execution of C<callback> is delayed
until there is some difference between them.

Format of C<assumed> argument and C<%$unacked_counts> is the same as C<%$unacked_counts> returned by C<get_unacked_counts()> method.
See also the following example.

In success, the C<callback> is called with three arguments (C<$error>, C<$w>, C<$unacked_counts>).
C<$error> is C<undef>.
C<$w> is an L<BusyBird::Watcher> object representing this watch.
C<$unacked_counts> is a hash-ref describing the current unacked counts of the C<$timeline>.

In failure, C<$error> is a truthy value describing the error. C<$w> is an inactive L<BusyBird::Watcher>.

For example, 

    use Data::Dumper;
    
    my $watcher = $timeline->watch_unacked_counts(
        assumed => { total => 4, 1 => 2 },
        callback => sub {
            my ($error, $w, $unacked_counts) = @_;
            $w->cancel();
            print Dumper $unacked_counts;
        }
    );

In the above example, the caller assumes that the C<$timeline> has 4 unacked statuses in total,
and 2 of them are in level 1.

The callback is called when the assumption breaks. The C<$unacked_counts> describes the current unacked counts.

    $unacked_counts = {
        total => 4,
        -1 => 1,
        0 => 2,
        1 => 1,
    };

In the above, the counts in 'total' is the same as the assumption (4),
but the unacked count for level 1 is 1 instead of 2.
So the callback is executed.


The return value of this method (C<$watcher>) is an L<BusyBird::Watcher> object.
It is the same instance as C<$w> given in the C<callback> function.
You can call C<< $watcher->cancel() >> or C<< $w->cancel() >> to cancel the watcher, like we did in the above example.
Otherwise, the C<callback> function is called repeatedly.

Caller does not have to specify the complete set of unacked counts in C<assumed> argument.
Updates are checked only for levels (or 'total') that are explicitly specified in C<assumed>.
Therefore, if some updates happen in levels that are not in C<assumed>, C<callback> is never called.

If C<assumed> is an empty hash-ref, C<callback> is always called immediately.

Never apply C<future_of()> function from L<BusyBird::Util> to this method.
This is because this method can execute the callback more than once.


=head1 AUTHOR

Toshio Ito C<< <toshioito [at] cpan.org> >>

=cut
