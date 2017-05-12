package DBIx::SecureCGI;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v3.0.0';

use DBI;
use List::Util qw( any );


## no critic (ProhibitPostfixControls Capitalization ProhibitEnumeratedClasses)

my $PRIVATE = 'private_' . __PACKAGE__;
my $INT     = qr/\A-?\d+\s+(?:SECOND|MINUTE|HOUR|DAY|MONTH|YEAR)\z/msi;
my $IDENT   = qr/((?!__)\w[a-zA-Z0-9]*(?:_(?!_)[a-zA-Z0-9]*)*)/ms;
my %Func    = ();


DefineFunc(eq => sub {
    my ($dbh, $f, $v) = @_;
    my (@val, $null, @expr);
    @val  = ref $v ? @{$v} : $v;
    $null = grep {!defined} @val;
    @val  = grep {defined} @val;
    push @expr, sprintf '%s IS NULL', $f                    if $null;
    push @expr, sprintf '%s = %s', $f, $dbh->quote($val[0]) if @val==1;
    push @expr, sprintf '%s IN (%s)',
        $f, join q{,}, map { $dbh->quote($_) } @val         if @val>1;
    push @expr, 'NOT 1'                                     if !@expr;
    return @expr==1 ? $expr[0] : '('.join(' OR ', @expr).')';
});
DefineFunc(ne => sub {
    my ($dbh, $f, $v) = @_;
    my (@val, $null, @expr);
    @val  = ref $v ? @{$v} : $v;
    $null = grep {!defined} @val;
    @val  = grep {defined} @val;
    push @expr, sprintf '%s IS NOT NULL', $f                if $null && !@val;
    push @expr, sprintf '%s IS NULL', $f                    if !$null && @val;
    push @expr, sprintf '%s != %s', $f,$dbh->quote($val[0]) if @val==1;
    push @expr, sprintf '%s NOT IN (%s)', $f,
        join q{,}, map { $dbh->quote($_) } @val             if @val>1;
    push @expr, 'NOT 0'                                     if !@expr;
    return @expr==1 ? $expr[0] : '('.join(' OR ', @expr).')';
});
DefineFunc(lt       => '%s <  %s');
DefineFunc(gt       => '%s >  %s');
DefineFunc(le       => '%s <= %s');
DefineFunc(ge       => '%s >= %s');
DefineFunc(like     => '%s LIKE %s');
DefineFunc(not_like => '%s NOT LIKE %s');
DefineFunc(date_eq  => [$INT, '%s =  DATE_ADD(NOW(), INTERVAL %s)']);
DefineFunc(date_ne  => [$INT, '%s != DATE_ADD(NOW(), INTERVAL %s)']);
DefineFunc(date_lt  => [$INT, '%s <  DATE_ADD(NOW(), INTERVAL %s)']);
DefineFunc(date_gt  => [$INT, '%s >  DATE_ADD(NOW(), INTERVAL %s)']);
DefineFunc(date_le  => [$INT, '%s <= DATE_ADD(NOW(), INTERVAL %s)']);
DefineFunc(date_ge  => [$INT, '%s >= DATE_ADD(NOW(), INTERVAL %s)']);
DefineFunc(set_date => sub {
    my ($dbh, $f, $v) = @_;
    if (uc $v eq 'NOW') {
        return sprintf '%s = NOW()', $f;
    } elsif ($v =~ /$INT/mso) {
        return sprintf '%s = DATE_ADD(NOW(), INTERVAL %s)', $f, $dbh->quote($v),
    }
    return;
});
DefineFunc(set_add  => sub {
    my ($dbh, $f, $v) = @_;
    return sprintf '%s = %s + %s', $f, $f, $dbh->quote($v);
});


sub DefineFunc {
    my ($func, $cmd) = @_;
    if (!$func || ref $func || $func !~ /\A[A-Za-z]\w*\z/ms) {
        croak "bad function name: $func";
    }
    if (!ref $cmd) {
        if (2 != (() = $cmd =~ /%s/msg)) {
            croak "bad function: $cmd";
        }
    } elsif (ref $cmd eq 'ARRAY') {
        if (2 != @{$cmd}
                || ref $cmd->[0] ne 'Regexp'
                || (ref $cmd->[1] || 2 != (() = $cmd->[1] =~ /%s/msg))) {
            croak "bad function: [@$cmd]";
        }
    } elsif (ref $cmd ne 'CODE') {
        croak 'bad function';
    }
    $Func{$func} = $cmd;
    return;
}

sub _ret {
    my $cb = shift;
    if ($cb) {
        return $cb->(@_);
    } else {
        return wantarray ? @_ : $_[0];
    }
}

sub _ret1 {
    my ($cb, $ret, $h) = @_;
    if ($cb) {
        return $cb->($ret, $h);
    } else {
        return $ret;
    }
}

sub _retdo {
    my ($dbh, $sql, $cb) = @_;
    if (!$cb) {
        return $dbh->do($sql);
    }
    return $dbh->do($sql, undef, $cb);
}

# Set cache to given HASHREF, if any.
# Initialize cache, if needed.
# Return current cache.
sub DBI::db::SecureCGICache {
    my ($dbh, $cache) = @_;
    if ($cache && ref $cache eq 'HASH') {
        $dbh->{$PRIVATE} = $cache;
    } else {
        $dbh->{$PRIVATE} //= {};
    }
    return $dbh->{$PRIVATE};
}

# Ensure $dbh->All("DESC $table") is cached.
# Return cached $dbh->All("DESC $table").
# On error set $dbh->err and return nothing.
sub DBI::db::ColumnInfo {
    my ($dbh, $table, $cb) = @_;
    my $cache = $dbh->SecureCGICache();
    if ($cache->{$table}) {
        return _ret($cb, $cache->{$table});
    }

    if (!$cb) {
        my @desc = $dbh->All('DESC '.$dbh->quote_identifier($table));
        return _set_column_info($dbh, $cache, $table, undef, @desc);
    }
    return $dbh->All('DESC '.$dbh->quote_identifier($table), sub {
        my @desc = @_;
        return _set_column_info($dbh, $cache, $table, $cb, @desc);
    });
}

sub _set_column_info {
    my ($dbh, $cache, $table, $cb, @desc) = @_;
    if (@desc) {
        my @pk = grep {$desc[$_]{Key} eq 'PRI'} 0 .. $#desc;
        if (1 != @pk || $pk[0] != 0) {
            return _ret($cb, $dbh->set_err($DBI::stderr, "first field must be primary key: $table\n", undef, 'ColumnInfo'));
        }
        $cache->{$table} = \@desc;
    }
    return _ret($cb, $cache->{$table});
}

