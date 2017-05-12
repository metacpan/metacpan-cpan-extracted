package BusyBird::StatusStorage::Memory;
use v5.8.0;
use strict;
use warnings;
use parent ('BusyBird::StatusStorage');
use BusyBird::Util qw(set_param sort_statuses);
use BusyBird::Log qw(bblog);
use BusyBird::StatusStorage::Common qw(contains ack_statuses get_unacked_counts);
use BusyBird::DateTime::Format;
use Storable qw(dclone);
use Carp;
use List::Util qw(min);
use JSON;
use Try::Tiny;

sub new {
    my ($class, %options) = @_;
    my $self = bless {
        timelines => {}, ## timelines should always be sorted.
    }, $class;
    $self->set_param(\%options, 'max_status_num', 2000);
    if($self->{max_status_num} <= 0) {
        croak "max_status_num option must be bigger than 0.";
    }
    return $self;
}

sub _log {
    my ($self, $level, $msg) = @_;
    bblog($level, $msg);
}

sub _index {
    my ($self, $timeline, $id) = @_;
    return -1 if not defined($self->{timelines}{$timeline});
    my $tl = $self->{timelines}{$timeline};
    my @ret = grep { $tl->[$_]{id} eq $id } 0..$#$tl;
    confess "multiple IDs in timeline $timeline." if int(@ret) >= 2;
    return int(@ret) == 0 ? -1 : $ret[0];
}

sub _acked {
    my ($self, $status) = @_;
    no autovivification;
    return $status->{busybird}{acked_at};
}

sub save {
    my ($self, $filepath) = @_;
    if(not defined($filepath)) {
        croak '$filepath is not specified.';
    }
    my $file;
    if(!open $file, ">", $filepath) {
        $self->_log("error", "Cannot open $filepath to write.");
        return 0;
    }
    my $success;
    try {
        print $file encode_json($self->{timelines});
        $success = 1;
    }catch {
        my $e = shift;
        $self->_log("error", "Error while saving: $e");
        $success = 0;
    };
    close $file;
    return $success;
}

sub load {
    my ($self, $filepath) = @_;
    if(not defined($filepath)) {
        croak '$filepath is not specified.';
    }
    my $file;
    if(!open $file, "<", $filepath) {
        $self->_log("notice", "Cannot open $filepath to read");
        return 0;
    }
    my $success;
    try {
        my $text = do { local $/; <$file> };
        $self->{timelines} = decode_json($text);
        $success = 1;
    }catch {
        my $e = shift;
        $self->_log("error", "Error while loading: $e");
        $success = 0;
    };
    close $file;
    return $success;
}

sub _is_timestamp_format_ok {
    my ($timestamp_str) = @_;
    return 1 if not defined $timestamp_str;
    
    ## It is very inefficient to parse $timestamp_str to check its
    ## format, because creating a DateTime object takes long time. We
    ## do it because BB::SS::Memory is just a reference
    ## implementation.
    return defined(BusyBird::DateTime::Format->parse_datetime($timestamp_str));
}

sub put_statuses {
    my ($self, %args) = @_;
    croak 'timeline arg is mandatory' if not defined $args{timeline};
    my $timeline = $args{timeline};
    if(!defined($args{mode}) ||
           ($args{mode} ne 'insert'
                && $args{mode} ne 'update' && $args{mode} ne 'upsert')) {
        croak 'mode arg must be insert/update/upsert';
    }
    my $mode = $args{mode};
    my $statuses;
    if(!defined($args{statuses})) {
        croak 'statuses arg is mandatory';
    }elsif(ref($args{statuses}) eq 'HASH') {
        $statuses = [ $args{statuses} ];
    }elsif(ref($args{statuses}) eq 'ARRAY') {
        $statuses = $args{statuses};
    }else {
        croak 'statuses arg must be STATUS/ARRAYREF_OF_STATUSES';
    }
    foreach my $s (@$statuses) {
        no autovivification;
        croak "{id} field is mandatory in statuses" if not defined $s->{id};
        croak "{busybird} field must be a hash-ref if present" if defined($s->{busybird}) && ref($s->{busybird}) ne "HASH";
        croak "{created_at} field must be parsable by BusyBird::DateTime::Format" if !_is_timestamp_format_ok($s->{created_at});
        my $acked_at = $s->{busybird}{acked_at}; ## avoid autovivification
        croak "{busybird}{acked_at} field must be parsable by BusyBird::DateTime::Format" if !_is_timestamp_format_ok($acked_at);
    }
    my $put_count = 0;
    foreach my $status_index (reverse 0 .. $#$statuses) {
        my $s = $statuses->[$status_index];
        my $tl_index = $self->_index($timeline, $s->{id});
        my $existent = ($tl_index >= 0);
        next if ($mode eq 'insert' && $existent) || ($mode eq 'update' && !$existent);
        my $is_insert = ($mode eq 'insert');
        if($mode eq 'upsert') {
            $is_insert = (!$existent);
        }
        if($is_insert) {
            unshift(@{$self->{timelines}{$timeline}}, dclone($s));
        }else {
            ## update
            $self->{timelines}{$timeline}[$tl_index] = dclone($s);
        }
        $put_count++;
    }
    if($put_count > 0) {
        $self->{timelines}{$timeline} = sort_statuses($self->{timelines}{$timeline});
        if(int(@{$self->{timelines}{$timeline}}) > $self->{max_status_num}) {
            splice(@{$self->{timelines}{$timeline}}, -(int(@{$self->{timelines}{$timeline}}) - $self->{max_status_num}));
        }
    }
    if($args{callback}) {
        @_ = (undef, $put_count);
        goto $args{callback};
    }
}

