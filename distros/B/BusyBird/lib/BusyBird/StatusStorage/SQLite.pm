package BusyBird::StatusStorage::SQLite;
use v5.8.0;
use strict;
use warnings;
use parent ("BusyBird::StatusStorage");
use DBI;
use Carp;
use Try::Tiny;
use SQL::Maker 1.19;
use SQL::QueryMaker 0.03 qw(sql_and sql_eq sql_ne sql_or sql_lt sql_le sql_raw);
use BusyBird::DateTime::Format;
use BusyBird::Util qw(set_param);
use JSON;
use Scalar::Util qw(looks_like_number);
use DateTime::Format::Strptime;
use DateTime;
no autovivification;

my @STATUSES_ORDER_BY = ('utc_acked_at DESC', 'utc_created_at DESC', 'status_id DESC');
my $DELETE_COUNT_ID = 0;

my $UNDEF_TIMESTAMP = '9999-99-99T99:99:99';

{
    my $TIMESTAMP_FORMAT_STR = '%Y-%m-%dT%H:%M:%S';
    my $TIMESTAMP_FORMAT = DateTime::Format::Strptime->new(
        pattern => $TIMESTAMP_FORMAT_STR,
        time_zone => 'UTC',
        on_error => 'croak',
    );

    sub _format_datetime {
        my ($dt) = @_;
        return $dt->strftime($TIMESTAMP_FORMAT_STR);
    }

    sub _parse_datetime {
        my ($dt_str) = @_;
        return $TIMESTAMP_FORMAT->parse_datetime($dt_str);
    }
}


sub new {
    my ($class, %args) = @_;
    my $self = bless {
        maker => SQL::Maker->new(driver => 'SQLite', strict => 1),
        in_memory_dbh => undef,
    }, $class;
    $self->set_param(\%args, "path", undef, 1);
    $self->set_param(\%args, "max_status_num", 2000);
    $self->set_param(\%args, "hard_max_status_num", int($self->{max_status_num} * 1.2));
    $self->set_param(\%args, "vacuum_on_delete", int($self->{max_status_num} * 2.0));
    croak "max_status_num must be a number" if !looks_like_number($self->{max_status_num});
    croak "hard_max_status_num must be a number" if !looks_like_number($self->{hard_max_status_num});
    $self->{max_status_num} = int($self->{max_status_num});
    $self->{hard_max_status_num} = int($self->{hard_max_status_num});
    croak "hard_max_status_num must be >= max_status_num" if !($self->{hard_max_status_num} >= $self->{max_status_num});
    $self->_create_tables();
    return $self;
}

sub _create_new_dbh {
    my ($self, @connect_params) = @_;
    my $dbh = DBI->connect(@connect_params);
    $dbh->do(q{PRAGMA foreign_keys = ON});
    return $dbh;
}

sub _get_my_dbh {
    my ($self) = @_;
    my @connect_params = ("dbi:SQLite:dbname=$self->{path}", "", "", {
        RaiseError => 1, PrintError => 0, AutoCommit => 1, sqlite_unicode => 1,
    });
    if($self->{path} eq ':memory:') {
        $self->{in_memory_dbh} = $self->_create_new_dbh(@connect_params) if !$self->{in_memory_dbh};
        return $self->{in_memory_dbh};
    }
    return $self->_create_new_dbh(@connect_params);
}