# Ensure DESC for all $tables cached.
# Return $dbh->SecureCGICache().
# On error set $dbh->err and return nothing.
sub DBI::db::TableInfo {
    my ($dbh, $tables, $cb) = @_;
    my @tables = ref $tables eq 'ARRAY' ? @{$tables} : ($tables);
    if (!@tables || any {/\A\z|\s/ms} @tables) {
        return _ret($cb, $dbh->set_err($DBI::stderr, "bad tables: [@tables]\n", undef, 'TableInfo'));
    }

    if (!$cb) {
        while (@tables) {
            my $desc = $dbh->ColumnInfo(shift @tables);
            if (!$desc) {
                return;
            }
        }
        return $dbh->SecureCGICache();
    }
    my $code; $code = sub {
        my ($desc) = @_;
        if (!$desc) {
            undef $code;
            return $cb->();
        }
        if (@tables) {
            return $dbh->ColumnInfo(shift @tables, $code);
        }
        undef $code;
        return $cb->( $dbh->SecureCGICache() );
    };
    return $dbh->ColumnInfo(shift @tables, $code);
}

sub DBI::db::GetSQL {
    my ($dbh, $tables, $P, $cb) = @_;
    # remove possible JOIN info from table names for TableInfo()
    my @tables = map {my $s=$_;$s=~s/\s.*//ms;$s} ref $tables ? @{$tables} : $tables; ## no critic (ProhibitComplexMappings)
    if (!$cb) {
        my $cache = $dbh->TableInfo(\@tables);
        return _get_sql($dbh, $cache, $tables, $P);
    }
    return $dbh->TableInfo(\@tables, sub {
        my $cache = shift;
        return _get_sql($dbh, $cache, $tables, $P, $cb);
    });
}

sub _get_sql { ## no critic (ProhibitExcessComplexity)
    my ($dbh, $cache, $tables, $P, $cb) = @_;
    if (!$cache) {
        return _ret($cb);
    }

    # Extract JOIN type info from table names
    my (@tables, @jointype);
    for (ref $tables eq 'ARRAY' ? @{$tables} : $tables) {
        if (/\A(\S+)(?:\s+(LEFT|INNER))?\s*\z/msi) {
            push @tables, $1;
            push @jointype, $2 // 'INNER';
        }
        else {
            return _ret($cb, $dbh->set_err($DBI::stderr, "unknown join type: $_\n", undef, 'GetSQL'));
        }
    }

    my %SQL = (
        Table       => $tables[0],
        ID          => $cache->{ $tables[0] }[0]{Field},
        Select      => q{},
        From        => q{},
        Set         => q{},
        Where       => q{},
        UpdateWhere => q{},
        Order       => q{},
        Group       => q{},
        Limit       => q{},
        SelectLimit => q{},
    );

    # Detect keys which should be used for JOINing tables
    $SQL{From} = $dbh->quote_identifier($tables[0]);
    my @field = map {{ map {$_->{Field}=>1} @{ $cache->{$_} } }} @tables;   ## no critic (ProhibitComplexMappings,ProhibitVoidMap)
TABLE:
    for my $right (1..$#tables) {
        ## no critic (ProhibitAmbiguousNames)
        my $rkey = $cache->{ $tables[$right] }[0]{Field};
        for my $left (0..$right-1) {
            my $lkey = $cache->{ $tables[$left] }[0]{Field};
            my $key = $field[$left]{$rkey}  ? $rkey :
                      $field[$right]{$lkey} ? $lkey : next;
            $SQL{From} .= sprintf ' %s JOIN %s ON (%s.%s = %s.%s)',
                $jointype[$right],
                map { $dbh->quote_identifier($_) }
                $tables[$right], $tables[$right], $key, $tables[$left], $key;
            next TABLE;
        }
        return _ret($cb, $dbh->set_err($DBI::stderr, "can't join table: $tables[$right]\n", undef, 'GetSQL'));
    }

    # Set $SQL{Select} using qualified field names and without duplicates
    my %qualify;
    for my $t (@tables) {
        for my $f (map {$_->{Field}} @{ $cache->{$t} }) {
            next if $qualify{$f};
            $qualify{$f} = sprintf '%s.%s',
                map { $dbh->quote_identifier($_) } $t, $f;
            $SQL{Select} .= ', '.$qualify{$f};
        }
    }
    $SQL{Select} =~ s/\A, //ms;

    # Set $SQL{Set}, $SQL{Where}, $SQL{UpdateWhere}
    for my $k (keys %{$P}) {
        $k =~ /\A$IDENT(?:__(?!_)$IDENT)?\z/ms or next; # ignore non-field keys
        my $f   = $qualify{$1} or next;                 # ignore non-field keys
        my $func= $2 // q{};
        my $cmd = $Func{$func || 'eq'};
        if (!$cmd) {
            return _ret($cb, $dbh->set_err($DBI::stderr, "unknown function: $k\n", undef, 'GetSQL'));
        }
        if (!$func && ref $P->{$k}) {
            return _ret($cb, $dbh->set_err($DBI::stderr, "ARRAYREF without function: $k\n", undef, 'GetSQL'));
        }
        # WARNING functions `eq' and `ne' must process value array themselves:
        my $is_list = ref $P->{$k} && $func ne 'eq' && $func ne 'ne';
        for my $v ($is_list ? @{$P->{$k}} : $P->{$k}) {
            my $expr
                = ref $cmd eq 'CODE'    ? $cmd->($dbh, $f, $v)
                : ref $cmd eq 'ARRAY'   ? ($v =~ /$cmd->[0]/ms && sprintf $cmd->[1], $f, $v)
                :                         sprintf $cmd, $f, $dbh->quote($v);
            if (!$expr) {
                return _ret($cb, $dbh->set_err($DBI::stderr, "bad value for $k: $v\n", undef, 'GetSQL'));
            }
            $SQL{Set}         .= ", $expr"    if !$func || $func =~ /\Aset_/ms;
            $SQL{Where}       .= " AND $expr" if           $func !~ /\Aset_/ms;
            $SQL{UpdateWhere} .= " AND $expr" if $func &&  $func !~ /\Aset_/ms;
            $SQL{UpdateWhere} .= " AND $expr" if $k eq $SQL{ID};
        }
    }
    $SQL{Set}         =~ s/\A, //ms;
    $SQL{Where}       =~ s/\A AND //ms;
    $SQL{UpdateWhere} =~ s/\A AND //ms;
    $SQL{Set}         =~ s/\s+IS\s+NULL/ = NULL/msg;
    $SQL{Where}       ||= '1';
    $SQL{UpdateWhere} ||= '1';

    # Set $SQL{Order} and $SQL{Group}
    for my $order (ref $P->{__order} ? @{$P->{__order}} : $P->{__order}) {
        next if !defined $order;
        if ($order !~ /\A(\w+)\s*( ASC| DESC|)\z/ms || !$qualify{$1}) {
            return _ret($cb, $dbh->set_err($DBI::stderr, "bad __order value: $order\n", undef, 'GetSQL'));
        }
        $SQL{Order} .= ", $qualify{$1}$2";
    }
    for my $group (ref $P->{__group} ? @{$P->{__group}} : $P->{__group}) {
        next if !defined $group;
        if ($group !~ /\A(\w+)\s*( ASC| DESC|)\z/ms || !$qualify{$1}) {
            return _ret($cb, $dbh->set_err($DBI::stderr, "bad __group value: $group\n", undef, 'GetSQL'));
        }
        $SQL{Group} .= ", $qualify{$1}$2";
    }
    $SQL{Order} =~ s/\A, //ms;
    $SQL{Group} =~ s/\A, //ms;

    # Set $SQL{Limit}, $SQL{SelectLimit}
    my @limit = ref $P->{__limit} ? @{$P->{__limit}} : $P->{__limit} // ();
    for (grep {!m/\A\d+\z/ms} @limit) {
        return _ret($cb, $dbh->set_err($DBI::stderr, "bad __limit value: $_\n", undef, 'GetSQL'));
    }
    if (@limit == 1) {
        $SQL{Limit}       = " $limit[0]"; # make __limit=>0 true value
        $SQL{SelectLimit} = " $limit[0]"; # make __limit=>0 true value
    }
    elsif (@limit == 2) {
        $SQL{SelectLimit} = join q{,}, @limit;
    }
    elsif (@limit > 2) {
        return _ret($cb, $dbh->set_err($DBI::stderr, "too many __limit values: [@limit]\n", undef, 'GetSQL'));
    }

    return _ret($cb, \%SQL);
}

sub DBI::db::Insert {
    my ($dbh, $table, $P, $cb) = @_;
    my $SQL = $dbh->GetSQL($table, $P) or return _ret1($cb, undef, $dbh);

    my $sql = sprintf 'INSERT INTO %s SET %s',
        $dbh->quote_identifier($SQL->{Table}), $SQL->{Set};

    if (!$cb) {
        return $dbh->do($sql) ? $dbh->{mysql_insertid} : undef;
    }
    return $dbh->do($sql, undef, sub {
        my ($rv, $dbh) = @_;    ## no critic (ProhibitReusedNames)
        return $cb->(($rv ? $dbh->{mysql_insertid} : undef), $dbh);
    });
}

sub DBI::db::InsertIgnore {
    my ($dbh, $table, $P, $cb) = @_;
    my $SQL = $dbh->GetSQL($table, $P) or return _ret1($cb, undef, $dbh);

    my $sql = sprintf 'INSERT IGNORE INTO %s SET %s',
        $dbh->quote_identifier($SQL->{Table}), $SQL->{Set};
    return _retdo($dbh, $sql, $cb);
}

sub DBI::db::Update {
    my ($dbh, $table, $P, $cb) = @_;
    my $SQL = $dbh->GetSQL($table, $P) or return _ret1($cb, undef, $dbh);
    if ($SQL->{UpdateWhere} eq '1' && !$P->{__force}) {
        return _ret1($cb, $dbh->set_err($DBI::stderr, "empty WHERE require {__force=>1}\n", undef, 'Update'), $dbh);
    }

    my $sql = sprintf 'UPDATE %s SET %s WHERE %s' . ($SQL->{Limit} ? ' LIMIT %s' : q{}),
        $dbh->quote_identifier($SQL->{Table}), $SQL->{Set}, $SQL->{UpdateWhere},
        $SQL->{Limit} || ();
    return _retdo($dbh, $sql, $cb);
}

sub DBI::db::Replace {
    my ($dbh, $table, $P, $cb) = @_;
    my $SQL = $dbh->GetSQL($table, $P) or return _ret1($cb, undef, $dbh);

    my $sql = sprintf 'REPLACE INTO %s SET %s',
        $dbh->quote_identifier($SQL->{Table}), $SQL->{Set};
    return _retdo($dbh, $sql, $cb);
}

sub _find_tables_for_delete {
    my ($dbh, $fields, $tables, $P, $cb) = @_;
    if (!@{$tables}) {
        return _ret1($cb, undef, $dbh);
    }

    my $found = [];
    if (!$cb) {
        for my $t (@{$tables}) {
            my $desc = $dbh->ColumnInfo($t);
            if ($desc) {
                my @columns = map {$_->{Field}} @{$desc};
                my %seen;
                if (@{$fields} == grep {++$seen{$_}==2} @{$fields}, @columns) {
                    push @{$found}, $t;
                }
            }
        }
        return $dbh->Delete($found, $P);
    }
    my $code; $code = sub {
        my ($desc) = @_;
        my $t = shift @{$tables};
        if ($desc) {
            my @columns = map {$_->{Field}} @{$desc};
            my %seen;
            if (@{$fields} == grep {++$seen{$_}==2} @{$fields}, @columns) {
                push @{$found}, $t;
            }
        }
        if (@{$tables}) {
            return $dbh->ColumnInfo($tables->[0], $code);
        }
        undef $code;
        return $dbh->Delete($found, $P, $cb);
    };
    return $dbh->ColumnInfo($tables->[0], $code);
}

sub DBI::db::Delete { ## no critic (ProhibitExcessComplexity)
    my ($dbh, $table, $P, $cb) = @_;

    if (!defined $table) {
        my %fields = map {/\A$IDENT(?:__(?!_)$IDENT)?\z/ms ? ($1=>1) : ()} keys %{$P};
        my @fields = keys %fields;
        if (!@fields) {
            return _ret1($cb, $dbh->set_err($DBI::stderr, "table undefined, require params\n", undef, 'Delete'), $dbh);
        }
        if (!$cb) {
            return _find_tables_for_delete($dbh, \@fields, [$dbh->Col('SHOW TABLES')], $P);
        }
        return $dbh->Col('SHOW TABLES', sub {
            my (@tables) = @_;
            return _find_tables_for_delete($dbh, \@fields, \@tables, $P, $cb);
        });
    }

    my @tables = ref $table ? @{$table} : $table;
    if (!$cb) {
        my $res;
        for my $t (@tables) {
            my $SQL = $dbh->GetSQL($t, $P) or return;
            if ($SQL->{Where} eq '1' && !$P->{__force}) {
                return $dbh->set_err($DBI::stderr, "empty WHERE require {__force=>1}\n", undef, 'Delete');
            }
            my $sql = sprintf 'DELETE FROM %s WHERE %s' . ($SQL->{Limit} ? ' LIMIT %s' : q{}),
                $dbh->quote_identifier($SQL->{Table}), $SQL->{Where}, $SQL->{Limit} || ();
            $res = $dbh->do($sql) or return;
        }
        return $res;
    }
    my $code; $code = sub {
        my ($SQL) = @_;
        my $t = shift @tables;
        if (!$SQL) {
            undef $code;
            return $cb->(undef, $dbh);
        }
        if ($SQL->{Where} eq '1' && !$P->{__force}) {
            undef $code;
            return $cb->($dbh->set_err($DBI::stderr, "empty WHERE require {__force=>1}\n", undef, 'Delete'), $dbh);
        }
        my $sql = sprintf 'DELETE FROM %s WHERE %s' . ($SQL->{Limit} ? ' LIMIT %s' : q{}),
            $dbh->quote_identifier($SQL->{Table}), $SQL->{Where}, $SQL->{Limit} || ();
        $dbh->do($sql, sub {
            my ($res, $dbh) = @_;   ## no critic (ProhibitReusedNames)
            if ($res && @tables) {
                return $dbh->GetSQL($tables[0], $P, $code);
            }
            undef $code;
            return $cb->($res, $dbh);
        });
    };
    return $dbh->GetSQL($tables[0], $P, $code);
}

sub DBI::db::ID {
    my ($dbh, $table, $P, $cb) = @_;
    my $SQL = $dbh->GetSQL($table, $P) or return _ret1($cb, undef, $dbh);

    my $sql = sprintf 'SELECT %s.%s FROM %s WHERE %s'
        . ($SQL->{Order}        ? ' ORDER BY %s' : q{})
        . ($SQL->{SelectLimit}  ? ' LIMIT %s' : q{}),
        (map { $dbh->quote_identifier($_) } $SQL->{Table}, $SQL->{ID}),
        $SQL->{From}, $SQL->{Where}, $SQL->{Order} || (), $SQL->{SelectLimit} || ();
    return $dbh->Col($sql, $cb // ());
}

sub DBI::db::Count {
    my ($dbh, $table, $P, $cb) = @_;
    my $SQL = $dbh->GetSQL($table, $P) or return _ret1($cb, undef, $dbh);

    my $sql = sprintf 'SELECT count(*) __count FROM %s WHERE %s',
        $SQL->{From}, $SQL->{Where};
    return $dbh->Col($sql, $cb // ());
}

sub DBI::db::Select {
    my ($dbh, $table, $P, $cb) = @_;
    my $SQL = $dbh->GetSQL($table, $P) or return _ret1($cb, undef, $dbh);

    my $sql = sprintf 'SELECT %s'
        . ($SQL->{Group} ? ', count(*) __count' : q{})
        . ' FROM %s WHERE %s'
        . ($SQL->{Group}        ? ' GROUP BY %s' : q{})
        . ($SQL->{Order}        ? ' ORDER BY %s' : q{})
        . ($SQL->{SelectLimit}  ? ' LIMIT %s'    : q{}),
        $SQL->{Select}, $SQL->{From}, $SQL->{Where},
        $SQL->{Group} || (), $SQL->{Order} || (), $SQL->{SelectLimit} || ();
    if (!$cb) {
        return wantarray ? $dbh->All($sql) : $dbh->Row($sql);
    }
    return $dbh->All($sql, $cb);
}

sub _is_cb {
    my $cb = shift;
    my $ref = ref $cb;
    return $ref eq 'CODE' || $ref eq 'AnyEvent::CondVar';
}

sub DBI::db::All {
    my ($dbh, $sql, @bind) = @_;
    my $cb = @bind && _is_cb($bind[-1]) ? pop @bind : undef;
    if (!$cb) {
        (my $sth = $dbh->prepare($sql, {async=>0}))->execute(@bind) or return;
        return @{ $sth->fetchall_arrayref({}) };
    }
    return $dbh->prepare($sql)->execute(@bind, sub {
        my ($rv, $sth) = @_;
        return $cb->(!$rv ? () : @{ $sth->fetchall_arrayref({}) });
    });
}

sub DBI::db::Row {
    my ($dbh, $sql, @bind) = @_;
    return $dbh->selectrow_hashref($sql, undef, @bind);
}

sub DBI::db::Col {
    my ($dbh, $sql, @bind) = @_;
    my $cb = @bind && _is_cb($bind[-1]) ? pop @bind : undef;
    if (!$cb) {
        my @res = @{ $dbh->selectcol_arrayref($sql, undef, @bind) || [] };
        return wantarray ? @res : $res[0];
    }
    return $dbh->selectcol_arrayref($sql, undef, @bind, sub {
        my ($ary_ref) = @_;
        return $cb->($ary_ref ? @{ $ary_ref } : ());
    });
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

DBIx::SecureCGI - Secure conversion of CGI params hash to SQL


=head1 VERSION

This document describes DBIx::SecureCGI version v3.0.0


=head1 SYNOPSIS

 #--- sync

 use DBIx::SecureCGI;

 $row   = $dbh->Select('Table',             \%Q);
 @rows  = $dbh->Select(['Table1','Table2'], {%Q, id_user=>$id});
 $count = $dbh->Count('Table',        {age__gt=>25});
 $id    = $dbh->ID('Table',           {login=>$login, pass=>$pass});
 @id    = $dbh->ID('Table',           {age__gt=>25});
 $newid = $dbh->Insert('Table',       \%Q);
 $rv    = $dbh->InsertIgnore('Table', \%Q);
 $rv    = $dbh->Update('Table',       \%Q);
 $rv    = $dbh->Replace('Table',      \%Q);
 $rv    = $dbh->Delete('Table',       \%Q);
 $rv    = $dbh->Delete(undef,         {id_user=>$id});

 @rows  = $dbh->All('SELECT * FROM Table WHERE id_user=?', $id);
 $row   = $dbh->Row('SELECT * FROM Table WHERE id_user=?', $id);
 @col   = $dbh->Col('SELECT id_user FROM Table');

 $SQL   = $dbh->GetSQL(['Table1','Table2'], \%Q);
 $cache = $dbh->TableInfo(['Table1','Table2']);
 $desc  = $dbh->ColumnInfo('Table');


 #--- async

 use AnyEvent::DBI::MySQL;
 use DBIx::SecureCGI;

 $dbh->Select(…,       sub { my (@rows)        = @_; … });
 $dbh->Count(…,        sub { my ($count)       = @_; … });
 $dbh->ID(…,           sub { my (@id)          = @_; … });
 $dbh->Insert(…,       sub { my ($newid, $dbh) = @_; … });
 $dbh->InsertIgnore(…, sub { my ($rv, $dbh)    = @_; … });
 $dbh->Update(…,       sub { my ($rv, $dbh)    = @_; … });
 $dbh->Replace(…,      sub { my ($rv, $dbh)    = @_; … });
 $dbh->Delete(…,       sub { my ($rv, $dbh)    = @_; … });

 $dbh->All(…, sub { my (@rows) = @_; … });
 $dbh->Row(…, sub { my ($row)  = @_; … });
 $dbh->Col(…, sub { my (@col)  = @_; … });

 $dbh->GetSQL(…,     sub { my ($SQL)   = @_; … });
 $dbh->TableInfo(…,  sub { my ($cache) = @_; … });
 $dbh->ColumnInfo(…, sub { my ($desc)  = @_; … });


 #--- setup

 DBIx::SecureCGI::DefineFunc( $name, '%s op %s' )
 DBIx::SecureCGI::DefineFunc( $name, [ qr/regexp/, '%s op %s' ] )
 DBIx::SecureCGI::DefineFunc( $name, sub { … } )

 $cache = $dbh->SecureCGICache();
 $dbh->SecureCGICache($new_cache);


=head1 DESCRIPTION

This module let you use B<hash with CGI params> to make (or just generate)
SQL queries to MySQL database in B<easy and secure> way. To make this
magic possible there are some limitations and requirements:

=over

=item * Your app and db scheme must conform to these L</"CONVENTIONS">

=item * Small speed penalty/extra queries to load scheme from db

=item * No support for advanced SQL, only basic queries

=back

Example: if all CGI params (including unrelated to db table 'Table') are
in C<%Q>, then:

 @rows = $dbh->Select('Table', \%Q);

will execute any simple C<SELECT> query from the table C<Table> (defined
by user-supplied parameters in C<%Q>); and this:

 @user_rows = $dbh->Select('Table', {%Q, id_user=>$id});

will make any similar query limited to records with C<id_user> column
value C<$id> (thus allowing user to fetch any or B<his own> records).

The module is intended for use only with a fairly simple tables and simple
SQL queries. More advanced queries usually can be generated manually with
help of L</GetSQL> or you can just use plain L<DBI> methods.

Also it support B<non-blocking SQL queries> using L<AnyEvent::DBI::MySQL>
and thus can be effectively used with event-based CGI frameworks like
L<Mojolicious> or with event-based FastCGI servers like L<FCGI::EV>.

Finally, it can be used in non-CGI environment, as simplified interface to
L<DBI>.

=head2 SECURITY OVERVIEW

At a glance, generating SQL queries based on untrusted parameters sent by
user to your CGI looks very unsafe. But interface of this module designed
to make it safe - while you conform to some L</CONVENTIONS> and follow
some simple guidelines.

=over

=item * B<User have no control over query type (SELECT/INSERT/…)>

It's defined by method name you call.

=item * B<User have no control over tables involved in SQL query>

It's defined by separate (first) parameter in all methods, unrelated to
hash with CGI parameters.

=item * B<User have no direct control over SQL query>

All values from hash are either quoted before inserting into SQL, or
checked using very strict regular expressions if it's impossible to quote
them (like for date/time C<INTERVAL> values).

=item * B<You can block/control access to "secure" fields in all tables>

Name all such fields in some special way (like beginning with "C<_>") and
when receiving CGI parameters immediately B<delete all keys> in hash which
match these fields (i.e. all keys beginning with "C<_>"). Later you can
analyse user's request and manually add to hash keys for these fields
before call method to execute SQL query.

=item * B<You can limit user's access to some subset of records>

Just instead of using plain C<\%Q> as parameter for methods use
something like C<< { %Q, id_user => $id } >> - this way user will be
limited to records with C<$id> value in C<id_user> column.

=back

Within these security limitations user can do anything - select records
with custom C<WHERE>, C<GROUP BY>, C<ORDER BY>, C<LIMIT>; set any values
(allowed by table scheme, of course) for any fields on C<INSERT> or
C<UPDATE>; etc. without any single line of your code - exclusively by
using different CGI parameters.


=head1 HOW IT WORKS

Each CGI parameter belongs to one of three categories:

=over

=item * B<related to some table's field in db:> C<fieldname>,
C<fieldname__funcname>

=item * B<control command:> C<__commandname>

=item * B<your app's parameter>

=back

It's recommended to name fields in db beginning with B<lowercase> letter
or B<underscore>, and name your app's parameters beginning with
B<Uppercase> letter to avoid occasional clash with field name.

To protect some fields (like "C<balance>" or "C<privileges>") from
uncontrolled access you can use simple convention: name these fields in db
beginning with "C<_>"; when receiving CGI params just
B<delete all with names beginning with> "C<_>" - thus it won't be possible
to access these fields from CGI params. This module doesn't know about
these protected fields and handle them just as usual fields. So, you
should later add needed keys for these fields into hash before calling
methods to execute SQL query. This way all operations on these fields will
be controlled by your app.

You can use any other similar naming scheme which won't conflict with
L</CONVENTIONS> below - DBIx::SecureCGI will analyse db scheme (and
cache it for speed) to detect which keys match field names.

CGI params may have several values. In hash, keys for such params must
have C<ARRAYREF> value. DBIx::SecureCGI support this only for keys which
contain "C<__>" (double underscore). Depending on used CGI framework you
may need to convert existing CGI parameters into this format.

Error handling: all unknown keys will be silently ignored, all other
errors (unable to detect key for joining table, field without
"C<__funcname>" have C<ARRAYREF> value, unknown "C<__funcname>" function, etc.)
will return usual DBI errors (or throw exceptions when C<< {RaiseError=>1} >>.

=head2 CONVENTIONS

=over

=item *

Each table's B<first field> must be a C<PRIMARY KEY>.

=over

MOTIVATION: This module use simplified analyse of db scheme and suppose
first field in every table is a C<PRIMARY KEY>. To add support for complex
primary keys or tables without primary keys we should first define how
L</ID> should handle them and how to automatically join such tables.

=back

=item *

Two tables are always C<JOIN>ed using field which must be C<PRIMARY KEY>
at least in one of them and have B<same name in both tables>.

=over

So, don't name your primary key "C<id>" if you plan to join this table with
another - name it like "C<id_thistable>" or "C<thistableId>".

=back

If both tables have field corresponding to C<PRIMARY KEY> in other table,
then key field of B<right table> (in order defined when you make array of
tables in first param of method) will be used.

If more than two tables C<JOIN>ed, then each table starting from second
one will try to join to each of the previous tables (starting at first
table) until it find table with suitable field. If it wasn't found
DBI error will be returned.

=over

MOTIVATION: Let this module automatically join tables.

=back

=item *

Field names must not contain "C<__>" (two adjoined underscore).

=over

MOTIVATION: Distinguish special commands for this module from field names.
Also, some methods sometimes create aliases for fields and their names
begins with "C<__>".

=back

=item *

Hash with CGI params may contain several values (as C<ARRAYREF>) only for key
names containing "C<__>" (keys unrelated to fields may have any values).

=over

MOTIVATION: Allowing C<< { field => \@values } >> introduce many
ambiguities and in fact same as C<< { field__eq => \@values } >>,
so it's safer to deny it.

=back

=back

=head2 Hash to SQL conversion rules

=head3 __commandname

Keys beginning with "C<__>" are control commands. Supported commands are:

=over

=item B<__order>

Define value for C<ORDER BY>. Valid values are:

 'field_name'
 'field_name ASC'
 'field_name DESC'

Multiple values can be given as C<ARRAYREF>.

=item B<__group>

Define value for C<GROUP BY>. Valid values are same as for B<__order>.

=item B<__limit>

Can have up to two numeric values (when it's C<ARRAYREF>), set C<LIMIT>.

=item B<__force>

If the value of B<__force> key is true, then it's allowed to run
L</Update> and L</Delete> with an empty C<WHERE>. (This isn't a security
feature, it's just for convenience to protect against occasional damage on
database while playing with CGI parameters.)

=back

Examples:

 my @rows = $dbh->Select('Table', {
    age__ge => 20,
    age__lt => 30,
    __group => 'age',
    __order => ['age DESC', 'fname'],
    __limit => 5,
 });
 $dbh->Delete('Table', { __force => 1 });

=head3 fieldname__funcname

If the key contains a "C<__>" then it is treated as applying function
"C<funcname>" to field "C<fieldname>".
If the there is no field with such name in database, this key is ignored.
A valid key value - string/number or a reference to an array of
strings/numbers.
A list of available functions in this version is shown below.

Unless special behavior mentioned functions handle C<ARRAYREF> value by
applying itself to each value in array and joining with C<AND>.

Example:

 { html__like => ['%<P>%', '%<BR>%'] }

will be transformed in SQL to

 html LIKE '%<P>%' AND html LIKE '%<BR>%'

Typically, such keys are used in C<WHERE>, except when "C<funcname>" begins
with "C<set_>" - such keys will be used in C<SET>.

=head3 fieldname

Other keys are treated as names of fields in database.
If there is no field with such name, then key is ignored.
A valid value for these keys - scalar.

Example:

 { name => 'Alex' }
 
will be transformed in SQL to

 name = 'Alex'

Typically, such keys are used in part C<SET>, except for C<PRIMARY KEY>
field in L</Update> - it will be used in C<WHERE>.


=head1 INTERFACE

=head2 Functions

=head3 DefineFunc

 DBIx::SecureCGI::DefineFunc( $name, '%s op %s' );
 DBIx::SecureCGI::DefineFunc( $name, [ qr/regexp/, '%s op %s' ] );
 DBIx::SecureCGI::DefineFunc( $name, sub { … } );

Define new or replace existing function applied to fields after "C<__>"
delimiter.

SQL expression for that function will be generated in different ways,
depending on how you defined that function - using string, regexp+string
or code:

 $expr = sprintf '%s op %s', $field, $dbh->quote($value);
 $expr = $value =~ /regexp/ && sprintf '%s op %s', $field, $value;
 $expr = $code->($dbh, $field, $value);

If C<$expr> will be false DBI error will be returned.
Here is example of code implementation:

 sub {
     my ($dbh, $f, $v) = @_;
     if (… value ok …) {
         return sprintf '…', $f, $dbh->quote($v);
     }
     return;     # wrong value
 }


=head2 Methods injected into DBI

=head3 GetSQL

 $SQL = $dbh->GetSQL( $table,   \%Q );
        $dbh->GetSQL( $table,   \%Q, sub { my ($SQL) = @_; … } );
 $SQL = $dbh->GetSQL( \@tables, \%Q );
        $dbh->GetSQL( \@tables, \%Q, sub { my ($SQL) = @_; … } );

This is helper function which will analyse (cached) database scheme for
given tables and generate elements of SQL query for given keys in C<%Q>.
You may use it to write own methods like L</Select> or L</Insert>.

In C<%Q> keys which doesn't match field names in C<$table> / C<@tables>
are ignored.

Names of tables and fields in all keys (except C<{Table}> and C<{ID}>)
are already quoted, field names qualified with table name (so they're
ready for inserting into SQL query). Values of C<{Table}> and C<{ID}>
should be escaped with C<< $dbh->quote_identifier() >> before using in SQL
query.

Returns C<HASHREF> with keys:

 {Table}        first of the used tables
 {ID}           name of PRIMARY KEY field in {Table}
 {Select}       list of all field names which should be returned by
                'SELECT *' excluding duplicated fields (when field with
                same name exist in many tables only field from first table
                will be returned); field names in {Select} are joined with ","
 {From}         all tables joined using chosen JOIN type (INNER by default)
 {Set}          string like "field=value, field2=value2" for all simple
                "fieldname" keys in %Q
 {Where}        a-la {Set}, except fields joined using "AND" and added
                "field__function" fields; if there are no fields it will
                be set to string "1"
 {UpdateWhere}  a-la {Where}, except it uses only "field__function" keys
                plus one PRIMARY KEY "fieldname" key (if it exists in %Q)
 {Order}        string like "field1 ASC, field2 DESC" or empty string
 {Group}        a-la {Order}
 {Limit}        set to value of __limit if it contain one number
 {SelectLimit}  set to value of __limit if it contain one number,
                or to values of __limit joined with "," if it contain
                two numbers

Example :

 CREATE TABLE A (
    id_a    INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    i       INT NOT NULL
 );
 CREATE TABLE B (
    id_b    INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_a    INT NOT NULL,
    s       VARCHAR(255) NOT NULL
 );

 $SQL = $dbh->GetSQL(['A', 'B LEFT'], {
    id_a        => 3,
    i           => 10,
    s           => 'str',
    id_b__gt    => 5,
    __group     => 'i',
    __order     => ['s DESC', 'i'],
    __limit     => [50,10],
 });

 # now %$SQL have these values:
 # (backticks added by $dbh->quote_identifier() around all table/field
 # names omitted for readability)
 Table       => 'A'
 ID          => 'id_a'
 Select      => 'A.id_a, A.i, B.id_b, B.s'
 From        => 'A LEFT JOIN B ON (B.id_a = A.id_a)'
 Set         => 'B.s = "str",    A.id_a = 3,    A.i = 10'
 Where       => 'B.s = "str" AND A.id_a = 3 AND A.i = 10 AND B.id_b > 5'
 UpdateWhere => '                A.id_a = 3              AND B.id_b > 5'
 Group       => 'A.i'
 Order       => 'B.s DESC, A.i'
 Limit       => ''
 SelectLimit => '50,10'


=head3 Insert

 $newid = $dbh->Insert( $table, \%Q );
          $dbh->Insert( $table, \%Q, sub { my ($newid, $dbh) = @_; … } );

Execute SQL query:

    INSERT INTO {Table} SET {Set}

Return C<< $dbh->{mysql_insertid} >> on success or C<undef> on error.

It's B<strongly recommended> to always use

 $dbh->Insert( …, { %Q, …, primary_key_name=>undef }, … )

because if you didn't force C<primary_key> field to be C<NULL> in SQL (and
thus use C<AUTO_INCREMENT> value) then user may send CGI parameter to set
it to C<-1> or C<4294967295> and this will result in B<DoS> because no
more records can be added using C<AUTO_INCREMENT> into this table.


=head3 InsertIgnore

 $rv = $dbh->InsertIgnore( $table, \%Q );
       $dbh->InsertIgnore( $table, \%Q, sub { my ($rv, $dbh) = @_; … } );

Execute SQL query:

    INSERT IGNORE INTO {Table} SET {Set}

Return C<$rv> (true on success or C<undef> on error).


=head3 Update

 $rv = $dbh->Update( $table, \%Q );
       $dbh->Update( $table, \%Q, sub { my ($rv, $dbh) = @_; … } );

Execute SQL query:

    UPDATE {Table} SET {Set} WHERE {UpdateWhere} [LIMIT {Limit}]

Uses in C<SET> part all fields given as "C<fieldname>", in C<WHERE> part all
fields given as "C<fieldname__funcname>" plus C<PRIMARY KEY> field if it was
given as "C<fieldname>".

Return C<$rv> (amount of modified records on success or C<undef> on error).

To use with empty C<WHERE> part require C<< {__force=>1} >> in C<%Q>.


=head3 Replace

 $rv = $dbh->Replace( $table, \%Q );
       $dbh->Replace( $table, \%Q, sub { my ($rv, $dbh) = @_; … } );

Execute SQL query:

    REPLACE INTO {Table} SET {Set}

Uses in C<SET> part all fields given as "C<fieldname>".

Return C<$rv> (true on success or C<undef> on error).


=head3 Delete

 $rv = $dbh->Delete( $table,   \%Q );
       $dbh->Delete( $table,   \%Q, sub { my ($rv, $dbh) = @_; … } );
 $rv = $dbh->Delete( \@tables, \%Q );
       $dbh->Delete( \@tables, \%Q, sub { my ($rv, $dbh) = @_; … } );
 $rv = $dbh->Delete( undef,    \%Q );
       $dbh->Delete( undef,    \%Q, sub { my ($rv, $dbh) = @_; … } );

Execute SQL query:

    DELETE FROM {Table} WHERE {Where} [LIMIT {Limit}]

Delete records from C<$table> or (one-by-one) from each table in
C<@tables>. If C<undef> given, then delete records from B<ALL> tables
(except C<TEMPORARY>) which have B<ALL> fields mentioned in C<%Q>.

To use with empty C<WHERE> part require C<< {__force=>1} >> in C<%Q>.

Return C<$rv> (amount of deleted records or C<undef> on error).
If used to delete records from more than one table - return C<$rv>
for last table. If error happens it will be immediately returned,
so some tables may not be processed in this case.


=head3 ID

 $id = $dbh->ID( $table,   \%Q );
 @id = $dbh->ID( $table,   \%Q );
       $dbh->ID( $table,   \%Q, sub { my (@id) = @_; … } );
 $id = $dbh->ID( \@tables, \%Q );
 @id = $dbh->ID( \@tables, \%Q );
       $dbh->ID( \@tables, \%Q, sub { my (@id) = @_; … } );

Return result of executing this SQL query using L</Col>:

    SELECT {ID} FROM {From} WHERE {Where}
        [ORDER BY {Order}] [LIMIT {SelectLimit}]


=head3 Count

 $count = $dbh->Count( $table,   \%Q );
          $dbh->Count( $table,   \%Q, sub { my ($count) = @_; … } );
 $count = $dbh->Count( \@tables, \%Q );
          $dbh->Count( \@tables, \%Q, sub { my ($count) = @_; … } );

Return result of executing this SQL query using L</Col>:

    SELECT count(*) __count FROM {From} WHERE {Where}


=head3 Select

 $row  = $dbh->Select( $table,   \%Q );
 @rows = $dbh->Select( $table,   \%Q );
         $dbh->Select( $table,   \%Q, sub { my (@rows) = @_; … } );
 $row  = $dbh->Select( \@tables, \%Q );
 @rows = $dbh->Select( \@tables, \%Q );
         $dbh->Select( \@tables, \%Q, sub { my (@rows) = @_; … } );

Execute one of these SQL queries (depending on using C<__group> command):

    SELECT * FROM {From} WHERE {Where}
        [ORDER BY {Order}] [LIMIT {SelectLimit}]
    SELECT *, count(*) __count FROM {From} WHERE {Where} GROUP BY {Group}
        [ORDER BY {Order}] [LIMIT {SelectLimit}]

Instead of C<SELECT *> it uses enumeration of all fields qualified using
table name; if same field found in several tables it's included only
one - from first table having that field.

In C<@tables> you can append C<' LEFT'> or C<' INNER'> to table name to
choose C<JOIN> variant (by default C<INNER JOIN> will be used):

 $dbh->Select(['TableA', 'TableB LEFT', 'TableC'], …)

Return result of executing SQL query using L</All> when called in list
context or L</Row> when called in scalar context.


=head3 All

 @rows = $dbh->All( $sql, @bind )
         $dbh->All( $sql, @bind, sub { my (@rows) = @_; … } );

Shortcut for this ugly but very useful snippet:

 @{ $dbh->selectall_arrayref($sql, {Slice=>{}}, @bind) }


=head3 Row

 $row = $dbh->Row( $sql, @bind );
        $dbh->Row( $sql, @bind, sub { my ($row) = @_; … } );

Shortcut for:

 $dbh->selectrow_hashref($sql, undef, @bind)

If you wonder why it exists, the answer is simple: it was added circa
2002, when there was no C<< $dbh->selectrow_hashref() >> and now it
continue to exists for compatibility and to complement L</All>
and L</Col>.


=head3 Col

 $col = $dbh->Col( $sql, @bind );
 @col = $dbh->Col( $sql, @bind );
        $dbh->Col( $sql, @bind, sub { my (@col) = @_; … } );

Shortcut for:

 $col = $dbh->selectcol_arrayref($sql, undef, @bind)->[0];
 @col = @{ $dbh->selectcol_arrayref($sql, undef, @bind) };


=head3 SecureCGICache

 $cache = $dbh->SecureCGICache();
 $cache = $dbh->SecureCGICache( $new_cache );

Fetch (or set when C<$new_cache> given) C<HASHREF> with cached results of
"C<DESC tablename>" SQL queries for all tables used previous in any methods.

You may need to reset cache (by using C<{}> as C<$new_cache> value) if
you've changed scheme for tables already accessed by any method or if you
changed current database.

Also in some environments when many different C<$dbh> used simultaneously,
connected to same database (like in event-based environments) it may make
sense to share same cache for all C<$dbh>.


=head3 TableInfo

 $cache = $dbh->TableInfo( $table );
          $dbh->TableInfo( $table,   sub { my ($cache) = @_; … } );
 $cache = $dbh->TableInfo( \@tables );
          $dbh->TableInfo( \@tables, sub { my ($cache) = @_; … } );

Ensure "C<DESC tablename>" for all C<$table> / C<@tables> is cached.

Return same as L</SecureCGICache> on success or C<undef> on error.


=head3 ColumnInfo

 $desc = $dbh->ColumnInfo( $table );
         $dbh->ColumnInfo( $table, sub { my ($desc) = @_; … } );

Ensure "C<DESC $table>" is cached.

Return result of C<< $dbh->All("DESC $table") >> on success or C<undef> on
error.


=head2 __funcname functions for fields

These functions can be added and replaced using L</DefineFunc>.

Functions which can be used in C<%Q> as "C<fieldname_funcname>":

=head3 eq, ne, lt, gt, le, ge

 field =  value     field IS NULL
 field != value     field IS NOT NULL
 field <  value
 field >  value
 field <= value
 field >= value

For functions B<eq> or B<ne>:

 eq []            - NOT 1
 ne []            - NOT 0
 eq only    undef - name IS NULL
 ne only    undef - name IS NOT NULL
 eq without undef - name IN (...)
 ne without undef - (name IS NULL OR name NOT IN (...))
 eq with    undef - (name IS NULL OR name IN (...))
 ne with    undef - name NOT IN (...)

where

 "[]"           : name__func=>[]
 "only    undef": name__func=>undef    or name__func=>[undef]
 "without undef": name__func=>$defined or name__func=>[@defined]
 "with    undef": name__func=>[@defined_and_not_defined]

=head3 like, not_like

 field LIKE value
 field NOT LIKE value

=head3 date_eq, date_ne, date_lt, date_gt, date_le, date_ge

 field =  DATE_ADD(NOW(), INTERVAL value)
 field != DATE_ADD(NOW(), INTERVAL value)
 field <  DATE_ADD(NOW(), INTERVAL value)
 field >  DATE_ADD(NOW(), INTERVAL value)
 field <= DATE_ADD(NOW(), INTERVAL value)
 field >= DATE_ADD(NOW(), INTERVAL value)

value must match:

 /^-?\d+ (?:SECOND|MINUTE|HOUR|DAY|MONTH|YEAR)$/

=head3 set_add

 field = field + value

When used in L</Update> it will be in C<SET> instead of C<WHERE>.
It doesn't make sense to use this function with L</Insert>,
L</InsertIgnore> or L</Replace>.

=head3 set_date

 field = NOW()
 field = DATE_ADD(NOW(), INTERVAL value)

If it's value is (case-insensitive) string C<'NOW'> then it'll use
C<NOW()> else it will use C<DATE_ADD(…)>.

When used in L</Insert>, L</InsertIgnore>, L</Update> and L</Replace> it
will be in C<SET>.


=head1 LIMITATIONS

Only MySQL supported.

It's impossible to change C<PRIMARY KEY> using L</Update> with:

 { id => $new_id, id__eq => $old_id }

because both "C<id>" and "C<id__eq>" will be in C<WHERE> part:

 SET id = $new_id WHERE id = $new_id AND id = $old_id

and if we won't add C<< 'id => $new_id' >> in C<WHERE> part if we have
C< 'id__eq' >, then we'll have do use this

 $dbh->Func($table, {%Q, id_user=>$S{id_user}, id_user__eq=>$S{id_user})

in B<all> CGI requests to protect against attempt to read someone else's
records or change own records's id_user field by using C<'id_user'>
or C<'id_user__eq'> CGI params.


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-DBIx-SecureCGI/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-DBIx-SecureCGI>

    git clone https://github.com/powerman/perl-DBIx-SecureCGI.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=DBIx-SecureCGI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/DBIx-SecureCGI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-SecureCGI>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=DBIx-SecureCGI>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/DBIx-SecureCGI>

=back


=head1 AUTHORS

Alex Efros E<lt>powerman@cpan.orgE<gt>

Nikita Savin E<lt>asdfgroup@gmail.comE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2002-2014 by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