sub delete_statuses {
    my ($self, %args) = @_;
    croak 'timeline arg is mandatory' if not defined $args{timeline};
    croak 'ids arg is mandatory' if not exists $args{ids};
    my $timeline = $args{timeline};
    my $ids = $args{ids};
    if(defined($ids)) {
        if(!ref($ids)) {
            $ids = [$ids];
        }elsif(ref($ids) eq 'ARRAY') {
            croak "ids arg array must not contain undef" if grep { !defined($_) } @$ids;
        }else {
            croak "ids must be undef/ID/ARRAYREF_OF_IDS";
        }
    }
    if(!$self->{timelines}{$timeline}) {
        if($args{callback}) {
            @_ = (undef, 0);
            goto $args{callback};
        }
        return;
    }
    my $delete_num = 0;
    if(defined($ids)) {
        foreach my $id (@$ids) {
            my $tl_index = $self->_index($timeline, $id);
            last if $tl_index < 0;
            splice(@{$self->{timelines}{$timeline}}, $tl_index, 1);
            $delete_num++;
        }
    }else {
        if(defined($self->{timelines}{$timeline})) {
            $delete_num = @{$self->{timelines}{$timeline}};
            delete $self->{timelines}{$timeline};
        }
    }
    if($args{callback}) {
        @_ = (undef, $delete_num);
        goto $args{callback};
    }
}

sub get_statuses {
    my ($self, %args) = @_;
    croak 'timeline arg is mandatory' if not defined $args{timeline};
    croak 'callback arg is mandatory' if not defined $args{callback};
    my $timeline = $args{timeline};
    if(!$self->{timelines}{$timeline}) {
        @_ = (undef, []);
        goto $args{callback};
    }
    my $ack_state = $args{ack_state} || 'any';
    my $max_id = $args{max_id};
    my $count = defined($args{count}) ? $args{count} : 20;
    my $ack_test = $ack_state eq 'unacked' ? sub {
        !$self->_acked(shift);
    } : $ack_state eq 'acked' ? sub {
        $self->_acked(shift);
    } : sub { 1 };
    my $start_index;
    if(defined($max_id)) {
        my $tl_index = $self->_index($timeline, $max_id);
        if($tl_index < 0) {
            @_ = (undef, []);
            goto $args{callback};
        }
        my $s = $self->{timelines}{$timeline}[$tl_index];
        if(!$ack_test->($s)) {
            @_ = (undef, []);
            goto $args{callback};
        }
        $start_index = $tl_index;
    }
    my @indice = grep {
        if(!$ack_test->($self->{timelines}{$timeline}[$_])) {
            0;
        }elsif(defined($start_index) && $_ < $start_index) {
            0;
        }else {
            1;
        }
    } 0 .. $#{$self->{timelines}{$timeline}};
    $count = int(@indice) if $count eq 'all';
    $count = min($count, int(@indice));
    my $result_statuses = $count <= 0 ? [] : [ map {
        dclone($self->{timelines}{$timeline}[$_])
    } @indice[0 .. ($count-1)] ];

    @_ = (undef, $result_statuses);
    goto $args{callback};
}

1;

__END__

=pod

=head1 NAME

BusyBird::StatusStorage::Memory - Simple status storage in the process memory

=head1 SYNOPSIS

    use BusyBird::StatusStorage::Memory;
    
    ## The statuses are stored in the process memory.
    my $storage = BusyBird::StatusStorage::Memory->new();

    ## Load statuses from a file
    $storage->load("my_statuses.json");
    
    ## Save the content of the storage into a file
    $storage->save("my_statuses.json");


=head1 DESCRIPTION

This module is an implementation of L<BusyBird::StatusStorage>.

This storage stores all statuses in the process memory.
The stored statuses can be saved to a file in JSON format.
The saved statuses can be loaded from the file.

This storage is rather for testing purposes.
If you want a light-weight in-memory status storage,
I recommend L<BusyBird::StatusStorage::SQLite>.

This storage is synchronous, i.e., all operations block the thread
and the callback is called before the method returns.

This module uses L<BusyBird::Log> for logging.

=head1 CAVEATS

=over

=item *

Because this storage stores statuses in the process memory,
forked servers cannot share the storage.

=item *

Because this storage stores statuses in the process memory,
the stored statuses are lost when the process is terminated.

=back

=head1 CLASS METHODS

=head2 $storage = BusyBird::StatusStorage::Memory->new(%options)

Creates the storage object.

You can specify the folowing options in C<%options>.

=over

=item C<max_status_num> => MAX_STATUS_NUM (optional, default: 2000)

Specifies the maximum number of statuses the storage can store per timeline.
If more statuses are added to a full timeline, the oldest statuses in the timeline are removed automatically.

=back

=head1 OBJECTS METHODS

In addition to the following methods,
all methods described in L<BusyBird::StatusStorage> are supported, too.


=head2 $is_success = $storage->save($filepath)

Saves the current content of the storage to the file named C<$filepath>.

In success, it returns true. In failure, it returns false and the error will be logged.


=head2 $is_success = $storage->load($filepath)

Loads statuses from the file named C<$filepath>.

In success, it returns true. In failure, it returns false and the error will be logged.


=head1 AUTHOR

Toshio Ito C<< <toshioito [at] cpan.org> >>

=cut
