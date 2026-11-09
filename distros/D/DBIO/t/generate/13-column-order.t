use strict;
use warnings;
use Test::More;
use File::Temp qw/tempdir/;

use DBIO::Generate;

# The generated Result class lists its columns in the order the introspect
# model holds them (the table's declared order), not alphabetically.

{
  package Test::Gen::OrderIntrospect;
  use base 'DBIO::Introspect::Base';

  sub _build_model {
    return {
      columns => {
        things => [
          { column_name => 'zeta',  data_type => 'integer', is_pk => 1 },
          { column_name => 'beta',  data_type => 'varchar', size => 20 },
          { column_name => 'alpha', data_type => 'integer' },
          { column_name => 'mid',   data_type => 'integer' },
        ],
      },
    };
  }
  sub table_keys { ['things'] }
  sub table_pk_info { ['zeta'] }
  sub table_uniq_info { [] }
  sub table_fk_info { [] }
  sub table_is_view { 0 }
  sub result_class_extra_statements { () }
}

my @declared = qw/zeta beta alpha mid/;

is_deeply(Test::Gen::OrderIntrospect->new(dbh => 'fake')->table_columns('things'),
  \@declared, 'Introspect::Base::table_columns keeps the model order');

for my $style (qw/vanilla candy cake/) {
  my $dir = tempdir(CLEANUP => 1);
  DBIO::Generate->new(
    schema_class   => 'My::Order',
    dump_directory => $dir,
    style          => $style,
    use_namespaces => 1,
    generate_pod   => 0,
  )->dump(Test::Gen::OrderIntrospect->new(dbh => 'fake'));

  my $file = "$dir/My/Order/Result/Thing.pm";
  open my $fh, '<', $file or BAIL_OUT "no $file: $!";
  my $src = do { local $/; <$fh> };
  close $fh;

  my @seen = $src =~ /^\s*(?:has_column\s+|col\s+)?['"]?(zeta|beta|alpha|mid)['"]?\s*(?:=>|,)/mg;
  is_deeply \@seen, \@declared, "$style: columns emitted in model order"
    or diag $src;
}

done_testing;
