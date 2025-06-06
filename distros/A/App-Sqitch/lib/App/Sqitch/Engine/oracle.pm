package App::Sqitch::Engine::oracle;

use 5.010;
use Moo;
use utf8;
use Path::Class;
use DBI;
use Try::Tiny;
use App::Sqitch::X qw(hurl);
use Locale::TextDomain qw(App-Sqitch);
use App::Sqitch::Plan::Change;
use List::Util qw(first);
use App::Sqitch::Types qw(DBH Dir ArrayRef);
use namespace::autoclean;

extends 'App::Sqitch::Engine';

our $VERSION = 'v1.5.2'; # VERSION

BEGIN {
    # We tell the Oracle connector which encoding to use. The last part of the
    # environment variable NLS_LANG is relevant concerning data encoding.
    $ENV{NLS_LANG} = 'AMERICAN_AMERICA.AL32UTF8';

    # Disable SQLPATH so that no start scripts run.
    $ENV{SQLPATH} = '';
}

sub destination {
    my $self = shift;

    # Just use the target name if it doesn't look like a URI or if the URI
    # includes the database name.
    return $self->target->name if $self->target->name !~ /:/
        || $self->target->uri->dbname;

    # Use the URI sans password, and with the database name added.
    my $uri = $self->target->uri->clone;
    $uri->password(undef) if $uri->password;
    $uri->dbname(
           $ENV{TWO_TASK}
        || ( App::Sqitch::ISWIN ? $ENV{LOCAL} : undef )
        || $ENV{ORACLE_SID}
        || $self->username
    );
    return $uri->as_string;
}

# No username or password defaults.
sub _def_user { }
sub _def_pass { }

has _sqlplus => (
    is         => 'ro',
    isa        => ArrayRef,
    lazy       => 1,
    default    => sub {
        my $self = shift;
        [ $self->client, qw(-S -L /nolog) ];
    },
);

sub sqlplus { @{ shift->_sqlplus } }

has tmpdir => (
    is       => 'ro',
    isa      => Dir,
    lazy     => 1,
    default  => sub {
        require File::Temp;
        dir File::Temp::tempdir( CLEANUP => 1 );
    },
);

sub key    { 'oracle' }
sub name   { 'Oracle' }
sub driver { 'DBD::Oracle 1.23' }
sub default_registry { $_[0]->username || '' }

sub default_client {
    if ($ENV{ORACLE_HOME}) {
        my $bin = 'sqlplus' . (App::Sqitch::ISWIN || $^O eq 'cygwin' ? '.exe' : '');
        my $path = file $ENV{ORACLE_HOME}, 'bin', $bin;
        return $path->stringify if -f $path && -x $path;
        $path = file $ENV{ORACLE_HOME}, $bin;
        return $path->stringify if -f $path && -x $path;
    }
    return 'sqlplus';
}

has dbh => (
    is      => 'rw',
    isa     => DBH,
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->use_driver;

        DBI->connect($self->_dsn, $self->username, $self->password, {
            PrintError        => 0,
            RaiseError        => 0,
            AutoCommit        => 1,
            FetchHashKeyName  => 'NAME_lc',
            HandleError       => $self->error_handler,
            Callbacks         => {
                connected => sub {
                    my $dbh = shift;
                    $dbh->do("ALTER SESSION SET $_='YYYY-MM-DD HH24:MI:SS TZR'") for qw(
                        nls_date_format
                        nls_timestamp_format
                        nls_timestamp_tz_format
                    );
                    if (my $schema = $self->registry) {
                        $dbh->do("ALTER SESSION SET CURRENT_SCHEMA = $schema")
                            or $self->_handle_no_registry($dbh);
                    }
                    return;
                },
            },
        });
    }
);

# Need to wait until dbh is defined.
with 'App::Sqitch::Role::DBIEngine';

sub _log_tags_param {
    [ map { $_->format_name } $_[1]->tags ];
}

sub _log_requires_param {
    [ map { $_->as_string } $_[1]->requires ];
}

sub _log_conflicts_param {
    [ map { $_->as_string } $_[1]->conflicts ];
}

