package Algorithm::SpatialIndex::Storage::DBI;
use 5.008001;
use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.02';

use parent 'Algorithm::SpatialIndex::Storage';
use constant DEBUG => 0;

=head1 NAME

Algorithm::SpatialIndex::Storage::DBI - DBI storage backend

=head1 SYNOPSIS

  use Algorithm::SpatialIndex;
  my $dbh = ...;
  my $idx = Algorithm::SpatialIndex->new(
    storage      => 'DBI',
    dbh_rw       => $dbh,
    dbh_ro       => $dbh, # defaults to dbh_rw
    table_prefix => 'si_',
  );

=head1 DESCRIPTION

B<WARNING: WHILE IT SEEMS TO WORK FOR ME, THIS STORAGE BACKEND IS HIGHLY
EXPERIMENTAL AND IN A PROOF-OF-CONCEPT STATE.> Unsurprisingly, it is also
20x slower when using SQLite as the storage engine then when using the
memory storage backend. Has only been tested with SQLite but has
mysql-specific and SQLite specific code paths as well as a general
SQL code path which is less careful about race conditions.

Inherits from L<Algorithm::SpatialIndex::Storage>.

This storage backend is persistent.

No implementation of schema migration yet, so expect to have to
reinitialize the index after a module upgrade!

=head1 ACCESSORS

=cut


use constant NODE_ID_TYPE => 'INTEGER';
use constant ITEM_ID_TYPE => 'INTEGER';

use Class::XSAccessor {
  getters => [qw(
    dbh_rw
    table_prefix

    no_of_coords
    coord_types
    node_coord_create_sql
    node_coord_select_sql
    node_coord_insert_sql

    no_of_subnodes
    subnodes_create_sql
    subnodes_select_sql
    subnodes_insert_sql

    bucket_size
    item_coord_types

    config

    dbms_name
    is_mysql
    is_sqlite

  )],
};

=head2 table_prefix

Returns the prefix of the table names.

=head2 coord_types

Returns an array reference containing the coordinate type strings.

=head2 item_coord_types

Returns an array reference containing the item coordinate type strings.

=head2 node_coord_create_sql

Returns the precomputed SQL fragment of the node coordinate
columns (C<CREATE TABLE> syntax).

=head2 no_of_subnodes

Returns the no. of subnodes per node.

=head2 subnodes_create_sql

Returns the precomputed SQL fragment of the subnode id
columns (C<CREATE TABLE> syntax).

=head2 config

Returns the hash reference of configuration options
read from the config table.

=head2 dbh_rw

Returns the read/write database handle.

=head2 dbh_ro

Returns the read-only database handle. Falls back
to the read/write handle if not defined.

=cut

sub dbh_ro {
  my $self = shift;
  if (defined $self->{dbh_ro}) {
    return $self->{dbh_ro};
  }
  return $self->{dbh_rw};
}

=head1 OTHER METHODS

=head2 init

Reads the options from the database for previously existing indexes.
Creates tables and writes default configuration for those that didn't
exist before.

Doesn't do any schema migration at this point.

=cut

sub init {
  my $self = shift;

  my $opt = $self->{opt};
  $self->{dbh_rw} = $opt->{dbh_rw};
  $self->{dbh_ro} = $opt->{dbh_ro};
  my $table_prefix = defined($opt->{table_prefix})
                     ? $opt->{table_prefix} : 'spatialindex';
  $self->{table_prefix} = $table_prefix;

  # Dear SQL. Please go away. Thank you.
  $self->{dbms_name} = $self->dbh_ro->get_info(17) if not defined $self->{dbms_name};
  $self->{is_mysql}  = 0;
  $self->{is_sqlite} = 0;

  my $option_table_name = $table_prefix . '_options';
  my $node_table_name   = $table_prefix . '_nodes';

  if ($self->{dbms_name} =~ /mysql/i) {
    $self->{is_mysql} = 1;
    $self->{_write_config_sql} = [
      qq{
        INSERT INTO $option_table_name
        SET id=?, value=?
        ON DUPLICATE KEY UPDATE id=?, value=?
      }, 0, 1, 0, 1
    ];
  }
  elsif ($self->{dbms_name} =~ /sqlite/i) {
    $self->{is_sqlite} = 1;
    $self->{_write_config_sql} = [qq{INSERT OR REPLACE INTO $option_table_name (id, value) VALUES(?, ?)}, 0, 1 ];
  }
  else {
    $self->{_write_config_sql} = sub {
      my $dbh = shift;
      eval {
        $dbh->do(qq{INSERT INTO $option_table_name (id, value) VALUES(?, ?)}, {}, $_[0], $_[1]);
        $dbh->do(qq{UPDATE $option_table_name SET id=?, value=?}, {}, $_[0], $_[1]);
        1;
      };
    };
  }

  my $config_existed = $self->_read_config_table;
  $self->{no_of_coords} = scalar(@{$self->coord_types});
  $self->_coord_types_to_sql($self->coord_types);
  $self->_subnodes_sql($self->no_of_subnodes);
  $self->{_fetch_node_sql} = qq(SELECT id, $self->{node_coord_select_sql}, $self->{subnodes_select_sql} FROM ${table_prefix}_nodes WHERE id=?);
  my $qlist = '?,' x ($self->no_of_subnodes + @{$self->coord_types});
  $qlist =~ s/,$//;
  $self->{_write_new_node_sql} = qq{INSERT INTO $node_table_name (}
                                 . $self->node_coord_select_sql . ', '
                                 . $self->subnodes_select_sql
                                 . qq{) VALUES($qlist)};
  $self->{_write_node_sql} = qq{UPDATE $node_table_name SET id=?, }
                             . $self->node_coord_insert_sql . ', '
                             . $self->subnodes_insert_sql
                             . ' WHERE id=?';
  $self->_bucket_sql; # init sql for bucket operations

  $self->_init_tables();
  $self->_write_config() if not $config_existed;
}