sub _create_tables {
    my ($self) = @_;
    my $dbh = $self->_get_my_dbh();
    $dbh->do(<<EOD);
CREATE TABLE IF NOT EXISTS timelines (
  timeline_id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  name TEXT UNIQUE NOT NULL
)
EOD
    $dbh->do(<<EOD);
CREATE TABLE IF NOT EXISTS statuses (
  timeline_id INTEGER NOT NULL
              REFERENCES timelines(timeline_id) ON DELETE CASCADE ON UPDATE CASCADE,
  status_id TEXT NOT NULL,
  utc_acked_at TEXT NOT NULL,
  utc_created_at TEXT NOT NULL,
  timezone_acked_at TEXT NOT NULL,
  timezone_created_at TEXT NOT NULL,
  level INTEGER NOT NULL,
  content TEXT NOT NULL,

  PRIMARY KEY (timeline_id, status_id)
)
EOD
    $dbh->do(<<EOD);
CREATE TABLE IF NOT EXISTS delete_counts (
  delete_count_id INTEGER PRIMARY KEY NOT NULL,
  delete_count INTEGER NOT NULL
)
EOD
    my ($sql, @bind) = $self->{maker}->insert('delete_counts', [
        delete_count_id => $DELETE_COUNT_ID, delete_count => 0
    ], {prefix => 'INSERT OR IGNORE INTO'});
    $dbh->do($sql, undef, @bind);
}

sub _record_hash_to_array {
    my ($record) = @_;
    return [ map { $_, $record->{$_} } sort { $a cmp $b } keys %$record ];
}

sub _put_update {
    my ($self, $dbh, $record, $prev_sth) = @_;
    my $sth = $prev_sth;
    my ($sql, @bind) = $self->{maker}->update('statuses', _record_hash_to_array($record), sql_and([
        sql_eq('timeline_id' => $record->{timeline_id}), sql_eq(status_id => $record->{status_id})
    ]));
    if(!$sth) {
        ## Or, should we check $sql is not changed...?
        $sth = $dbh->prepare($sql);
    }
    return ($sth->execute(@bind), $sth);
}

sub _put_insert {
    my ($self, $dbh, $record, $prev_sth) = @_;
    my $sth = $prev_sth;
    my ($sql, @bind) = $self->{maker}->insert('statuses', _record_hash_to_array($record), {
        prefix => 'INSERT OR IGNORE INTO'
    });
    if(!$sth) {
        $sth = $dbh->prepare($sql);
    }
    return ($sth->execute(@bind), $sth);
}

sub _put_upsert {
    my ($self, $dbh, $record) = @_;
    my ($count) = $self->_put_update($dbh, $record);
    if($count <= 0) {
        ($count) = $self->_put_insert($dbh, $record);
    }
    return ($count, undef);
}

sub put_statuses {
    my ($self, %args) = @_;
    my $timeline = $args{timeline};
    croak "timeline parameter is mandatory" if not defined $timeline;
    my $mode = $args{mode};
    croak "mode parameter is mandatory" if not defined $mode;
    if($mode ne 'insert' && $mode ne 'update' && $mode ne 'upsert') {
        croak "mode must be either insert, update or upsert";
    }
    my $statuses = $args{statuses};
    croak "statuses parameter is mandatory" if not defined $statuses;
    if(ref($statuses) ne 'HASH' && ref($statuses) ne 'ARRAY') {
        croak "statuses parameter must be either a status object or an array-ref of statuses";
    }
    if(ref($statuses) eq 'HASH') {
        $statuses = [$statuses];
    }
    foreach my $status (@$statuses) {
        croak "status object must be a hash-ref" if !defined($status) || !ref($status) || ref($status) ne 'HASH';
        croak "status ID is missing" if not defined $status->{id};
    }
    my $callback = $args{callback} || sub {};
    my $dbh;
    my @results = try {
        return (undef, 0) if @$statuses == 0;
        $dbh = $self->_get_my_dbh();
        $dbh->begin_work();
        my $timeline_id = $self->_get_timeline_id($dbh, $timeline) || $self->_create_timeline($dbh, $timeline);
        if(!defined($timeline_id)) {
            die "Internal error: could not create a timeline '$timeline' somehow.";
        }
        my $sth;
        my $total_count = 0;
        my $put_method = "_put_$mode";
        foreach my $status (@$statuses) {
            my $record = _to_status_record($timeline_id, $status);
            my $count;
            ($count, $sth) = $self->$put_method($dbh, $record, $sth);
            if($count > 0) {
                $total_count += $count;
            }
        }
        my $exceeding_delete_count = 0;
        if($mode ne "update" && $total_count > 0) {
            $exceeding_delete_count = $self->_delete_exceeding_statuses($dbh, $timeline_id);
        }
        $dbh->commit();
        if($exceeding_delete_count > 0) {
            $self->_add_to_delete_count($dbh, $exceeding_delete_count);
        }
        return (undef, $total_count);
    } catch {
        my $e = shift;
        if($dbh) {
            $dbh->rollback();
        }
        return ($e);
    };
    @_ = @results;
    goto $callback;
}

