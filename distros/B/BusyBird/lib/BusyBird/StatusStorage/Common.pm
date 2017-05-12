package BusyBird::StatusStorage::Common;
use v5.8.0;
use strict;
use warnings;
use Carp;
use Exporter 5.57 qw(import);
use BusyBird::Util qw(future_of);
use BusyBird::DateTime::Format;
use DateTime;
use Try::Tiny;
use Future::Q;

our @EXPORT_OK = qw(contains ack_statuses get_unacked_counts);

sub ack_statuses {
    my ($self, %args) = @_;
    croak 'timeline arg is mandatory' if not defined $args{timeline};
    my $ids;
    if(defined($args{ids})) {
        if(!ref($args{ids})) {
            $ids = [$args{ids}];
        }elsif(ref($args{ids}) eq 'ARRAY') {
            $ids = $args{ids};
            croak "ids arg array must not contain undef" if grep { !defined($_) } @$ids;
        }else {
            croak "ids arg must be either undef, status ID or array-ref of IDs";
        }
    }
    my $max_id = $args{max_id};
    my $timeline = $args{timeline};
    my $callback = $args{callback} || sub {};
    my $ack_str = BusyBird::DateTime::Format->format_datetime(
        DateTime->now(time_zone => 'UTC')
    );
    my @subfutures = (_get_unacked_statuses_by_ids_future($self, $timeline, $ids));
    if(!defined($ids) || defined($max_id)) {
        push @subfutures, future_of(
            $self, 'get_statuses',
            timeline => $timeline,
            max_id => $max_id, count => 'all',
            ack_state => 'unacked'
        );
    }
    Future::Q->needs_all(@subfutures)->then(sub {
        my @statuses_list = @_;
        my @target_statuses = _uniq_statuses(map { @$_ } @statuses_list);
        if(!@target_statuses) {
            return 0;
        }
        $_->{busybird}{acked_at} = $ack_str foreach @target_statuses;
        return future_of(
            $self, 'put_statuses',
            timeline => $timeline, mode => 'update',
            statuses => \@target_statuses,
        );
    })->then(sub {
        ## invocations of $callback should be at the same level of
        ## then() chain, because $callback might throw exception and
        ## we should not catch that exception.
        
        my ($changed) = @_;
        @_ = (undef, $changed);
        goto $callback;
    }, sub {
        my ($error) = @_;
        @_ = ($error);
        goto $callback;
    });
}

sub _get_unacked_statuses_by_ids_future {
    my ($self, $timeline, $ids) = @_;
    if(!defined($ids) || !@$ids) {
        return Future::Q->new->fulfill([]);
    }
    my @status_futures = map {
        my $id = $_;
        future_of(
            $self, 'get_statuses', 
            timeline => $timeline, max_id => $id, ack_state => 'unacked', count => 1
        );
    } @$ids;
    return Future::Q->needs_all(@status_futures)->then(sub {
        my @statuses_list = @_;
        return [ map { defined($_->[0]) ? ($_->[0]) : () } @statuses_list ];
    });
}

sub _uniq_statuses {
    my (@statuses) = @_;
    my %id_to_s = map { $_->{id} => $_ } @statuses;
    return values %id_to_s;
}

sub contains {
    my ($self, %args) = @_;
    my $timeline = $args{timeline};
    my $query = $args{query};
    my $callback = $args{callback};
    croak 'timeline argument is mandatory' if not defined($timeline);
    croak 'query argument is mandatory' if not defined($query);
    croak 'callback argument is mandatory' if not defined($callback);
    if(ref($query) eq 'ARRAY') {
        ;
    }elsif(ref($query) eq 'HASH' || !ref($query)) {
        $query = [$query];
    }else {
        croak 'query argument must be either STATUS, ID or ARRAYREF_OF_STATUSES_OR_IDS';
    }
    if(grep { !defined($_) } @$query) {
        croak 'query argument must not contain undef';
    }
    if(!@$query) {
        @_ = (undef, [], []);
        goto $callback;
    }
    my @subfutures = map {
        my $query_elem = $_;
        my $id = ref($query_elem) ? $query_elem->{id} : $query_elem;
        defined($id) ? future_of($self, "get_statuses", timeline => $timeline, count => 1, max_id => $id)
                     : Future::Q->new->fulfill([]); ## ID-less status is always 'not contained'.
    } @$query;
    Future::Q->needs_all(@subfutures)->then(sub {
        my (@statuses_list) = @_;
        if(@statuses_list != @$query) {
            confess("fatal error: number of statuses_list does not match the number of query");
        }
        my @contained = ();
        my @not_contained = ();
        foreach my $i (0 .. $#statuses_list) {
            if(@{$statuses_list[$i]}) {
                push @contained, $query->[$i];
            }else {
                push @not_contained, $query->[$i];
            }
        }
        return (\@contained, \@not_contained);
    })->then(sub {
        my ($contained, $not_contained) = @_;
        @_ = (undef, $contained, $not_contained);
        goto $callback;
    }, sub {
        my ($error) = @_;
        @_ = ($error);
        goto $callback;
    });
}

sub get_unacked_counts {
    my ($self, %args) = @_;
    croak 'timeline arg is mandatory' if not defined $args{timeline};
    croak 'callback arg is mandatory' if not defined $args{callback};
    my $timeline = $args{timeline};
    my $callback = $args{callback};
    
    ## get_statuses() called plainly. its exception propagates to the caller.
    $self->get_statuses(
        timeline => $timeline, ack_state => "unacked", count => "all",
        callback => sub {
            my ($error, $statuses) = @_;
            if(defined($error)) {
                @_ = ("get error: $error");
                goto $callback;
            }
            my %count = (total => int(@$statuses));
            foreach my $status (@$statuses) {
                my $level = do {
                    no autovivification;
                    $status->{busybird}{level} || 0;
                };
                $count{$level}++;
            }
            @_ = (undef, \%count);
            goto $callback;
        }
    );
}


1;
__END__

=pod

=head1 NAME

BusyBird::StatusStorage::Common - common partial implementation of StatusStorage

=head1 SYNOPSIS

    package My::StatusStorage;
    use parent "BusyBird::StatusStorage";
    use BusyBird::StatusStorage::Common qw(ack_statuses get_unacked_counts contains);
    
    sub new { ... }
    sub get_statuses { ... }
    sub put_statuses { ... }
    sub delete_statuses { ... }
    
    1;

=head1 DESCRIPTION

This module implements and exports some methods required by L<BusyBird::StatusStorage> interface.

To import methods from L<BusyBird::StatusStorage::Common>, the importing class must implement C<get_statuses()> and C<put_statuses>.
This is because exported methods in L<BusyBird::StatusStorage::Common> use those methods.

=head1 EXPORTABLE FUNCTIONS

The following methods are exported only by request.

=head2 ack_statuses

=head2 get_unacked_counts

=head2 contains

See L<BusyBird::StatusStorage>.


=head1 AUTHOR

Toshio Ito C<< <toshioito [at] cpan.org> >>

=cut