=head2 _read_config_table

Reads the configuration table.
Returns whether this succeeded or not.
In case of failure, this initializes some of the
configuration options from other sources.

=cut

sub _read_config_table {
  my $self = shift;
  my $dbh = $self->dbh_ro;
  my $table_prefix = $self->table_prefix;

  my $find_sth = $dbh->table_info('%', '%', "${table_prefix}_options", 'TABLE');
  my $opt;
  my $success;
  if ($find_sth->fetchrow_arrayref()) {
    my $sql = qq#
          SELECT id, value
          FROM ${table_prefix}_options
        #;
    $success = eval {
      $opt = $dbh->selectall_hashref($sql, 'id');
      my $err = $dbh->errstr;
      die $err if $err;
      1;
    };
  }
  $opt ||= {};
  $opt->{$_} = $opt->{$_}{value} for keys %$opt;
  $self->{config} = $opt;

  if (defined $opt->{coord_types}) {
    $self->{coord_types} = [split / /, $opt->{coord_types}];
  }
  else {
    $self->{coord_types} = [$self->index->strategy->coord_types];
    $opt->{coord_types} = join ' ', @{$self->{coord_types}};
  }

  if (defined $opt->{item_coord_types}) {
    $self->{item_coord_types} = [split / /, $opt->{item_coord_types}];
  }
  else {
    $self->{item_coord_types} = [$self->index->strategy->item_coord_types];
    $opt->{item_coord_types} = join ' ', @{$self->{item_coord_types}};
  }

  $opt->{no_of_subnodes} ||= $self->index->strategy->no_of_subnodes;
  $self->{no_of_subnodes} = $opt->{no_of_subnodes};

  $opt->{bucket_size} ||= $self->index->strategy->bucket_size;
  $self->{bucket_size} = $opt->{bucket_size};

  return $success;
}

=head2 _init_tables

Creates the index's tables.

=cut

sub _init_tables {
  my $self = shift;

  my $dbh = $self->dbh_rw;

  my $table_prefix = $self->table_prefix;
  my $sql_opt = qq(
    CREATE TABLE IF NOT EXISTS ${table_prefix}_options (
      id VARCHAR(255) PRIMARY KEY,
      value VARCHAR(1023)
    )
  );
  warn $sql_opt if DEBUG;
  $dbh->do($sql_opt);

  my $node_id_type = NODE_ID_TYPE;
  my $coord_sql = $self->node_coord_create_sql;
  my $subnodes_sql = $self->subnodes_create_sql;
  my $sql =  qq(
    CREATE TABLE IF NOT EXISTS ${table_prefix}_nodes (
      id $node_id_type PRIMARY KEY AUTOINCREMENT,
      $coord_sql,
      $subnodes_sql
    )
  );
  warn $sql if DEBUG;
  $dbh->do($sql);

  my $bsql = $self->{buckets_create_sql};
  warn $bsql if DEBUG;
  $dbh->do($bsql);
}

=head2 _write_config

Writes the index's configuration to the
configuration table.

=cut

