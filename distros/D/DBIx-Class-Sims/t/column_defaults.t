# vi:sw=2
use strictures 2;

use Test::More;
use Test::Exception;

# This currently cannot be converted to build_schema() because the functions
# are not coming across properly. Figure something out later.
BEGIN {
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
      int_maxmin => {
        data_type => 'int',
        sim => {
          min => 5, max => 20,
        },
      },
      int_nomin => {
        data_type => 'int',
        sim => {
          max => 20,
        },
      },
      int_nomax => {
        data_type => 'int',
        sim => {
          min => 5,
        },
      },
      int_nolimit => {
        data_type => 'int',
        sim => {},
      },
      int_with_func => {
        data_type => 'int',
        sim => {
          func => sub {
            return 22;
          },
        },
      },
      varchar_maxmin => {
        data_type => 'varchar',
        sim => {
          min => 5, max => 20,
        },
      },
      varchar_nomin => {
        data_type => 'varchar',
        sim => {
          max => 20,
        },
      },
      varchar_nomax_length => {
        data_type => 'varchar',
        data_length => '60',
        sim => {
          min => 5,
        },
      },
      varchar_nomax_nolength => {
        data_type => 'varchar',
        sim => {
          min => 5,
        },
      },
      varchar_nolimit => {
        data_type => 'varchar',
        sim => {},
      },
      varchar_with_func => {
        data_type => 'varchar',
        data_length => 20,
        sim => {
          func => sub {
            return 'abcd';
          },
        },
      },
      us_zipcode => {
        data_type => 'varchar',
        data_length => 9,
        sim => {
          type => 'us_zipcode',
        },
      },
      us_zipcode_as_char => {
        data_type => 'char',
        data_length => 9,
        sim => {
          type => 'us_zipcode',
        },
      },
      us_zipcode_as_int => {
        data_type => 'int',
        data_length => 9,
        sim => {
          type => 'us_zipcode',
        },
      },
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

lives_ok {
  Schema->load_sims(
    {
      ColumnTests => [
        {},
      ],
    },
  );
} "load_sims runs to completion";

is( ColumnTests->count, 1, 'The number of rows is correct' );

my $row = ColumnTests->first;

is( $row->id, 1, 'The id is correct' );

cmp_ok( $row->int_maxmin, '>=', 5, 'int_maxmin >= 5' );
cmp_ok( $row->int_maxmin, '<=', 20, 'int_maxmin <= 20' );

cmp_ok( $row->int_nomin, '>=', 0, 'sim_int_nomin >= 0' );
cmp_ok( $row->int_nomin, '<=', 20, 'sim_int_nomin <= 20' );

cmp_ok( $row->int_nomax, '>=', 5, 'sim_int_nomax >= 5' );
cmp_ok( $row->int_nomax, '<=', 100, 'sim_int_nomax <= 100' );

cmp_ok( $row->int_nolimit, '>=', 0, 'sim_int_nolimit >= 0' );
cmp_ok( $row->int_nolimit, '<=', 100, 'sim_int_nolimit <= 100' );

is( $row->int_with_func, 22, 'sim_int_with_func is 22' );

like( $row->varchar_maxmin, qr/\w{5,20}/, 'varchar_maxmin of right length' );
like( $row->varchar_nomin, qr/\w{1,20}/, 'varchar_nomin of right length' );
like( $row->varchar_nomax_length, qr/\w{1,60}/, 'varchar_nomax_length of right length' );
like( $row->varchar_nomax_nolength, qr/\w{1,255}/, 'varchar_nomax_nolength of right length' );
like( $row->varchar_nolimit, qr/\w{1,255}/, 'varchar_nolimit of right length' );

is( $row->varchar_with_func, 'abcd', 'sim_varchar_with_func is abcd' );

like( $row->us_zipcode, qr/^\d{4,9}$/, 'us_zipcode is correct' );
like( $row->us_zipcode_as_char, qr/^\d{1,9}$/, 'us_zipcode is correct' );
like( $row->us_zipcode_as_int, qr/^\d{1,5}$/, 'us_zipcode is correct' );

done_testing;