sub _get_timeline_id {
    my ($self, $dbh, $timeline_name) = @_;
    my ($sql, @bind) = $self->{maker}->select('timelines', ['timeline_id'], sql_eq(name => $timeline_name));
    my $record = $dbh->selectrow_arrayref($sql, undef, @bind);
    if(!defined($record)) {
        return undef;
    }
    return $record->[0];
}

sub _create_timeline {
    my ($self, $dbh, $timeline_name) = @_;
    my ($sql, @bind) = $self->{maker}->insert('timelines', [name => "$timeline_name"]);
    $dbh->do($sql, undef, @bind);
    return $self->_get_timeline_id($dbh, $timeline_name);
}

sub _to_status_record {
    my ($timeline_id, $status) = @_;
    croak "status ID must be set" if not defined $status->{id};
    croak "timeline_id must be defined" if not defined $timeline_id;
    my $record = {
        timeline_id => $timeline_id,
        status_id => $status->{id},
        level => $status->{busybird}{level} || 0,
    };
    my $acked_at = $status->{busybird}{acked_at};  ## avoid autovivification
    ($record->{utc_acked_at}, $record->{timezone_acked_at}) = _extract_utc_timestamp_and_timezone($acked_at);
    ($record->{utc_created_at}, $record->{timezone_created_at}) = _extract_utc_timestamp_and_timezone($status->{created_at});
    $record->{content} = to_json($status);
    return $record;
}

sub _from_status_record {
    my ($record) = @_;
    my $status = from_json($record->{content});
    $status->{id} = $record->{status_id};
    if($record->{level} != 0 || defined($status->{busybird}{level})) {
        $status->{busybird}{level} = $record->{level};
    }
    my $acked_at_str = _create_bb_timestamp_from_utc_timestamp_and_timezone($record->{utc_acked_at}, $record->{timezone_acked_at});
    if(defined($acked_at_str) || defined($status->{busybird}{acked_at})) {
        $status->{busybird}{acked_at} = $acked_at_str;
    }
    my $created_at_str = _create_bb_timestamp_from_utc_timestamp_and_timezone($record->{utc_created_at}, $record->{timezone_created_at});
    if(defined($created_at_str) || defined($status->{created_at})) {
        $status->{created_at} = $created_at_str;
    }
    return $status;
}

sub _extract_utc_timestamp_and_timezone {
    my ($timestamp_str) = @_;
    if(!defined($timestamp_str) || $timestamp_str eq '') {
        return ($UNDEF_TIMESTAMP, 'UTC');
    }
    my $datetime = BusyBird::DateTime::Format->parse_datetime($timestamp_str);
    croak "Invalid datetime format: $timestamp_str" if not defined $datetime;
    my $timezone_name = $datetime->time_zone->name;
    $datetime->set_time_zone('UTC');
    my $utc_timestamp = _format_datetime($datetime);
    return ($utc_timestamp, $timezone_name);
}

sub _create_bb_timestamp_from_utc_timestamp_and_timezone {
    my ($utc_timestamp_str, $timezone) = @_;
    if($utc_timestamp_str eq $UNDEF_TIMESTAMP) {
        return undef;
    }
    my $dt = _parse_datetime($utc_timestamp_str);
    $dt->set_time_zone($timezone);
    return BusyBird::DateTime::Format->format_datetime($dt);
}

