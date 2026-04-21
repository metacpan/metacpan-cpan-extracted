package DBIx::Wizard::DB::Table;

use strict;
use DBIx::Wizard::DB;

my %h_desc;
my %h_auto_pk;
my %h_time_columns_href;
my %h_decimal_columns_href;

sub desc {
  my ($class, $db, $table) = @_;

  if (exists $h_desc{$db}{$table}) {
    return $h_desc{$db}{$table};
  }

  my $dbh = DBIx::Wizard::DB->dbh($db);
  my $driver = $dbh->{Driver}->{Name};

  my ($sth, $ra_desc);

  if ($driver eq 'SQLite') {
    $sth = $dbh->prepare("PRAGMA table_info($table)");
    $sth->execute();
    my $ra_pragma = $sth->fetchall_arrayref({});
    # Normalize to MySQL-like format: Field, Type, Null, Key, Default, Extra
    $ra_desc = [ map {{
      Field   => $_->{name},
      Type    => lc($_->{type} || ''),
      Null    => $_->{notnull} ? 'NO' : 'YES',
      Key     => $_->{pk} ? 'PRI' : '',
      Default => $_->{dflt_value},
      Extra   => ($_->{pk} && lc($_->{type} || '') eq 'integer') ? 'auto_increment' : '',
    }} @$ra_pragma ];
  } else {
    $sth = $dbh->prepare("DESC " . $table);
    $sth->execute();
    $ra_desc = $sth->fetchall_arrayref({});
  }

  $h_desc{$db}{$table} = $ra_desc;

  return $ra_desc;
}

sub column_names {
  my ($class, $db, $table) = @_;

  my $ra_desc = $class->desc($db, $table);

  return map { $_->{Field} } @$ra_desc;
}

sub auto_pk {
  my ($class, $db, $table) = @_;

  if (exists $h_auto_pk{$db}{$table}) {
    return $h_auto_pk{$db}{$table};
  }

  my $ra_desc = $class->desc($db, $table);

  my $auto_pk;

  for my $rh_column_info (@$ra_desc) {
    if (_is_auto_pk_column($rh_column_info)) {
      $auto_pk = $rh_column_info->{Field};
    }
  }

  $h_auto_pk{$db}{$table} = $auto_pk;

  return $auto_pk;
}

sub _is_auto_pk_column {
  my $rh_column_info = shift;

  return exists $rh_column_info->{Extra} &&
         $rh_column_info->{Extra} eq 'auto_increment';
}

sub time_columns_href {
  my ($class, $db, $table) = @_;

  if (exists $h_time_columns_href{$db}{$table}) {
    return $h_time_columns_href{$db}{$table};
  }

  my $ra_desc = $class->desc($db, $table);

  my $rh_time_columns = {};

  for my $rh_column_info (@$ra_desc) {
    if (exists $rh_column_info->{Type} && exists $rh_column_info->{Field}) {
      if ($rh_column_info->{Type} eq 'datetime' ||
          $rh_column_info->{Type} eq 'date' ||
          $rh_column_info->{Type} eq 'timestamp') {
        $rh_time_columns->{$rh_column_info->{Field}} = $rh_column_info->{Type};
      }
    } elsif (exists $rh_column_info->{type} && exists $rh_column_info->{name}) {
      ## ClickHouse 22+ via MySQL interface
      if ($rh_column_info->{type} eq 'DateTime' ||
          $rh_column_info->{type} eq 'Date') {
        $rh_time_columns->{$rh_column_info->{name}} = lc($rh_column_info->{type});
      }
    }
  }

  $h_time_columns_href{$db}{$table} = $rh_time_columns;

  return $rh_time_columns;
}

sub decimal_columns_href {
  my ($class, $db, $table) = @_;

  if (exists $h_decimal_columns_href{$db}{$table}) {
    return $h_decimal_columns_href{$db}{$table};
  }

  my $ra_desc = $class->desc($db, $table);

  my $rh_decimal_columns = {};

  for my $rh_column_info (@$ra_desc) {
    if ($rh_column_info->{Type} =~ m/decimal/i) {
      $rh_decimal_columns->{$rh_column_info->{Field}} = $rh_column_info->{Type};
    }
  }

  $h_decimal_columns_href{$db}{$table} = $rh_decimal_columns;

  return $rh_decimal_columns;
}

1;
