#!/usr/bin/perl -w

package Data::Fallback::DBI;

use strict;
use Carp qw(confess);

use DBI;

use Data::Fallback;
use vars qw(@ISA);
@ISA = qw(Data::Fallback);

sub connect {
  my $self = shift;
  my $db = $self->get_db;
  confess "need a \$db to connect with" unless $db;
  my $dbh = DBI->connect(@{$db});
  confess "couldn't connect with " . join(", ", @{$db}) unless $dbh;
  confess "got a \$DBI::errstr with " . join(", ", @{$db}) . ": $DBI::errstr" if $DBI::errstr;
  return $dbh;
}

sub _GET {
  my $self = shift;

  my $return = 0;
  my $row_hash_ref = $self->get_content;

  if( $row_hash_ref && exists $row_hash_ref->{$self->get_cache_key('item')} ) {
    $self->{update}{group} = $row_hash_ref;
    $self->{update}{item} = $row_hash_ref->{$self->get_cache_key('item')};
    $self->set_cache('DBI', 'item', $self->get_full_cache_key, $self->{update}{item});
    $return = 1;
  }

  return $return;
}

sub get_full_cache_key {
  my $self = shift;
  return $self->get_connect_string . "." . 
         $self->get_cache_key('content') . "." . 
         $self->get_cache_key('primary_key') . "." . 
         $self->get_cache_key('item');
}

sub get_content {
  my $self = shift;

  my ($found_in_cache, $hash_ref, $found_at_cache_level) = 
    $self->check_cache('DBI', 'group', $self->get_full_cache_key);

  if($found_in_cache) {
    # already set in $hash_ref, so we're done
  } else {
    my $dbh = $self->get_dbh;
    $self->{cache}{DBI} ||= {};
    $self->{cache}{DBI}{sth} ||= {};

    my $connect_string = $self->get_connect_string;

    my $sth_key = $connect_string . "." . $self->{hash}{content};
    $self->{cache}{DBI}{sth}{$sth_key} ||= $dbh->prepare($self->{hash}{content});

    my @primary_key = GET_VALUES($self->get_cache_key('primary_key'));

    my $execute = $self->{cache}{DBI}{sth}{$sth_key}->execute(@primary_key);
    confess "got a \$DBI::errstr with $self->{hash}{content}: $DBI::errstr" if $DBI::errstr;
    $hash_ref = $self->{cache}{DBI}{sth}{$sth_key}->fetchrow_hashref('NAME_lc');
    confess "got a \$DBI::errstr with $self->{hash}{content}: $DBI::errstr" if $DBI::errstr;
    $self->set_cache('DBI', 'group', $self->get_full_cache_key, $hash_ref) if($hash_ref);
  }
  return $hash_ref;
}

sub get_connect_string {
  my $self = shift;
  my $db = $self->get_db;
  return join(",", @{$db});
}

sub get_db {
  my $self = shift;
  return $self->{hash}{db} || $self->{db};
}

sub get_dbh {
  my $self = shift;
  my $db = $self->get_db;

  confess "need a \$db to connect with" unless $db;
  $self->{dbh_cache} ||= {};
  my $connect_string = $self->get_connect_string;
  my $dbh = $self->{dbh_cache}{$connect_string};
  unless($dbh) {
    $dbh = $self->connect;
    $self->{dbh_cache}{$connect_string} = $dbh;
  }
  return $dbh;
}

sub SET_ITEM {
  my $self = shift;
  my $dbh = $self->get_dbh;
  my $update_item_sql = $self->get_update_item_sql;
  my $key_name = $self->{hash}{content} . "." . $self->get_cache_key('primary_key') . ".$self->{item}";
  $self->{cache}{DBI} ||= {};
  $self->{cache}{DBI}{sql} ||= {};
  $self->{cache}{DBI}{sql}{$key_name} ||= $update_item_sql;
  $self->{cache}{DBI}{sth}{$key_name} ||= $dbh->prepare($self->{cache}{DBI}{sql}{$key_name});
  confess "got a \$DBI::errstr with $self->{cache}{DBI}{sql}{$key_name}: $DBI::errstr" if $DBI::errstr;

  my @primary_key = GET_VALUES($self->get_cache_key('primary_key'));
  my $execute = $self->{cache}{DBI}{sth}{$key_name}->execute($self->{update}{item}, @primary_key);
  confess "got a \$DBI::errstr with $self->{cache}{DBI}{sql}{$key_name}: $DBI::errstr" if $DBI::errstr;
}