sub get_statuses {
    my ($self, %args) = @_;
    my $timeline = $args{timeline};
    croak "timeline parameter is mandatory" if not defined $timeline;
    my $callback = $args{callback};
    croak "callback parameter is mandatory" if not defined $callback;
    croak "callback parameter must be a CODEREF" if ref($callback) ne "CODE";
    my $ack_state = defined($args{ack_state}) ? $args{ack_state} : "any";
    if($ack_state ne "any" && $ack_state ne "unacked" && $ack_state ne "acked") {
        croak "ack_state parameter must be either 'any' or 'acked' or 'unacked'";
    }
    my $max_id = $args{max_id};
    my $count = defined($args{count}) ? $args{count} : 'all';
    if($count ne 'all' && !looks_like_number($count)) {
        croak "count parameter must be either 'all' or number";
    }
    my @results = try {
        my $dbh = $self->_get_my_dbh();
        my $timeline_id = $self->_get_timeline_id($dbh, $timeline);
        if(!defined($timeline_id)) {
            return (undef, []);
        }
        my $cond = $self->_create_base_condition($timeline_id, $ack_state);
        if(defined($max_id)) {
            my $max_id_cond = $self->_create_max_id_condition($dbh, $timeline_id, $max_id, $ack_state);
            if(!defined($max_id_cond)) {
                return (undef, []);
            }
            $cond = sql_and([$cond, $max_id_cond]);
        }
        my %maker_opt = (order_by => \@STATUSES_ORDER_BY);
        if($count ne 'all') {
            $maker_opt{limit} = "$count";
        }
        my ($sql, @bind) = $self->{maker}->select("statuses", ['*'], $cond, \%maker_opt);
        my $sth = $dbh->prepare($sql);
        $sth->execute(@bind);
        my @statuses = ();
        while(my $record = $sth->fetchrow_hashref('NAME_lc')) {
            push(@statuses, _from_status_record($record));
        }
        return (undef, \@statuses);
    }catch {
        my $e = shift;
        return ($e);
    };
    @_ = @results;
    goto $callback;
}

sub _create_base_condition {
    my ($self, $timeline_id, $ack_state) = @_;
    $ack_state ||= 'any';
    my $cond = sql_eq(timeline_id => $timeline_id);
    if($ack_state eq 'acked') {
        $cond = sql_and([$cond, sql_ne(utc_acked_at => $UNDEF_TIMESTAMP)]);
    }elsif($ack_state eq 'unacked') {
        $cond = sql_and([$cond, sql_eq(utc_acked_at => $UNDEF_TIMESTAMP)]);
    }
    return $cond;
}

sub _get_timestamps_of {
    my ($self, $dbh, $timeline_id, $status_id, $ack_state) = @_;
    my $cond = $self->_create_base_condition($timeline_id, $ack_state);
    $cond = sql_and([$cond, sql_eq(status_id => $status_id)]);
    my ($sql, @bind) = $self->{maker}->select("statuses", ['utc_acked_at', 'utc_created_at'], $cond, {
        limit => 1
    });
    my $record = $dbh->selectrow_arrayref($sql, undef, @bind);
    if(!$record) {
        return ();
    }
    return ($record->[0], $record->[1]);
}

sub _create_max_id_condition {
    my ($self, $dbh, $timeline_id, $max_id, $ack_state) = @_;
    my ($max_acked_at, $max_created_at) = $self->_get_timestamps_of($dbh, $timeline_id, $max_id, $ack_state);
    if(!defined($max_acked_at) || !defined($max_created_at)) {
        return undef;
    }
    return $self->_create_max_time_condition($max_acked_at, $max_created_at, $max_id);
}

