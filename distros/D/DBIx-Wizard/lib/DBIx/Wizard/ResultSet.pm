package DBIx::Wizard::ResultSet;

use strict;
use Carp;
use DBIx::Wizard::DB;
use DBIx::Wizard::DB::Table;
use DBIx::Wizard::Cursor;
use SQL::Wizard;

my $sw = SQL::Wizard->new;

sub _sw { return $sw }

sub new {
  my ($class, $rh_args) = @_;
  return bless($rh_args || {}, $class);
}

sub _clone {
  my ($self) = @_;
  return bless { %$self }, ref($self);
}

## Query building methods (all return $self for chaining)

sub as {
  my ($self, $alias) = @_;
  $self->{alias} = $alias;
  return $self;
}

sub find {
  my ($self, $where) = @_;
  $where ||= {};

  if (ref($where) eq 'HASH') {
    my %h_new_where = (%{$self->{where} || {}}, %{$where});
    $self->{where} = \%h_new_where;
  } elsif (ref($where) eq 'ARRAY') {
    $self->{where} = $where;
  }

  return $self;
}

sub join {
  my ($self, $table, $on) = @_;
  $self->{joins} ||= [];
  push @{$self->{joins}}, $sw->join($table, $on);
  return $self;
}

sub left_join {
  my ($self, $table, $on) = @_;
  $self->{joins} ||= [];
  push @{$self->{joins}}, $sw->left_join($table, $on);
  return $self;
}

sub right_join {
  my ($self, $table, $on) = @_;
  $self->{joins} ||= [];
  push @{$self->{joins}}, $sw->right_join($table, $on);
  return $self;
}

sub full_join {
  my ($self, $table, $on) = @_;
  $self->{joins} ||= [];
  push @{$self->{joins}}, $sw->full_join($table, $on);
  return $self;
}

sub cross_join {
  my ($self, $table) = @_;
  $self->{joins} ||= [];
  push @{$self->{joins}}, $sw->cross_join($table);
  return $self;
}

sub sort {
  my ($self, @sort) = @_;

  if (scalar(@sort) == 1 && ref($sort[0]) eq 'ARRAY') {
    $self->{sort} = $sort[0];
  } else {
    $self->{sort} = \@sort;
  }

  return $self;
}

sub group_by {
  my ($self, @group_by) = @_;
  $self->{group_by} = \@group_by;
  return $self;
}

sub having {
  my ($self, $having) = @_;
  $self->{having} = $having;
  return $self;
}

sub limit {
  my ($self, $limit) = @_;
  croak "DBIW: limit failed: invalid input $limit" if $limit !~ m/^\d+$/;
  $self->{limit} = $limit;
  return $self;
}

sub offset {
  my ($self, $offset) = @_;
  croak "DBIW: offset failed: invalid input $offset" if $offset !~ m/^\d+$/;
  $self->{offset} = $offset;
  return $self;
}

sub inflate {
  my ($self, $inflate) = @_;
  $self->{inflate} = $inflate;
  return $self;
}

sub inflate_class {
  my ($self, $class) = @_;
  $self->{inflate_class} = $class;
  return $self;
}

## Data retrieval

sub all {
  my ($self, $columns) = @_;

  if ($columns) {
    if (ref($columns) eq 'ARRAY') {
      $self->{columns} = [_alias_dotted(@$columns)];
    } else {
      $self->{columns} = [_alias_dotted($columns)];
    }
  }

  my @all = $self->_select();

  if ($columns && ref($columns) ne 'ARRAY') {
    return map { $_->{$columns} } @all;
  } else {
    return @all;
  }
}

sub distinct {
  my ($self, $columns) = @_;
  croak "distinct() requires a column name or arrayref of columns" unless $columns;
  $self->{distinct} = 1;
  return $self->all($columns);
}

sub one {
  my ($self, $columns) = @_;
  my $clone = $self->_clone;

  $clone->{limit} = 1;

  if ($columns) {
    if (ref($columns) eq 'ARRAY') {
      $clone->{columns} = [_alias_dotted(@$columns)];
    } else {
      $clone->{columns} = [_alias_dotted($columns)];
    }
  }

  my @one = $clone->_select();

  if ($columns && ref($columns) ne 'ARRAY') {
    return $one[0]->{$columns};
  } else {
    return $one[0];
  }
}