sub _ts2char_format {
    # q{CAST(to_char(%1$s AT TIME ZONE 'UTC', '"year":YYYY:"month":MM:"day":DD') AS VARCHAR2(100 byte)) || CAST(to_char(%1$s AT TIME ZONE 'UTC', ':"hour":HH24:"minute":MI:"second":SS:"time_zone":"UTC"')  AS VARCHAR2(168 byte))}
    # Good grief, Oracle, WTF? https://github.com/sqitchers/sqitch/issues/316
    join ' || ', (
        q{to_char(%1$s AT TIME ZONE 'UTC', '"year":YYYY')},
        q{to_char(%1$s AT TIME ZONE 'UTC', ':"month":MM')},
        q{to_char(%1$s AT TIME ZONE 'UTC', ':"day":DD')},
        q{to_char(%1$s AT TIME ZONE 'UTC', ':"hour":HH24')},
        q{to_char(%1$s AT TIME ZONE 'UTC', ':"minute":MI')},
        q{to_char(%1$s AT TIME ZONE 'UTC', ':"second":SS')},
        q{':time_zone:UTC'},
    );
}
sub _ts_default { 'current_timestamp' }

sub _can_limit { 0 }

sub _char2ts {
    my $dt = $_[1];
    join ' ', $dt->ymd('-'), $dt->hms(':'), $dt->time_zone->name;
}

sub _listagg_format {
    # https://stackoverflow.com/q/16313631/79202
    return q{CAST(COLLECT(CAST(%s AS VARCHAR2(512))) AS sqitch_array)};
}

sub _regex_op { 'REGEXP_LIKE(%s, ?)' }

sub _simple_from { ' FROM dual' }

sub _multi_values {
    my ($self, $count, $expr) = @_;
    return join "\nUNION ALL ", ("SELECT $expr FROM dual") x $count;
}

sub _dt($) {
    require App::Sqitch::DateTime;
    return App::Sqitch::DateTime->new(split /:/ => shift);
}