sub _create_max_time_condition {
    my ($self, $max_acked_at, $max_created_at, $max_id) = @_;
    my $cond = sql_or([
        sql_lt(utc_acked_at => $max_acked_at),
        sql_and([
            sql_eq(utc_acked_at => $max_acked_at),
            sql_or([
                sql_lt(utc_created_at => $max_created_at),
                sql_and([
                    sql_eq(utc_created_at => $max_created_at),
                    sql_le(status_id => $max_id),
                ])
            ])
        ])
    ]);
    return $cond;
}

sub ack_statuses {
    my ($self, %args) = @_;
    my $timeline = $args{timeline};
    croak "timeline parameter is mandatory" if not defined $timeline;
    my $callback = defined($args{callback}) ? $args{callback} : sub {};
    croak "callback parameter must be a CODEREF" if ref($callback) ne 'CODE';
    my $ids = $args{ids};
    if(defined($ids) && ref($ids) && ref($ids) ne 'ARRAY') {
        croak "ids parameter must be either undef, a status ID or an array-ref of status IDs";
    }
    if(defined($ids) && !ref($ids)) {
        $ids = [$ids];
    }
    if(defined($ids) && grep { !defined($_) } @$ids) {
        croak "ids parameter array must not contain undef.";
    }
    my $max_id = $args{max_id};
    my $dbh;
    my @results = try {
        my $ack_utc_timestamp = _format_datetime(DateTime->now(time_zone => 'UTC'));
        $dbh = $self->_get_my_dbh();
        my $timeline_id = $self->_get_timeline_id($dbh, $timeline);
        return (undef, 0) if not defined $timeline_id;
        $dbh->begin_work();
        my $total_count = 0;
        if(!defined($ids) && !defined($max_id)) {
            $total_count = $self->_ack_all($dbh, $timeline_id, $ack_utc_timestamp);
        }else {
            if(defined($max_id)) {
                my $max_id_count = $self->_ack_max_id($dbh, $timeline_id, $ack_utc_timestamp, $max_id);
                $total_count += $max_id_count if $max_id_count > 0;
            }
            if(defined($ids)) {
                my $ids_count = $self->_ack_ids($dbh, $timeline_id, $ack_utc_timestamp, $ids);
                $total_count += $ids_count if $ids_count > 0;
            }
        }
        $dbh->commit();
        $total_count = 0 if $total_count < 0;
        return (undef, $total_count);
    }catch {
        my $e = shift;
        if($dbh) {
            $dbh->rollback();
        }
        return ($e);
    };
    @_ = @results;
    goto $callback;
}

sub _ack_all {
    my ($self, $dbh, $timeline_id, $ack_utc_timestamp) = @_;
    my ($sql, @bind) = $self->{maker}->update(
        'statuses', [utc_acked_at => $ack_utc_timestamp],
        sql_and([sql_eq(timeline_id => $timeline_id), sql_eq(utc_acked_at => $UNDEF_TIMESTAMP)]),
    );
    return $dbh->do($sql, undef, @bind);
}

sub _ack_max_id {
    my ($self, $dbh, $timeline_id, $ack_utc_timestamp, $max_id) = @_;
    my $max_id_cond = $self->_create_max_id_condition($dbh, $timeline_id, $max_id, 'unacked');
    if(!defined($max_id_cond)) {
        return 0;
    }
    my $cond = $self->_create_base_condition($timeline_id, 'unacked');
    my ($sql, @bind) = $self->{maker}->update(
        'statuses', [utc_acked_at => $ack_utc_timestamp], sql_and([$cond, $max_id_cond])
    );
    return $dbh->do($sql, undef, @bind);
}

sub _ack_ids {
    my ($self, $dbh, $timeline_id, $ack_utc_timestamp, $ids) = @_;
    if(@$ids == 0) {
        return 0;
    }
    my $total_count = 0;
    my $sth;
    foreach my $id (@$ids) {
        my $cond = $self->_create_base_condition($timeline_id, 'unacked');
        $cond = sql_and([$cond, sql_eq(status_id => $id)]);
        my ($sql, @bind) = $self->{maker}->update(
            'statuses', [utc_acked_at => $ack_utc_timestamp], $cond
        );
        if(!$sth) {
            $sth = $dbh->prepare($sql);
        }
        my $count = $sth->execute(@bind);
        if($count > 0) {
            $total_count += $count;
        }
    }
    return $total_count;
}