sub cursor {
  my ($self, $columns) = @_;

  if ($columns) {
    if (ref($columns) eq 'ARRAY') {
      $self->{columns} = $columns;
    } else {
      $self->{columns} = [$columns];
    }
  }

  my ($sql, @bind) = $self->_build_select()->to_sql();
  _debug_log('cursor', $sql, @bind);

  my $dbh = DBIx::Wizard::DB->dbh($self->{db});
  my $sth = $dbh->prepare($sql);
  $sth->execute(@bind) || croak "DBIW: query failed: $DBI::errstr";

  return DBIx::Wizard::Cursor->new({
    rs  => $self,
    sth => $sth,
  });
}

sub count {
  my $clone = shift->_clone;

  $clone->{columns} = [$sw->func('COUNT', '*')];
  my @count = $clone->_select();

  ## NOTE: fallback is for ClickHouse
  return $count[0]->{'COUNT(*)'} // $count[0]->{'count()'} // $count[0]->{'COUNT()'};
}

sub exists {
  my $self = shift;
  return $self->count > 0;
}

sub sum {
  my ($self, $column) = @_;
  my $clone = $self->_clone;

  $column =~ s/[^\w\.]+//gs;
  $clone->{columns} = [$sw->func('SUM', $column)];
  my @sum = $clone->_select();

  return $sum[0]->{"SUM($column)"} + 0;
}

## Data modification

sub insert {
  my ($self, $rh_insert, $auto_pk) = @_;
  $rh_insert ||= {};

  my $dbh = DBIx::Wizard::DB->dbh($self->{db});
  $auto_pk ||= DBIx::Wizard::DB::Table->auto_pk($self->{db}, $self->{table});

  my ($sql, @bind) = $sw->insert(
    -into   => $self->{table},
    -values => $rh_insert,
  )->to_sql;

  _debug_log('insert', $sql, @bind);

  my $sth = $dbh->prepare($sql);
  $sth->execute(@bind) || croak "DBIW: insert failed: $DBI::errstr";

  if ($auto_pk) {
    my @row;
    if ($sth->can('last_insert_id')) {
      @row = $sth->last_insert_id();
    } else {
      @row = $dbh->selectrow_array('SELECT LAST_INSERT_ID()');
    }
    return $row[0];
  }

  return;
}

sub update {
  my ($self, $rh_update) = @_;

  my ($sql, @bind) = $sw->update(
    -table => $self->{table},
    -set   => $rh_update,
    ($self->{where}) ? (-where => $self->{where}) : (),
    (defined $self->{limit}) ? (-limit => $self->{limit}) : (),
  )->to_sql;

  _debug_log('update', $sql, @bind);

  my $dbh = DBIx::Wizard::DB->dbh($self->{db});
  my $sth = $dbh->prepare($sql);
  $sth->execute(@bind) || croak "DBIW: update failed: $DBI::errstr";

  return $sth->rows;
}

sub delete {
  my $self = shift;

  my ($sql, @bind) = $sw->delete(
    -from => $self->{table},
    ($self->{where}) ? (-where => $self->{where}) : (),
  )->to_sql;

  _debug_log('delete', $sql, @bind);

  my $dbh = DBIx::Wizard::DB->dbh($self->{db});
  my $sth = $dbh->prepare($sql);
  $sth->execute(@bind) || croak "DBIW: delete failed: $DBI::errstr";
}

sub truncate {
  my $self = shift;

  my $dbh = DBIx::Wizard::DB->dbh($self->{db});
  my $driver = $dbh->{Driver}->{Name};

  # SQLite doesn't support TRUNCATE TABLE
  my ($sql, @bind);
  if ($driver eq 'SQLite') {
    ($sql, @bind) = $sw->delete(-from => $self->{table})->to_sql;
  } else {
    ($sql, @bind) = $sw->truncate(-table => $self->{table})->to_sql;
  }

  _debug_log('truncate', $sql, @bind);

  my $sth = $dbh->prepare($sql);
  $sth->execute(@bind) || croak "DBIW: truncate failed: $DBI::errstr";
}

