#sql-translator.t
use strict;
use warnings;
use Test::More;
use List::Util qw(first);

unless (eval { require SQL::Translator }) {
  plan(skip_all => 'SQL::Translator is required for this test');
}
{
  package CDs;
  use strict;
  use warnings;
  use 5.010;
  use base qw(ActiveRecord::Simple);
  my $class = __PACKAGE__;
  $class->table_name(lc $class);
  $class->fields(
    id => {
      data_type         => 'int',
      is_auto_increment => 1,
      is_primary_key    => 1,
    },
    title => {
      data_type   => 'varchar',
      is_nullable => 0,
      size        => 64,
    }
  );

}
ok((first { $_ eq 'id' },    @{CDs->_get_columns}), 'id column exists');
ok((first { $_ eq 'title' }, @{CDs->_get_columns}), 'title column exists');
like(CDs->as_sql, qr/CREATE\sTABLE/x);
done_testing;