sub delete_statuses {
    my ($self, %args) = @_;
    my $timeline = $args{timeline};
    croak 'timeline parameter is mandatory' if not defined $timeline;
    croak 'ids parameter is mandatory' if not exists $args{ids};
    my $ids = $args{ids};
    if(defined($ids) && ref($ids) && ref($ids) ne 'ARRAY') {
        croak 'ids parameter must be either undef, a status ID or array-ref of status IDs.';
    }
    if(defined($ids) && !ref($ids)) {
        $ids = [$ids];
    }
    if(defined($ids) && grep { !defined($_) } @$ids) {
        croak "ids parameter array must not contain undef.";
    }
    my $callback = defined($args{callback}) ? $args{callback} : sub {};
    croak 'callback parameter must be a CODEREF' if ref($callback) ne 'CODE';
    my $dbh;
    my @results = try {
        my $dbh = $self->_get_my_dbh();
        my $timeline_id = $self->_get_timeline_id($dbh, $timeline);
        if(!defined($timeline_id)) {
            return (undef, 0);
        }
        $dbh->begin_work();
        my $total_count;
        if(defined($ids)) {
            $total_count = $self->_delete_ids($dbh, $timeline_id, $ids);
        }else {
            $total_count = $self->_delete_timeline($dbh, $timeline_id);
        }
        $total_count = 0 if $total_count < 0;
        $dbh->commit();
        $self->_add_to_delete_count($dbh, $total_count);
        return (undef, $total_count);
    }catch {
        my $e = shift;
        if($dbh) {
            $dbh->rollback();
        }
        return ($e);
    };
    @_ = @results;
    goto $callback;
}

sub _delete_timeline {
    my ($self, $dbh, $timeline_id) = @_;
    my ($sql, @bind) = $self->{maker}->delete('statuses', sql_eq(timeline_id => $timeline_id));
    my $status_count = $dbh->do($sql, undef, @bind);
    ($sql, @bind) = $self->{maker}->delete('timelines', sql_eq(timeline_id => $timeline_id));
    $dbh->do($sql, undef, @bind);
    return $status_count;
}

sub _delete_ids {
    my ($self, $dbh, $timeline_id, $ids) = @_;
    return 0 if @$ids == 0;
    my $sth;
    my $total_count = 0;
    foreach my $id (@$ids) {
        my ($sql, @bind) = $self->{maker}->delete('statuses', sql_and([
            sql_eq(timeline_id => $timeline_id), sql_eq(status_id => $id)
        ]));
        if(!$sth) {
            $sth = $dbh->prepare($sql);
        }
        my $count = $sth->execute(@bind);
        if($count > 0) {
            $total_count += $count;
        }
    }
    return $total_count;
}

sub _delete_exceeding_statuses {
    my ($self, $dbh, $timeline_id) = @_;
    ## get total count in the timeline
    my ($sql, @bind) = $self->{maker}->select('statuses', [\'count(*)'], sql_eq(timeline_id => $timeline_id));
    my $row = $dbh->selectrow_arrayref($sql, undef, @bind);
    if(!defined($row)) {
        die "count query for timeline $timeline_id returns undef. something is wrong.";
    }
    my $total_count = $row->[0];
    
    if($total_count <= $self->{hard_max_status_num}) {
        return 0;
    }

    ## get the top of the exceeding statuses
    ($sql, @bind) = $self->{maker}->select('statuses', [qw(utc_acked_at utc_created_at status_id)], sql_eq(timeline_id => $timeline_id), {
        order_by => \@STATUSES_ORDER_BY,
        offset => $self->{max_status_num},
        limit => 1,
    });
    $row = $dbh->selectrow_arrayref($sql, undef, @bind);
    if(!defined($row)) {
        die "selecting the top of exceeding status returns undef. something is wrong.";
    }
    my $time_cond = $self->_create_max_time_condition(@$row);

    ## execute deletion
    my $timeline_cond = sql_eq(timeline_id => $timeline_id);
    ($sql, @bind) = $self->{maker}->delete('statuses', sql_and([$timeline_cond, $time_cond]));
    return $dbh->do($sql, undef, @bind);
}

