package DBIx::MoCo::DataBase;
use strict;
use warnings;
use Carp;
use base qw (Class::Data::Inheritable);
use DBI;
use SQL::Abstract;

__PACKAGE__->mk_classdata($_) for qw(username password
                                     cache_connection last_insert_id);
__PACKAGE__->cache_connection(1);

our $DEBUG = 0;
our $SQL_COUNT = 0;

# $Carp::CarpLevel = 2;
my $sqla = SQL::Abstract->new;

sub insert {
    my $class = shift;
    my ($table, $args) = @_;
    my ($sql, @binds) = $sqla->insert($table,$args);
    $class->execute($sql,undef,\@binds);
}

sub delete {
    my $class = shift;
    my ($table, $where) = @_;
    $where or croak "where is not specified to delete from $table";
    (ref $where eq 'HASH' && %$where) or croak "where is not specified to delete from $table";
    my ($sql, @binds) = $sqla->delete($table,$where);
    $sql =~ /WHERE/io or croak "where is not specified to delete from $table";
    $class->execute($sql,undef,\@binds);
}

sub update {
    my $class = shift;
    my ($table, $args, $where) = @_;
    $where or croak "where is not specified to update $table";
    (ref $where eq 'HASH' && %$where) or croak "where is not specified to update $table";
    my ($sql, @binds) = $sqla->update($table,$args,$where);
    $sql =~ /WHERE/io or croak "where is not specified to update $table";
    $class->execute($sql,undef,\@binds);
}

sub select {
    my $class = shift;
    my ($table, $args, $where, $order, $limit) = @_;
    my ($sql, @binds) = $sqla->select($table,$args,$where,$order);
    $sql .= $class->_parse_limit($limit) if $limit;
    my $data;
    $class->execute($sql,\$data,\@binds) or return;
    return $data;
}

sub search {
    my $class = shift;
    my %args = @_;
    my ($sql, @binds) = $class->_search_sql(\%args);
    my $data;
    $class->execute($sql,\$data,\@binds) or return;
    return $data;
}

sub _search_sql {
    my $class = shift;
    my $args = shift;
    my $field = $args->{field} || "*";
    my $sql = "SELECT $field FROM " . $args->{table};
    $sql .= " USE INDEX ($args->{use_index})" if $args->{use_index};
    my ($where,@binds) = $class->_parse_where($args->{where});
    $sql .= $where if $where;
    $sql .= " GROUP BY $args->{group}" if $args->{group};
    $sql .= " ORDER BY $args->{order}" if $args->{order};
    $sql .= $class->_parse_limit($args);
    return ($sql,@binds);
}

sub _parse_where {
    my ($class, $where) = @_;
    my $binds = [];
    if (ref $where eq 'ARRAY') {
        my $sql = shift @$where;
        if ($sql =~ m!\s*:[A-Za-z_][A-Za-z0-9_]+\s*!o) {
            @$where % 2 and croak "You gave me an odd number of parameters to 'where'!";
            my %named_values = @$where;
            my @values;
            $sql =~ s{:([A-Za-z_][A-Za-z0-9_]*)}{
                croak "$1 is not exists in hash" if !exists $named_values{$1};
                my $value = $named_values{$1};
                if (ref $value eq 'ARRAY') {
                    push @values, $_ for @$value;
                    join ',', map('?', 1..@$value);
                } else {
                    push @values, $value;
                    '?'
                }
            }ge;
            $binds = \@values;
        } else {
            $binds = $where;
        }
        return (' WHERE ' . $sql, @$binds);
    } elsif (ref $where eq 'HASH') {
        return $sqla->where($where);
    } elsif ($where) {
        return ' WHERE ' . $where;
    }
    return $where;
}

sub _parse_limit {
    my ($class, $args) = @_;
    my $sql = '';
    if ($args->{offset} || $args->{limit}) {
        $sql .= " LIMIT ";
        if ($args->{offset} && $args->{offset} =~ m/^\d+$/o) {
            $sql .= $args->{offset}.",";
        }
        $sql .= $args->{limit} =~ /^\d+$/o ? $args->{limit} : '1';
    }
    return $sql;
}

sub dsn {
    my $class = shift;
    my ($master_dsn, $slave_dsn);
    if ($_[0] && ref($_[0]) eq 'HASH') {
        @_ = (%{$_[0]});
    }
    if ($_[1]) {
        my %args = @_;
        my $master = $args{master} or croak "master dsn is not specified";
        $master_dsn = ref($master) eq 'ARRAY' ? $master : [$master];
        my $slave = $args{slave} || $master;
        $slave_dsn = ref($slave) eq 'ARRAY' ? $slave : [$slave];
    } elsif ($_[0]) {
        $slave_dsn = $master_dsn = ref($_[0]) eq 'ARRAY' ? $_[0] : [$_[0]];
    } else {
        croak "Please specify your dsn.";
    }
#     $dsn->{$class} = {
#         master => $master_dsn,
#         slave => $slave_dsn,
#     };
    my $getter = $class . '::get_dsn';
    {
        no strict 'refs';
        no warnings 'redefine';
        *{$getter} = sub {
            my $class = shift;
            my $sql = shift;
            my $list = $master_dsn;
            if ($sql && $sql =~ /^SELECT/io) { $list = $slave_dsn }
            my $dsn = shift @$list;
            push @$list, $dsn;
            return $dsn;
        }
    }
}

sub get_dsn { croak "You must set up your dsn first" }