sub SET_GROUP {
  my $self = shift;
  my $dbh = $self->get_dbh;
  my ($table, $where) = $self->get_table_where($self->{hash}{content});
  my $key_name = $self->{hash}{content} . "." . $self->get_cache_key('primary_key') . ".$self->{item}";
  my @primary_key = GET_VALUES($self->get_cache_key('primary_key'));
  $self->{cache}{DBI} ||= {};
  $self->{cache}{DBI}{sql} ||= {};
  $self->{cache}{DBI}{sql}{$key_name} ||= $self->{hash}{content};
  $self->{cache}{DBI}{sth}{$key_name} ||= $dbh->prepare($self->{cache}{DBI}{sql}{$key_name});
  $self->{cache}{DBI}{sth}{$key_name}->execute(@primary_key);
  if(my @array = $self->{cache}{DBI}{sth}{$key_name}->fetchrow_array) {
    # record is there, need to UPDATE
    unless($self->do_update) {
    }
  } else {
    # record is not there, need to SELECT
    confess "got a \$DBI::errstr with $self->{hash}{content}: $DBI::errstr" if $DBI::errstr;
    unless($self->do_insert) {
    }
  }
}

sub do_insert {
  my $self = shift;
  my $dbh = $self->get_dbh;
  my ($insert_sql, $args) = $self->get_insert_info;
  my $connect_string = $self->get_connect_string;
  $self->{cache}{DBI} ||= {};
  $self->{cache}{DBI}{sql} ||= {};
  $self->{cache}{DBI}{sql}{$insert_sql} ||= $insert_sql;
  my $key = $connect_string . "." . $insert_sql;
  $self->{cache}{DBI}{sth}{$key} ||= $dbh->prepare($self->{cache}{DBI}{sql}{$insert_sql});
  my $inserted = $self->{cache}{DBI}{sth}{$key}->execute(@{$args});
  confess "got a \$DBI::errstr with $self->{hash}{content}: $DBI::errstr" if $DBI::errstr;
  return $inserted;
}

sub get_insert_info {
  my $self = shift;
  my $table = $self->get_table($self->{hash}{content});
  my ($cols, $values) = ('', '');
  my @args = ();
  foreach(sort keys %{$self->{update}{group}}) {
    $cols .= "$_, ";
    $values .= "?, ";
    push @args, $self->{update}{group}{$_};
  }
  foreach($cols, $values) {
    s/,\s+$//;
  }
  my $insert_sql = "INSERT INTO $table (" . $cols . ") VALUES (" . $values . ")";
  return ($insert_sql, \@args);
}

sub do_update {
  my $self = shift;
  my $dbh = $self->get_dbh;
  my ($update_sql, $args) = $self->get_update_info;
  my $connect_string = $self->get_connect_string;
  my $key = $connect_string . "." . $update_sql;
  $self->{cache}{DBI} ||= {};
  $self->{cache}{DBI}{sql} ||= {};
  $self->{cache}{DBI}{sql}{$update_sql} ||= $update_sql;
  $self->{cache}{DBI}{sth}{$key} ||= $dbh->prepare($self->{cache}{DBI}{sql}{$update_sql});

  my @primary_key = GET_VALUES($self->get_cache_key('primary_key'));

  my $updated = $self->{cache}{DBI}{sth}{$key}->execute(@{$args}, @primary_key);
  confess "got a \$DBI::errstr with $self->{hash}{content}: $DBI::errstr" if $DBI::errstr;
  return $updated;
}

sub get_update_info {
  my $self = shift;
  my ($table, $where) = $self->get_table_where($self->{hash}{content});
  my ($cols, $values) = ('', '');
  my @args = ();
  my $update_sql = "UPDATE $table SET ";
  foreach(sort keys %{$self->{update}{group}}) {
    $update_sql .= "$_ = ?, ";
    push @args, $self->{update}{group}{$_};
  }
  $update_sql =~ s/,\s+$//;
  $update_sql .= " WHERE " . $where;
  return ($update_sql, \@args);
}

sub get_update_item_sql {
  my $self = shift;

  my ($table, $where) = $self->get_table_where($self->{hash}{content});
  my $update_item_sql = "UPDATE $table SET $self->{item} = ? WHERE $where"; 
  return $update_item_sql;
}

sub get_table_where {
  my $self = shift;
  my $sql = shift;
  my $table = $self->get_table($sql);
  my $where = $self->get_where($sql);
  return ($table, $where);
}

sub get_table {
  my $self = shift;
  my $sql = shift;
  my $table;
  if($sql =~ /^\s*select\s+.+?\s+from\s+([a-z0-9_]+)\s+where/si) {
    $table = $1;
  } else {
    die "couldn't find a table name easily in $sql";
  }
  return $table;
}

sub get_where {
  my $self = shift;
  my $sql = shift;
  my $where;
  if($sql =~ /^\s*select\s+.+?\s+from\s+[a-z0-9_]+\s+where\s+(.+)/si) {
    $where = $1;
  } else {
    die "couldn't get your update where easily from $sql";
  }
  return $where;
}

sub GET_VALUES {
  my $values=shift;
  return () unless defined $values;
  if (ref $values eq "ARRAY") {
    return @$values;
  }
  return ($values);
}

sub DESTROY {
  my $self = shift;
}

1;