sub get_unacked_counts {
    my ($self, %args) = @_;
    my $timeline = $args{timeline};
    croak 'timeline parameter is mandatory' if not defined $timeline;
    my $callback = $args{callback};
    croak 'callback parameter is mandatory' if not defined $callback;
    croak 'callback parameter must be a CODEREF' if ref($callback) ne 'CODE';
    my @results = try {
        my $dbh = $self->_get_my_dbh();
        my $timeline_id = $self->_get_timeline_id($dbh, $timeline);
        my %result_obj = (total => 0);
        if(!defined($timeline_id)) {
            return (undef, \%result_obj);
        }
        my $cond = $self->_create_base_condition($timeline_id, 'unacked');
        my ($sql, @bind) = $self->{maker}->select('statuses', ['level', \'count(status_id)'], $cond, {
            group_by => 'level'
        });
        my $sth = $dbh->prepare($sql);
        $sth->execute(@bind);
        while(my $record = $sth->fetchrow_arrayref()) {
            $result_obj{total} += $record->[1];
            $result_obj{$record->[0]} = $record->[1];
        }
        return (undef, \%result_obj);
    }catch {
        my $e = shift;
        return ($e);
    };
    @_ = @results;
    goto $callback;
}

sub _add_to_delete_count {
    my ($self, $dbh, $add_count) = @_;
    return if $self->{vacuum_on_delete} <= 0;
    return if $add_count <= 0;
    my ($sql, @bind) = $self->{maker}->update(
        'delete_counts',
        [delete_count => sql_raw('delete_count + ?', $add_count)],
        sql_eq(delete_count_id => $DELETE_COUNT_ID));
    $dbh->do($sql, undef, @bind);
    
    ($sql, @bind) = $self->{maker}->select('delete_counts', ["delete_count"], sql_eq(delete_count_id => $DELETE_COUNT_ID));
    my $row = $dbh->selectrow_arrayref($sql, undef, @bind);
    if(!defined($row)) {
        die "no delete_counts row with delete_count_id = $DELETE_COUNT_ID. something is wrong.";
    }
    my $current_delete_count = $row->[0];

    if($current_delete_count >= $self->{vacuum_on_delete}) {
        $self->_do_vacuum($dbh);
    }
}

sub _do_vacuum {
    my ($self, $dbh) = @_;
    my ($sql, @bind) = $self->{maker}->update('delete_counts', [delete_count => 0], sql_eq(delete_count_id => $DELETE_COUNT_ID));
    $dbh->do($sql, undef, @bind);
    $dbh->do('VACUUM');
}

sub vacuum {
    my ($self) = @_;
    $self->_do_vacuum($self->_get_my_dbh());
}