sub dbh {
    my $class = shift;
    my $sql = shift;
    my $connect = $class->cache_connection ? 'connect_cached' : 'connect';
    my $dsn = $class->get_dsn($sql);
    my $opt = {RaiseError => 1};
    DBI->$connect($dsn, $class->username, $class->password, $opt);
}

sub execute {
    my $class = shift;
    my ($sql, $data, $binds) = @_;
    $sql or return;
    my @bind_values = ref $binds eq 'ARRAY' ? @$binds : ();
    my $dbh = $class->dbh(substr($sql,0,8));
    my $sth = @bind_values ? $dbh->prepare_cached($sql,undef,1) :
        $dbh->prepare($sql);
    unless ($sth) { carp $dbh->errstr and return; }
    if ($DEBUG) {
        my @binds = map { defined $_ ? "'$_'" : "'NULL'" } @bind_values; 
        carp $sql . '->execute(' . join(',', @binds) . ')';
        $SQL_COUNT++;
    }

    my $sql_error = sub {
        my ($sql, $sth) = @_;
        defined $data
            ? sprintf('SQL Error: "%s" (%s)', $sql, $sth->errstr)
            : sprintf('SQL Error "%s"', $sql);
    };

    eval {
        if (defined $data) {
            $sth->execute(@bind_values) or carp $sql_error->($sth, $sql) and return;
            $$data = $sth->fetchall_arrayref({});
        } else {
            unless ($sth->execute(@bind_values)) {
                $sql_error->($sql, $sth);
                return;
            }
        }
    };
    if ($@) {
        confess $sql_error->($sql, $sth);
    }

    if ($sql =~ /^insert/io) {
        $class->last_insert_id($dbh->last_insert_id(undef,undef,undef,undef) ||
                           $dbh->{'mysql_insertid'});
    }
    return !$sth->err;
}

sub vendor {
    my $class = shift;
    $class->dbh->get_info(17); # SQL_DBMS_NAME
}

sub primary_keys {
    my $class = shift;
    my $table = shift or return;
    my $dbh = $class->dbh;
    if ($class->vendor eq 'MySQL') {
        my $sth = $dbh->column_info(undef,undef,$table,'%') or
            croak $dbh->errstr;
        $dbh->err and croak $dbh->errstr;
        my @cols = @{$sth->fetchall_arrayref({})} or
            croak "couldnt get primary keys";
        return [
            map {$_->{COLUMN_NAME}}
            grep {$_->{mysql_is_pri_key}}
            @cols
        ];
    } else {
        return [$dbh->primary_key(undef,undef,$table)];
    }
}

sub unique_keys {
    my $class = shift;
    my $table = shift or return;
    if ($class->vendor eq 'MySQL') {
        my $sql = "SHOW INDEX FROM $table";
        my $data;
        $class->execute($sql,\$data) or
            croak "couldnt get unique keys";
        @$data or croak "couldnt get unique keys";
        return [
            map {$_->{Column_name}}
            grep {!$_->{Non_unique}}
            @$data
        ];
    } else {
        return $class->primary_keys($table);
    }
}

sub columns {
    my $class = shift;
    my $table = shift or return;
    my $dbh = $class->dbh;
    if (my $sth = $class->dbh->column_info(undef,undef,$table,'%')) {
        croak $dbh->errstr if $dbh->err;
        my @cols = @{$sth->fetchall_arrayref({})} or
            croak "couldnt get primary keys";
        return [
            map {$_->{COLUMN_NAME}}
            @cols
        ];
    } else {
        my $d = $class->select($table,'*',undef,'',{limit => 1}) or return;
        return [keys %{$d->[0]}];
    }
}

1;

=head1 NAME

DBIx::MoCo::DataBase - Data Base Handler for DBIx::MoCo

=head1 SYNOPSIS

  package MyDataBase;
  use base qw(DBIx::MoCo::DataBase);

  __PACKAGE__->dsn('dbi:mysql:myapp');
  __PACKAGE__->username('test');
  __PACKAGE__->password('test');

  1;

  # In your scripts
  MyDataBase->execute('select 1');

  # Configure your replication databases
  __PACKAGE__->dsn(
    master => 'dbi:mysql:dbname=test;host=db1',
    slave => ['dbi:mysql:dbname=test;host=db2','dbi:mysql:dbname=test;host=db3'],
  );

=head1 METHODS

=over 4

=item cache_connection

Controlls cache behavior for dbh connection. (default 1)
If its set to 0, DBIx::MoCo::DataBase uses DBI->connect instead of
DBI->connect_cached.

  DBIx::MoCo::DataBase->cache_connection(0);

=item dsn

Configures dsn(s). You can specify single dsn as string, multiple dsns as an array,
master/slave dsns as hash.

If you specify multiple dsns, they will be rotated automatically in round-robin.
MoCo will use slave dsns when the sql begins with C<SELECT> if you set up slave(s).

  MyDataBase->dsn('dbi:mysql:dbname=test');
  MyDataBase->dsn(['dbi:mysql:dbname=test;host=db1','dbi:mysql:dbname=test;host=db2']);
  MyDataBase->dsn(
     master => ['dbi:mysql:dbname=test;host=db1','dbi:mysql:dbname=test;host=db2'],
  );
  MyDataBase->dsn(
    master => 'dbi:mysql:dbname=test;host=db1',
    slave => ['dbi:mysql:dbname=test;host=db2','dbi:mysql:dbname=test;host=db3'],
  );

=back

=head1 SEE ALSO

L<DBIx::MoCo>, L<SQL::Abstract>

=head1 AUTHOR

Junya Kondo, E<lt>jkondo@hatena.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut
