package CellBIS::SQL::Abstract;
use Mojo::Base -base;

use Scalar::Util qw(blessed);
use Carp ();
use Mojo::Util qw(trim);
use CellBIS::SQL::Abstract::Util;
use CellBIS::SQL::Abstract::Table;

# ABSTRACT: SQL Query Generator
our $VERSION = '1.2';

has 'QueryUtil' => sub { state $qu = CellBIS::SQL::Abstract::Util->new };
has 'db_type';

# For Query Insert :
# ------------------------------------------------------------------------
sub insert {
  my $self    = shift;
  my $arg_len = scalar @_;
  my $data    = '';
  my ($table_name, $column, $col_val, $type);
  if ($arg_len == 3) {
    ($table_name, $column, $col_val) = @_;
  }
  if ($arg_len >= 4) {
    ($table_name, $column, $col_val, $type) = @_;
  }
  my @table_field    = @{$column};
  my @table_data     = @{$col_val};
  my @get_data_value = ();
  my $field_col      = join ', ', @table_field;
  my $value_col      = '';

  if ((scalar @table_field) == (scalar @table_data)) {

    if ($type && $type eq 'no-pre-st') {
      $value_col = join ', ',
        $self->QueryUtil->replace_data_value_insert_no_pre_st(\@table_data);
    }
    elsif ($type && $type eq 'pre-st') {
      @get_data_value
        = $self->QueryUtil->replace_data_value_insert(\@table_data);
      $value_col = join ', ', @get_data_value;
    }
    else {
      $value_col = join ', ',
        $self->QueryUtil->replace_data_value_insert_no_pre_st(\@table_data);
    }

    $field_col = trim($field_col);
    $value_col = trim($value_col);
    $value_col =~ s/\,$//g;
    $value_col =~ s/\s\,//g;

    $data = "INSERT INTO $table_name($field_col) VALUES($value_col)";
  }
  return $data;
}

# For Query Update :
# ------------------------------------------------------------------------
sub update {
  my $self    = shift;
  my $arg_len = scalar @_;

  if ($arg_len > 2 || $arg_len >= 5) {
    my $method_name = '_qUpdate_arg' . $arg_len;
    if ($self->can($method_name)) {
      return $self->$method_name(@_);
    }
  }
  return '';
}

# For Query Delete :
# ------------------------------------------------------------------------
sub delete {
  my $self = shift;
  my ($table_name, $clause) = @_;
  my $data = '';

  if (ref($clause) eq "HASH") {

    #    my $size_clause = scalar keys %{$clause};
    if (exists $clause->{where}) {
      my $where_clause = $self->QueryUtil->create_clause($clause);
      $data = "DELETE FROM $table_name \n$where_clause";
    }
  }
  return $data;
}

# For Query Select :
# ------------------------------------------------------------------------
sub select {
  my $self    = shift;
  my $arg_len = scalar @_;
  my $data;

  $data = $self->_qSelect_arg3(@_) unless ($arg_len < 2);
  return $data;
}

# For Query Select Join :
# ------------------------------------------------------------------------
sub select_join {
  my $self    = shift;
  my $arg_len = scalar @_;
  my $data    = '';

  $data = $self->_qSelectJoin_arg3(@_) unless ($arg_len < 3);
  return $data;
}