sub contains {
    my ($self, %args) = @_;
    my $timeline = $args{timeline};
    croak 'timeline parameter is mandatory' if not defined $timeline;
    my $callback = $args{callback};
    croak 'callback parameter is mandatory' if not defined $callback;
    my $query = $args{query};
    croak 'query parameter is mandatory' if not defined $query;
    my $ref_query = ref($query);
    if(!$ref_query || $ref_query eq 'HASH') {
        $query = [$query];
    }elsif($ref_query eq 'ARRAY') {
        ;
    }else {
        croak 'query parameter must be either a status, status ID or array-ref';
    }
    if(grep { !defined($_) } @$query) {
        croak "query element must be defined";
    }
    my @method_result = try {
        my $dbh = $self->_get_my_dbh();
        my $timeline_id = $self->_get_timeline_id($dbh, $timeline);
        my @ret_contained = ();
        my @ret_not_contained = ();
        if(!defined($timeline_id)) {
            @ret_not_contained = @$query;
            return (undef, \@ret_contained, \@ret_not_contained);
        }
        my $sth;
        foreach my $query_elem (@$query) {
            my $status_id = (ref($query_elem) eq 'HASH') ? $query_elem->{id} : $query_elem;
            if(!defined($status_id)) {
                ## ID-less statuses are always 'not contained'.
                push @ret_not_contained, $query_elem;
                next;
            }
            my ($sql, @bind) = $self->{maker}->select(
                'statuses', ['timeline_id', 'status_id'],
                sql_and([sql_eq(timeline_id => $timeline_id), sql_eq(status_id => $status_id)])
            );
            if(!$sth) {
                $sth = $dbh->prepare($sql);
            }
            $sth->execute(@bind);
            my $result = $sth->fetchall_arrayref();
            if(!defined($result)) {
                confess "Statement handle is inactive. Something is wrong.";
            }
            if(@$result) {
                push @ret_contained, $query_elem;
            }else {
                push @ret_not_contained, $query_elem;
            }
        }
        return (undef, \@ret_contained, \@ret_not_contained);
    }catch {
        my $e = shift;
        return ($e);
    };
    @_ = @method_result;
    goto $callback;
}

sub get_timeline_names {
    my ($self) = @_;
    my $dbh = $self->_get_my_dbh();
    my ($sql, @bind) = $self->{maker}->select(
        'timelines', ['name']
    );
    my $result = $dbh->selectall_arrayref($sql, undef, @bind);
    my @return = map { $_->[0] } @$result;
    return @return;
}

1;

__END__

=pod

=head1 NAME

BusyBird::StatusStorage::SQLite - status storage in SQLite database

=head1 SYNOPSIS

    use BusyBird;
    use BusyBird::StatusStorage::SQLite;
    
    my $storage = BusyBird::StatusStorage::SQLite->new(
        path => 'path/to/storage.sqlite3',
        max_status_num => 5000
    );
    
    busybird->set_config(
        default_status_storage => $storage
    );

=head1 DESCRIPTION

This is an implementation of L<BusyBird::StatusStorage> interface.
It stores statuses in an SQLite database.

This storage is synchronous, i.e., all operations block the thread
and the callback is called before the method returns.

=head1 CLASS METHOD

=head2 $storage = BusyBird::StatusStorage::SQLite->new(%args)

The constructor.

Fields in C<%args> are:

=over

=item C<path> => FILE_PATH (mandatory)

Path string to the SQLite database file.
If C<':memory:'> is specified, it creates a temporary in-memory storage.

=item C<max_status_num> => INT (optional, default: 2000)

The maximum number of statuses the storage guarantees to store per timeline.
You cannot expect a timeline to keep more statuses than this number.

=item C<hard_max_status_num> => INT (optional, default: 120% of max_status_num)

The hard limit max number of statuses the storage is able to store per timeline.
When the number of statuses in a timeline exceeds this number,
it deletes old statuses from the timeline so that the timeline has C<max_status_num> statuses.

=item C<vacuum_on_delete> => INT (optional, default: 200% of max_status_num)

The status storage automatically executes C<VACUUM> every time this number of statuses are
deleted from the storage. B<The number is for the whole storage, not per timeline>.

If you set this option less than or equal to 0, it never C<VACUUM> itself.


=back

=head1 OBJECT METHODS

L<BusyBird::StatusStorage::SQLite> implements all object methods in L<BusyBird::StatusStorage>.
In addition to it, it has the following methods.

=head2 $storage->vacuum()

Executes SQL C<VACUUM> on the database.

=head2 @timeline_names = $storage->get_timeline_names()

Returns all timeline names in the C<$storage>.


=head1 AUTHOR

Toshio Ito C<< <toshioito [at] cpan.org> >>

=cut

