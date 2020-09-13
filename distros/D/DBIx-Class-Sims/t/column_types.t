# vi:sw=2
use strictures 2;

use Test2::V0 qw( done_testing is like cmp_ok );
use Test::Trap; # Needed for trap()

my %types;
BEGIN {
  %types = (
    numeric => [qw(
      tinyint smallint mediumint bigint
      int integer int1 int2 int3 int4 int8 middleint
      bool boolean
    )],
    decimal => [qw(
      float float4 float8
      real
      double
      decimal dec
      numeric
      fixed
    )],
    string => [qw(
      char varchar varchar2
      binary varbinary
      text tinytext mediumtext longtext long
      blob tinyblob mediumblob longblob
    )],
    # These will be unhandled because SQLite doesn't have any column types other
    # than NULL, INTEGER, REAL, TEXT, and BLOB
    datetime => [qw(
      date
      datetime
      timestamp
      year
    )],
    unknown => [qw(
      enum set bit json
      geometry point linestring polygon
      multipoint multilinestring multipolygon geometrycollection
    )],
  );

  {
    package MyApp::Schema::Result::ColumnTests;
    use base 'DBIx::Class::Core';
    __PACKAGE__->table('column_tests');
    __PACKAGE__->add_columns(
      id => {
        data_type => 'int',
        is_nullable => 0,
        is_auto_increment => 1,
      },
      (
        map {
          ("col_$_" => { data_type => $_, is_nullable => 0 })
        } @{$types{numeric}}
      ),
      (
        map {
          ("col_$_" => { data_type => $_, is_nullable => 0 })
        } @{$types{decimal}}
      ),
      (
        map {
          ("col_$_" => { data_type => $_, is_nullable => 0 })
        } @{$types{string}}
      ),
    );
    __PACKAGE__->set_primary_key('id');
  }


  {
    package MyApp::Schema;
    use base 'DBIx::Class::Schema';
    __PACKAGE__->register_class(ColumnTests => 'MyApp::Schema::Result::ColumnTests');
    __PACKAGE__->load_components('Sims');
  }
}

use Test::DBIx::Class qw(:resultsets);

{
  my $count = grep { $_ != 0 } map { ResultSet($_)->count } Schema->sources;
  is $count, 0, "There are no tables loaded at first";
}

trap {
  Schema->load_sims(
    {
      ColumnTests => [{}],
    },
  );
};
my $continue = is $trap->leaveby, 'return', "load_sims runs to completion";

# Don't bother continuing if we didn't succeed in load_sims().
if ($continue) {
  is( ColumnTests->count, 1, 'The number of rows is correct' );

  my $row = ColumnTests->first;

  foreach my $name (@{$types{numeric}}) {
    my $colname = "col_${name}";
    my $value = $row->$colname;
    my %comparisons = ( '>=' => 0, '<=' => 100 );
    while (my ($op, $val) = each %comparisons) {
      cmp_ok( $value, $op, $val, "numeric type $name ($value $op $val)" );
    }
  }

  foreach my $name (@{$types{decimal}}) {
    my $colname = "col_${name}";
    my $value = $row->$colname;
    my %comparisons = ( '>=' => 0.0, '<=' => 100.0 );
    while (my ($op, $val) = each %comparisons) {
      cmp_ok( $value, $op, $val, "decimal type $name ($value $op $val)" );
    }
  }

  foreach my $name (@{$types{string}}) {
    my $colname = "col_${name}";
    my $value = $row->$colname;
    like( $value, qr/\w{1,1}/, "string type $name ($value) correct" );
  }
}

done_testing;