sub _write_config {
  my $self = shift;
  my $dbh = $self->dbh_rw;

  my $table_prefix = $self->table_prefix;

  my $sql_struct = $self->{_write_config_sql};
  my $is_sub = ref($sql_struct) eq 'CODE';
  my $sth;
  $sth = $dbh->prepare_cached($sql_struct->[0]) if not $is_sub;

  my $success = eval {
    foreach my $key (keys %{$self->{config}}) {
      if ($is_sub) {
        $sql_struct->($key, $self->{config}{$key});
      } else {
        my $d = [$key, $self->{config}{$key}];
        $sth->execute(map $d->[$_], @{$sql_struct}[1..$#$sql_struct]);
        my $err = $sth->errstr; die $err if $err;
      }
    }
    1;
  };
  $sth->finish;
}

sub fetch_node {
  my $self  = shift;
  my $index = shift;
  my $dbh = $self->dbh_ro;
  my $str = $self->{_fetch_node_sql};
  my $sth = $dbh->prepare_cached($str);
  $sth->execute($index);
  my $struct = $sth->fetchrow_arrayref;
  $sth->finish;
  return if not defined $struct;
  my $coords = $self->no_of_coords;
  my $snodes = [@{$struct}[1+$coords..$coords+$self->no_of_subnodes]];
  $snodes = [] if not defined $snodes->[0];
  my $node = Algorithm::SpatialIndex::Node->new(
    id => $struct->[0],
    coords => [@{$struct}[1..$coords]],
    subnode_ids => $snodes,
  );
  #use Data::Dumper; warn "FETCH: " . Dumper($node);
  return $node;
}

sub store_node {
  my $self = shift;
  my $node = shift;
  #use Data::Dumper;
  #use Data::Dumper; warn "STORE: " . Dumper($node);
  my $id = $node->id;
  my $dbh = $self->dbh_rw;
  my $tname = $self->table_prefix . '_nodes'; 
  my $sth;
  if (not defined $id) {
    $sth = $dbh->prepare_cached($self->{_write_new_node_sql});
    my $coords = $node->coords;
    my $snids = $node->subnode_ids;
    my @args = (
      @$coords,
      ((undef) x ($self->no_of_coords - @$coords)),
      @$snids,
      ((undef) x ($self->no_of_subnodes - @$snids))
    );
    $sth->execute(@args);
    $id = $dbh->last_insert_id('', '', '', ''); # FIXME NOT PORTABLE LIKE THAT
    $node->id($id);
  }
  else {
    $sth = $dbh->prepare_cached($self->{_write_node_sql});
    $sth->execute($id, @{$node->coords}, @{$node->subnode_ids}, $id);
  }
  $sth->finish();
  return $id;
}

sub get_option {
  my $self = shift;
  return $self->{config}->{shift()}; # We assume this data changes RARELY
}

sub set_option {
  my $self  = shift;
  my $key   = shift;
  my $value = shift;

  $self->{config}->{$key} = $value;
  $self->_write_config(); # FIXME wasteful
}

sub store_bucket {
  my $self   = shift;
  my $bucket = shift;
  my $dbh = $self->dbh_rw;
  my $id = $bucket->node_id;
  my $sql = $self->{buckets_insert_sql};
  my $is_sub = ref($sql) eq 'CODE';
  if (!$is_sub) {
    my $sth = $dbh->prepare_cached($sql->[0]);
    my $d = [$id, map {@$_} @{$bucket->items}];
    $sth->execute(map $d->[$_], @{$sql}[1..$#$sql]);
    my $err = $sth->errstr; die $err if $err;
    $sth->finish;
  }
  else {
    $sql->($id, map {@$_} @{$bucket->items});
  }
}

sub fetch_bucket {
  my $self    = shift;
  my $node_id = shift;
  my $dbh = $self->dbh_ro;
  my $selsql = $self->{buckets_select_sql};
# This throws SEGV in the driver
  #my $sth = $dbh->prepare_cached($selsql);
  #$sth->execute($node_id) or die $dbh->errstr;
  #my $row = $sth->fetchrow_arrayref;
  #$sth->finish;
  my $rows = $dbh->selectall_arrayref($selsql, {}, $node_id);
  my $row = $rows->[0];
  return undef if not defined $row;
  my $items = [];
  my $n = scalar(@{$self->item_coord_types}) + 1;
  while (@$row > 1) {
    my $item = [splice(@$row, 1, $n)];
    next if not defined $item->[0];
    push @$items, $item;
  }
  my $bucket = $self->bucket_class->new(node_id => $node_id, items => $items);
  return $bucket;
}

sub delete_bucket {
  my $self    = shift;
  my $node_id = shift;
  $node_id = $node_id->node_id if ref($node_id);
  my $tname = $self->table_prefix . '_buckets';
  $self->dbh_rw->do(qq{DELETE FROM $tname WHERE node_id=?}, {}, $node_id);
  return();
}


=head2 _coord_types_to_sql

Given an array ref containing coordinate type strings
(cf. L<Algorithm::SpatialIndex::Strategy>),
stores the SQL fragments for C<SELECT>
and C<CREATE TABLE> for the node coordinates.

The coordinates will be called C<c$i> where C<$i>
starts at 0.

=cut

sub _coord_types_to_sql {
  my $self = shift;
  my $types = shift;

  my %types = (
    float    => 'FLOAT',
    double   => 'DOUBLE',
    integer  => 'INTEGER',
    unsigned => 'INTEGER UNSIGNED',
  );
  my $create_sql = '';
  my $select_sql = '';
  my $insert_sql = '';
  my $i = 0;
  foreach my $type (@$types) {
    my $sql_type = $types{lc($type)};
    die "Invalid coord type '$type'" if not defined $sql_type;
    $create_sql .= "  c$i $sql_type, ";
    $select_sql .= "  c$i, ";
    $insert_sql .= " c$i=?, ";
    $i++;
  }
  $create_sql =~ s/, \z//;
  $select_sql =~ s/, \z//;
  $insert_sql =~ s/, \z//;
  $self->{node_coord_create_sql} = $create_sql;
  $self->{node_coord_select_sql} = $select_sql;
  $self->{node_coord_insert_sql} = $insert_sql;
}

=head2 _subnodes_sql

Given the number of subnodes per node,
creates a string of column specifications
for interpolation into a C<CREATE TABLE>
and one for interpolation into a C<SELECT>.
Saves those strings into the object.

The columns are named C<sn$i> with C<$i>
starting at 0.

=cut

sub _subnodes_sql {
  my $self = shift;
  my $no_subnodes = shift;
  my $create_sql = '';
  my $select_sql = '';
  my $insert_sql = '';
  my $i = 0;
  my $node_id_type = NODE_ID_TYPE;
  foreach my $i (0..$no_subnodes-1) {
    $create_sql .= "  sn$i $node_id_type, ";
    $select_sql .= "  sn$i, ";
    $insert_sql .= " sn$i=?, ";
    $i++;
  }
  $create_sql =~ s/, \z//;
  $select_sql =~ s/, \z//;
  $insert_sql =~ s/, \z//;
  $self->{subnodes_create_sql} = $create_sql;
  $self->{subnodes_select_sql} = $select_sql;
  $self->{subnodes_insert_sql} = $insert_sql;
}

sub _bucket_sql {
  my $self = shift;
  my $bsize = $self->bucket_size;
  my $tname = $self->table_prefix . '_buckets';

  my %types = (
    float    => 'FLOAT',
    double   => 'DOUBLE',
    integer  => 'INTEGER',
    unsigned => 'INTEGER UNSIGNED',
  );
  my $item_coord_types = [map $types{$_}, @{$self->item_coord_types}];

  # i0 INTEGER, i0c0 DOUBLE, i0c1 DOUBLE, ...
  $self->{buckets_create_sql} = qq{CREATE TABLE IF NOT EXISTS $tname ( node_id INTEGER PRIMARY KEY, }
                                . join(
                                  ', ',
                                  map {
                                    my $i = $_;
                                    my $c = 0;
                                    ("i$i INTEGER", map "i${i}c".$c++." $_", @$item_coord_types)
                                  } 0..$bsize-1
                                )
                                . ')';
  $self->{buckets_select_sql} = qq{SELECT * FROM $tname WHERE node_id=?};

  my $insert_id_list = join(
    ', ',
    map {
      my $i = $_;
      "i$i", map "i${i}c$_", 0..$#$item_coord_types
    } 0..$bsize-1
  );
  my $nentries = 1 + $bsize * (1+@$item_coord_types);
  #my $idlist = join(', ', map "i$_" 0..$bsize-1);
  my $qlist  = '?,' x $nentries;
  $qlist =~ s/,$//;
  if ($self->is_mysql) {
    $self->{buckets_insert_sql} = [
      qq{
        INSERT INTO $tname
        VALUES ($qlist)
        ON DUPLICATE KEY UPDATE $insert_id_list
      }, 0..$nentries-1
    ];
  }
  elsif ($self->is_sqlite) {
    $self->{buckets_insert_sql} = [qq{INSERT OR REPLACE INTO $tname VALUES($qlist)}, 0..$nentries-1 ];
  }
  else {
    my $insert_sql = qq{INSERT INTO $tname VALUES(?, $qlist)};
    my $update_sql = qq{UPDATE $tname SET id=?, $insert_id_list};
    $self->{buckets_insert_sql} = sub {
      my $dbh = shift;
      eval {
        $dbh->do($insert_sql, {}, @_, (undef) x ($nentries-@_));
        $dbh->do($update_sql, {}, @_, (undef) x ($nentries-@_));
        1;
      };
    };
  }
  #use Data::Dumper;
  #warn Dumper $self->{buckets_insert_sql};
}

1;
__END__

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, 2011 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