# For Create Table :
# ------------------------------------------------------------------------
sub create_table {
  my $self    = shift;
  my $arg_len = scalar @_;
  my $result  = '';

  if ($arg_len >= 3) {
    my $tables = CellBIS::SQL::Abstract::Table->new(db_type => $self->db_type
        // 'mysql');
    $result = $tables->create_query_table(@_);
  }
  return $result;
}

sub _qUpdate_arg3 {
  my $self = shift;
  my ($table_name, $col_val, $clause) = @_;
  my $data = '';

  Carp::croak '$col_val is must be hashref datatype'
    unless ref $col_val eq "HASH";

  if (exists $clause->{where}) {
    my @field = map {
          $col_val->{$_} =~ qr/date|datetime|now|NOW/
        ? $_ . ' = ' . $col_val->{$_}
        : $_ . ' = ' . "'"
        . $col_val->{$_} . "'"
    } keys %{$col_val};
    my $field_change = join ', ', @field;
    my $where_clause = $self->QueryUtil->create_clause($clause);
    $data = "UPDATE $table_name \nSET $field_change \n$where_clause";
  }
  return $data;
}

sub _qUpdate_arg4 {
  my $self = shift;
  my ($table_name, $column, $value, $clause) = @_;
  my $data = '';

  if (exists $clause->{where}) {
    my @get_value = $self->QueryUtil->col_with_val($column, $value);
    my $field_change = join ', ', @get_value;
    my $where_clause = $self->QueryUtil->create_clause($clause);
    $data = "UPDATE $table_name \nSET $field_change \n$where_clause";
  }
  return $data;
}

sub _qUpdate_arg5 {
  my $self = shift;
  my ($table_name, $column, $value, $clause, $type) = @_;
  my $data = '';

  my @table_field  = @{$column};
  my $field_change = '';
  my $where_clause = '';

  if ($type && $type eq 'no-pre-st') {

    if (exists $clause->{where}) {
      my @get_value = $self->QueryUtil->col_with_val($column, $value);
      $field_change = join ', ', @get_value;
      $where_clause = $self->QueryUtil->create_clause($clause);
      $data         = "UPDATE $table_name \nSET $field_change \n$where_clause";
    }

  }
  else {

    if (exists $clause->{where}) {
      $field_change = join '=?, ', @table_field;
      $field_change .= '=?';
      $where_clause = $self->QueryUtil->create_clause($clause);
      $data         = "UPDATE $table_name \nSET $field_change \n$where_clause";
    }
  }
  return $data;
}

# For Action Query String - "select" - arg3 :
# ------------------------------------------------------------------------
sub _qSelect_arg3 {
  my $self = shift;
  my ($table_name, $column, $clause) = @_;
  my $data     = '';
  my @col      = @{$column};
  my $size_col = scalar @col;

  if (ref($clause) eq "HASH") {
    my $field_change;
    my $where_clause;

    my $size_clause = scalar keys %{$clause};

    if ($size_clause != 0) {
      $where_clause = $self->QueryUtil->create_clause($clause);
      if (scalar @col == 0) {
        $data = 'SELECT * FROM ' . $table_name . "\n" . $where_clause;
      }
      else {
        $field_change = ref($column) eq "ARRAY" ? (join ', ', @col) : '*';
        $data
          = 'SELECT '
          . $field_change
          . " \nFROM "
          . $table_name . "\n"
          . $where_clause;
      }

    }
    else {
      if ($size_col == 0) {
        $data = "SELECT * FROM $table_name";
      }
      else {
        $field_change = join ', ', @col;
        $data = "SELECT $field_change FROM $table_name";
      }
    }
  }
  else {
    my $field_change = '';

    if ($size_col == 0) {
      $data = "SELECT * FROM $table_name";
    }
    else {
      $field_change = join ', ', @col;
      $data = "SELECT $field_change FROM $table_name";
    }
  }
  return $data;
}

# For Action Query String - "select_join" - arg3 :
# ------------------------------------------------------------------------
sub _qSelectJoin_arg3 {
  my $self = shift;
  my ($table_name, $column, $clause) = @_;
  my $data = '';

  my $size_col     = scalar @{$column};
  my $field_change = '';
  $field_change = '*' if $size_col == 0;
  $field_change = join ', ', @{$column} if $size_col >= 1;
  my $where_clause = '';
  my $join_clause  = '';

  if (ref($clause) eq "HASH") {
    if (exists $clause->{join}) {
      $join_clause = $self->QueryUtil->for_onjoin($clause, $table_name);
      $where_clause = $self->QueryUtil->create_clause($clause);
      $data = "SELECT $field_change $join_clause" . "\n" . $where_clause;
    }
    else {
      $where_clause = $self->QueryUtil->create_clause($clause);
      $data         = "SELECT $field_change FROM $table_name";
    }
  }
  else {
    $data = "SELECT $field_change FROM $table_name";
  }
  return $data;
}

sub to_one_liner {
  my ($self, $result) = @_;

  $result =~ s/\t+//g;
  $result =~ s/\,\s+/\, /g;
  $result =~ s/\s+/ /g;
  return $result;
}

1;