sub dbh {
  my $self = shift;
  return DBIx::Wizard::DB->dbh($self->{db});
}

## Internal

sub _alias_dotted {
  return map { !ref($_) && /\./ ? $sw->col($_)->as($_) : $_ } @_;
}

sub _build_select {
  my $self = shift;

  my $from_table = $self->{alias}
    ? "$self->{table}|$self->{alias}"
    : $self->{table};

  my @from = ($from_table);
  if ($self->{joins}) {
    push @from, @{$self->{joins}};
  }

  return $sw->select(
    -from     => \@from,
    ($self->{distinct}) ? (-distinct => 1)                 : (),
    ($self->{columns})  ? (-columns  => $self->{columns})  : (),
    ($self->{where})    ? (-where    => $self->{where})    : (),
    ($self->{group_by}) ? (-group_by => $self->{group_by}) : (),
    ($self->{having})   ? (-having   => $self->{having})   : (),
    ($self->{sort})     ? (-order_by => $self->{sort})     : (),
    (defined $self->{limit})  ? (-limit  => $self->{limit})  : (),
    (defined $self->{offset}) ? (-offset => $self->{offset}) : (),
  );
}

sub _select {
  my $self = shift;

  my ($sql, @bind) = $self->_build_select()->to_sql();

  _debug_log('_select', $sql, @bind);

  my $dbh = DBIx::Wizard::DB->dbh($self->{db});
  my $sth = $dbh->prepare($sql);
  $sth->execute(@bind) || confess "DBIW: query failed: $DBI::errstr\n" .
                                  "SQL:  $sql\n" .
                                  "BIND: " . CORE::join(" -- ", @bind) . "\n";

  my $ra_rows = $sth->fetchall_arrayref({});

  if ($self->{inflate}) {
    my $ic = $self->_resolve_inflate_class;
    _inflate_time_objects($ra_rows, $self->{db}, $self->{table}, $ic);
  }

  return @$ra_rows;
}

sub _debug_log {
  my ($label, $sql, @bind) = @_;

  return unless $ENV{DEBUG_DBIW};

  my $log = "DBIW: $label() | $sql | " . CORE::join(" -- ", @bind) . "\n";

  if ($ENV{DEBUG_DBIW_FILE}) {
    open my $fh, '>>', $ENV{DEBUG_DBIW_FILE};
    print $fh $log;
    close $fh;
  } else {
    print $log;
  }
}

sub _resolve_inflate_class {
  my $self = shift;

  # ResultSet > DB declare > package default
  return $self->{inflate_class}
      || DBIx::Wizard::DB->inflate_class($self->{db})
      || DBIx::Wizard->default_inflate_class;
}

my %_loaded_classes;

sub _inflate_time_objects {
  my ($ra_rows, $db, $table, $inflate_class) = @_;

  # Lazy-load the inflate class
  if ($inflate_class && !$_loaded_classes{$inflate_class}) {
    (my $file = $inflate_class) =~ s|::|/|g;
    require "$file.pm";
    $_loaded_classes{$inflate_class} = 1;
  }

  my $rh_time_columns = DBIx::Wizard::DB::Table->time_columns_href($db, $table);

  if (%$rh_time_columns) {
    for my $rh_row (@$ra_rows) {
      for my $col (keys %$rh_row) {
        if ($rh_time_columns->{$col}) {
          if (defined $rh_row->{$col}) {
            if ($inflate_class eq 'Time::Moment') {
              (my $iso = $rh_row->{$col}) =~ s/ /T/;
              $iso .= 'Z' unless $iso =~ /[Z+-]/;
              $rh_row->{$col} = Time::Moment->from_string($iso);
            } else {
              $rh_row->{$col} = $inflate_class->new($rh_row->{$col});
            }
          }
        }
      }
    }
  }
}

1;