sub _cid {
    my ( $self, $ord, $offset, $project ) = @_;

    return try {
        return $self->dbh->selectcol_arrayref(qq{
            SELECT change_id FROM (
                SELECT change_id, rownum as rnum FROM (
                    SELECT change_id
                      FROM changes
                     WHERE project = ?
                     ORDER BY committed_at $ord
                )
            ) WHERE rnum = ?
        }, undef, $project || $self->plan->project, ($offset // 0) + 1)->[0];
    } catch {
        return if $self->_no_table_error;
        die $_;
    };
}

sub _cid_head {
    my ($self, $project, $change) = @_;
    return $self->dbh->selectcol_arrayref(qq{
        SELECT change_id FROM (
            SELECT change_id
              FROM changes
             WHERE project = ?
               AND change  = ?
             ORDER BY committed_at DESC
        ) WHERE rownum = 1
    }, undef, $project, $change)->[0];
}

sub _select_state {
    my ( $self, $project, $with_hash ) = @_;
    my $cdtcol = sprintf $self->_ts2char_format, 'c.committed_at';
    my $pdtcol = sprintf $self->_ts2char_format, 'c.planned_at';
    my $tagcol = sprintf $self->_listagg_format, 't.tag';
    my $hshcol = $with_hash ? "c.script_hash\n                 , " : '';
    my $dbh    = $self->dbh;
    return $dbh->selectrow_hashref(qq{
        SELECT * FROM (
            SELECT c.change_id
                 , ${hshcol}c.change
                 , c.project
                 , c.note
                 , c.committer_name
                 , c.committer_email
                 , $cdtcol AS committed_at
                 , c.planner_name
                 , c.planner_email
                 , $pdtcol AS planned_at
                 , $tagcol AS tags
              FROM changes   c
              LEFT JOIN tags t ON c.change_id = t.change_id
             WHERE c.project = ?
             GROUP BY c.change_id
                 , ${hshcol}c.change
                 , c.project
                 , c.note
                 , c.committer_name
                 , c.committer_email
                 , c.committed_at
                 , c.planner_name
                 , c.planner_email
                 , c.planned_at
             ORDER BY c.committed_at DESC
        ) WHERE rownum = 1
    }, undef, $project // $self->plan->project);
}

sub is_deployed_change {
    my ( $self, $change ) = @_;
    $self->dbh->selectcol_arrayref(
        'SELECT 1 FROM changes WHERE change_id = ?',
        undef, $change->id
    )->[0];
}

sub _initialized {
    my $self = shift;
    return $self->dbh->selectcol_arrayref(q{
        SELECT 1
          FROM all_tables
         WHERE owner = UPPER(?)
           AND table_name = 'CHANGES'
    }, undef, $self->registry)->[0];
}

sub _log_event {
    my ( $self, $event, $change, $tags, $requires, $conflicts) = @_;
    my $dbh    = $self->dbh;
    my $sqitch = $self->sqitch;

    $tags      ||= $self->_log_tags_param($change);
    $requires  ||= $self->_log_requires_param($change);
    $conflicts ||= $self->_log_conflicts_param($change);

    # Use the sqitch_array() constructor to insert arrays of values.
    my $tag_ph = 'sqitch_array('. join(', ', ('?') x @{ $tags      }) . ')';
    my $req_ph = 'sqitch_array('. join(', ', ('?') x @{ $requires  }) . ')';
    my $con_ph = 'sqitch_array('. join(', ', ('?') x @{ $conflicts }) . ')';
    my $ts     = $self->_ts_default;

    $dbh->do(qq{
        INSERT INTO events (
              event
            , change_id
            , change
            , project
            , note
            , tags
            , requires
            , conflicts
            , committer_name
            , committer_email
            , planned_at
            , planner_name
            , planner_email
            , committed_at
        )
        VALUES (?, ?, ?, ?, ?, $tag_ph, $req_ph, $con_ph, ?, ?, ?, ?, ?, $ts)
    }, undef,
        $event,
        $change->id,
        $change->name,
        $change->project,
        $change->note,
        @{ $tags      },
        @{ $requires  },
        @{ $conflicts },
        $sqitch->user_name,
        $sqitch->user_email,
        $self->_char2ts( $change->timestamp ),
        $change->planner_name,
        $change->planner_email,
    );

    return $self;
}

sub changes_requiring_change {
    my ( $self, $change ) = @_;
    # Why CTE: https://forums.oracle.com/forums/thread.jspa?threadID=1005221
    return @{ $self->dbh->selectall_arrayref(q{
        WITH tag AS (
            SELECT tag, committed_at, project,
                   ROW_NUMBER() OVER (partition by project ORDER BY committed_at) AS rnk
              FROM tags
        )
        SELECT c.change_id, c.project, c.change, t.tag AS asof_tag
          FROM dependencies d
          JOIN changes  c ON c.change_id = d.change_id
          LEFT JOIN tag t ON t.project   = c.project AND t.committed_at >= c.committed_at
         WHERE d.dependency_id = ?
           AND (t.rnk IS NULL OR t.rnk = 1)
    }, { Slice => {} }, $change->id) };
}

sub name_for_change_id {
    my ( $self, $change_id ) = @_;
    # Why CTE: https://forums.oracle.com/forums/thread.jspa?threadID=1005221
    return $self->dbh->selectcol_arrayref(q{
        WITH tag AS (
            SELECT tag, committed_at, project,
                   ROW_NUMBER() OVER (partition by project ORDER BY committed_at) AS rnk
              FROM tags
        )
        SELECT change || COALESCE(t.tag, '@HEAD')
          FROM changes c
          LEFT JOIN tag t ON c.project = t.project AND t.committed_at >= c.committed_at
         WHERE change_id = ?
           AND (t.rnk IS NULL OR t.rnk = 1)
    }, undef, $change_id)->[0];
}

sub change_id_offset_from_id {
    my ( $self, $change_id, $offset ) = @_;

    # Just return the ID if there is no offset.
    return $change_id unless $offset;

    # Are we offset forwards or backwards?
    my ( $dir, $op ) = $offset > 0 ? ( 'ASC', '>' ) : ( 'DESC' , '<' );
    return $self->dbh->selectcol_arrayref(qq{
        SELECT id FROM (
            SELECT id, rownum AS rnum FROM (
                SELECT change_id AS id
                  FROM changes
                 WHERE project = ?
                   AND committed_at $op (
                       SELECT committed_at FROM changes WHERE change_id = ?
                 )
                 ORDER BY committed_at $dir
            )
        ) WHERE rnum = ?
    }, undef, $self->plan->project, $change_id, abs $offset)->[0];
}

sub change_offset_from_id {
    my ( $self, $change_id, $offset ) = @_;

    # Just return the object if there is no offset.
    return $self->load_change($change_id) unless $offset;

    # Are we offset forwards or backwards?
    my ( $dir, $op ) = $offset > 0 ? ( 'ASC', '>' ) : ( 'DESC' , '<' );
    my $tscol  = sprintf $self->_ts2char_format, 'c.planned_at';
    my $tagcol = sprintf $self->_listagg_format, 't.tag';

    my $change = $self->dbh->selectrow_hashref(qq{
        SELECT id, name, project, note, timestamp, planner_name, planner_email, tags, script_hash
          FROM (
              SELECT id, name, project, note, timestamp, planner_name, planner_email, tags, script_hash, rownum AS rnum
                FROM (
                  SELECT c.change_id AS id, c.change AS name, c.project, c.note,
                         $tscol AS timestamp, c.planner_name, c.planner_email,
                         $tagcol AS tags, c.script_hash
                    FROM changes   c
                    LEFT JOIN tags t ON c.change_id = t.change_id
                   WHERE c.project = ?
                     AND c.committed_at $op (
                         SELECT committed_at FROM changes WHERE change_id = ?
                   )
                   GROUP BY c.change_id, c.change, c.project, c.note, c.planned_at,
                         c.planner_name, c.planner_email, c.committed_at, c.script_hash
                   ORDER BY c.committed_at $dir
              )
         ) WHERE rnum = ?
    }, undef, $self->plan->project, $change_id, abs $offset) || return undef;
    $change->{timestamp} = _dt $change->{timestamp};
    return $change;
}

sub is_deployed_tag {
    my ( $self, $tag ) = @_;
    return $self->dbh->selectcol_arrayref(
        'SELECT 1 FROM tags WHERE tag_id = ?',
        undef, $tag->id
    )->[0];
}

sub are_deployed_changes {
    my $self = shift;
    @{ $self->dbh->selectcol_arrayref(
        'SELECT change_id FROM changes WHERE ' . _change_id_in(scalar @_),
        undef,
        map { $_->id } @_,
    ) };
}

sub _change_id_in {
    my $i = shift;
    my @qs;
    while ($i > 250) {
        push @qs => 'change_id IN (' . join(', ' => ('?') x 250) . ')';
        $i -= 250;
    }
    push @qs => 'change_id IN (' . join(', ' => ('?') x $i) . ')' if $i > 0;
    return join ' OR ', @qs;
}

sub _registry_variable {
    my $self   = shift;
    my $schema = $self->registry;
    return $schema ? ("DEFINE registry=$schema") : (
        # Select the current schema into &registry.
        # https://www.orafaq.com/node/515
        'COLUMN sname for a30 new_value registry',
        q{SELECT SYS_CONTEXT('USERENV', 'SESSION_SCHEMA') AS sname FROM DUAL;},
    );
}

sub _initialize {
    my $self   = shift;
    my $schema = $self->registry;
    hurl engine => __ 'Sqitch already initialized' if $self->initialized;

    # Load up our database.
    (my $file = file(__FILE__)->dir->file('oracle.sql')) =~ s/"/""/g;
    $self->_run_with_verbosity($file);
    $self->dbh->do("ALTER SESSION SET CURRENT_SCHEMA = $schema") if $schema;
    $self->_register_release;
}

# Override for special handling of regular the expression operator and
# LIMIT/OFFSET.
sub search_events {
    my ( $self, %p ) = @_;

    # Determine order direction.
    my $dir = 'DESC';
    if (my $d = delete $p{direction}) {
        $dir = $d =~ /^ASC/i  ? 'ASC'
             : $d =~ /^DESC/i ? 'DESC'
             : hurl 'Search direction must be either "ASC" or "DESC"';
    }

    # Limit with regular expressions?
    my (@wheres, @params);
    for my $spec (
        [ committer => 'committer_name' ],
        [ planner   => 'planner_name'   ],
        [ change    => 'change'         ],
        [ project   => 'project'        ],
    ) {
        my $regex = delete $p{ $spec->[0] } // next;
        push @wheres => "REGEXP_LIKE($spec->[1], ?)";
        push @params => $regex;
    }

    # Match events?
    if (my $e = delete $p{event} ) {
        my ($in, @vals) = $self->_in_expr( $e );
        push @wheres => "event $in";
        push @params => @vals;
    }

    # Assemble the where clause.
    my $where = @wheres
        ? "\n         WHERE " . join( "\n               ", @wheres )
        : '';

    # Handle remaining parameters.
    my ($lim, $off) = (delete $p{limit}, delete $p{offset});

    hurl 'Invalid parameters passed to search_events(): '
        . join ', ', sort keys %p if %p;

    # Prepare, execute, and return.
    my $cdtcol = sprintf $self->_ts2char_format, 'committed_at';
    my $pdtcol = sprintf $self->_ts2char_format, 'planned_at';
    my $sql = qq{
        SELECT event
             , project
             , change_id
             , change
             , note
             , requires
             , conflicts
             , tags
             , committer_name
             , committer_email
             , $cdtcol AS committed_at
             , planner_name
             , planner_email
             , $pdtcol AS planned_at
          FROM events$where
         ORDER BY events.committed_at $dir
    };

    if ($lim || $off) {
        my @limits;
        if ($lim) {
            $off //= 0;
            push @params => $lim + $off;
            push @limits => 'rnum <= ?';
        }
        if ($off) {
            push @params => $off;
            push @limits => 'rnum > ?';
        }

        $sql = "SELECT * FROM ( SELECT ROWNUM AS rnum, i.* FROM ($sql) i ) WHERE "
            . join ' AND ', @limits;
    }

    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@params);
    return sub {
        my $row = $sth->fetchrow_hashref or return;
        delete $row->{rnum};
        $row->{committed_at} = _dt $row->{committed_at};
        $row->{planned_at}   = _dt $row->{planned_at};
        return $row;
    };
}

# Override to lock the changes table. This ensures that only one instance of
# Sqitch runs at one time.
sub begin_work {
    my $self = shift;
    my $dbh = $self->dbh;

    # Start transaction and lock changes to allow only one change at a time.
    $dbh->begin_work;
    $dbh->do('LOCK TABLE changes IN EXCLUSIVE MODE');
    return $self;
}

sub _file_for_script {
    my ($self, $file) = @_;

    # Just use the file if no special character.
    if ($file !~ /[@?%\$]/) {
        $file =~ s/"/""/g;
        return $file;
    }

    # Alias or copy the file to a temporary directory that's removed on exit.
    (my $alias = $file->basename) =~ s/[@?%\$]/_/g;
    $alias = $self->tmpdir->file($alias);

    # Remove existing file.
    if (-e $alias) {
        $alias->remove or hurl oracle => __x(
            'Cannot remove {file}: {error}',
            file  => $alias,
            error => $!
        );
    }

    if (App::Sqitch::ISWIN) {
        # Copy it.
        $file->copy_to($alias) or hurl oracle => __x(
            'Cannot copy {file} to {alias}: {error}',
            file  => $file,
            alias => $alias,
            error => $!
        );
    } else {
        # Symlink it.
        $alias->remove;
        symlink $file->absolute, $alias or hurl oracle => __x(
            'Cannot symlink {file} to {alias}: {error}',
            file  => $file,
            alias => $alias,
            error => $!
        );
    }

    # Return the alias.
    $alias =~ s/"/""/g;
    return $alias;
}

sub run_file {
    my $self = shift;
    my $file = $self->_file_for_script(shift);
    $self->_run(qq{\@"$file"});
}

sub _run_with_verbosity {
    my $self = shift;
    my $file = $self->_file_for_script(shift);
    # Suppress STDOUT unless we want extra verbosity.
    my $meth = $self->can($self->sqitch->verbosity > 1 ? '_run' : '_capture');
    $self->$meth(qq{\@"$file"});
}

sub run_upgrade { shift->_run_with_verbosity(@_) }
sub run_verify  { shift->_run_with_verbosity(@_) }

sub run_handle {
    my ($self, $fh) = @_;
    my $conn = $self->_script;
    open my $tfh, '<:utf8_strict', \$conn;
    $self->sqitch->spool( [$tfh, $fh], $self->sqlplus );
}

# Override to take advantage of the RETURNING expression, and to save tags as
# an array rather than a space-delimited string.
sub log_revert_change {
    my ($self, $change) = @_;
    my $dbh = $self->dbh;
    my $cid = $change->id;

    # Delete tags.
    my $sth = $dbh->prepare(
        'DELETE FROM tags WHERE change_id = ? RETURNING tag INTO ?',
    );
    $sth->bind_param(1, $cid);
    $sth->bind_param_inout_array(2, my $del_tags = [], 0, {
        ora_type => DBD::Oracle::ORA_VARCHAR2()
    });
    $sth->execute;

    # Retrieve dependencies.
    my $depcol = sprintf $self->_listagg_format, 'dependency';
    my ($req, $conf) = $dbh->selectrow_array(qq{
        SELECT (
            SELECT $depcol
              FROM dependencies
             WHERE change_id = ?
               AND type = 'require'
        ),
        (
            SELECT $depcol
              FROM dependencies
             WHERE change_id = ?
               AND type = 'conflict'
        ) FROM dual
    }, undef, $cid, $cid);

    # Delete the change record.
    $dbh->do(
        'DELETE FROM changes where change_id = ?',
        undef, $change->id,
    );

    # Log it.
    return $self->_log_event( revert => $change, $del_tags, $req, $conf );
}

sub _no_table_error  {
    return $DBI::err && $DBI::err == 942; # ORA-00942: table or view does not exist
}

sub _no_column_error  {
    return $DBI::err && $DBI::err == 904; # ORA-00904: invalid identifier
}

sub _unique_error  {
    return $DBI::err && $DBI::err == 1; # ORA-00001: unique constraint violated
}

sub _script {
    my $self = shift;
    my $uri  = $self->uri;
    my $conn = '';
    # Use _port instead of port so it's empty if no port is in the URI.
    # https://github.com/sqitchers/sqitch/issues/675
    my ($user, $pass, $host, $port) = (
        $self->username, $self->password, $uri->host, $uri->_port
    );
    if ($user || $pass || $host || $port) {
        $conn = $user // '';
        if ($pass) {
            $pass =~ s/"/""/g;
            $conn .= qq{/"$pass"};
        }
        if (my $db = $uri->dbname) {
            $conn .= '@';
            $db =~ s/"/""/g;
            if ($host || $port) {
                $conn .= '//' . ($host || '');
                if ($port) {
                    $conn .= ":$port";
                }
                $conn .= qq{/"$db"};
            } else {
                $conn .= qq{"$db"};
            }
        }
    } else {
        # OS authentication or Oracle wallet (no username or password).
        if (my $db = $uri->dbname) {
            $db =~ s/"/""/g;
            $conn = qq{/@"$db"};
        }
    }
    my %vars = $self->variables;

    return join "\n" => (
        'SET ECHO OFF NEWP 0 SPA 0 PAGES 0 FEED OFF HEAD OFF TRIMS ON TAB OFF VERIFY OFF',
        'WHENEVER OSERROR EXIT 9;',
        'WHENEVER SQLERROR EXIT 4;',
        (map {; (my $v = $vars{$_}) =~ s/"/""/g; qq{DEFINE $_="$v"} } sort keys %vars),
        "connect $conn",
        $self->_registry_variable,
        @_
    );
}

sub _run {
    my $self = shift;
    my $script = $self->_script(@_);
    open my $fh, '<:utf8_strict', \$script;
    return $self->sqitch->spool( $fh, $self->sqlplus );
}

sub _capture {
    my $self = shift;
    my $conn = $self->_script(@_);
    my @out;

    require IPC::Run3;
    IPC::Run3::run3(
        [$self->sqlplus], \$conn, \@out, \@out,
        { return_if_system_error => 1 },
    );
    if (my $err = $?) {
        # Ugh, send everything to STDERR.
        $self->sqitch->vent(@out);
        hurl io => __x(
            '{command} unexpectedly returned exit value {exitval}',
            command => $self->client,
            exitval => ($err >> 8),
        );
    }

    return wantarray ? @out : \@out;
}

1;

__END__

=head1 Name

App::Sqitch::Engine::oracle - Sqitch Oracle Engine

=head1 Synopsis

  my $oracle = App::Sqitch::Engine->load( engine => 'oracle' );

=head1 Description

App::Sqitch::Engine::oracle provides the Oracle storage engine for Sqitch. It
supports Oracle 10g and higher.

=head1 Interface

=head2 Instance Methods

=head3 C<initialized>

  $oracle->initialize unless $oracle->initialized;

Returns true if the database has been initialized for Sqitch, and false if it
has not.

=head3 C<initialize>

  $oracle->initialize;

Initializes a database for Sqitch by installing the Sqitch registry schema.

=head3 C<sqlplus>

Returns a list containing the C<sqlplus> client and options to be passed to it.
Used internally when executing scripts.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 License

Copyright (c) 2012-2025 David E. Wheeler, 2012-2021 iovation Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
