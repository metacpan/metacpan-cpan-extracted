use strict;
use warnings;
use Test::More;

use DBIO::MySQL::DDL;

# OFFLINE half of karr k120, found by the shared conformance table (t/157, core
# ADR 0060): three declarations install_ddl wrote wrong.
#
# WHY IT MATTERS. (1) An enum column wrote the bare word `enum`: the members of
# extra => { list => [...] } were dropped and the server refused the table (1064).
# (2) A bit column with a size wrote `bit`, which the server reads as BIT(1):
# the width declared was not the width kept. (3) An index over exactly the
# columns of a unique constraint was written beside it, a second index for the
# lookups the UNIQUE key serves already. Claims:
#   a. enum and set list their members, an apostrophe or a backslash in one
#      member escaped, so it is the member and not the end of the list;
#   b. bit(M) keeps the size;
#   c. an index over the columns of a unique constraint (same order) is not
#      written; another order, a subset and a FULLTEXT index are.

{
  package K120::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MySQL');
}
{
  package K120::Schema::Result::Pick;
  use DBIO 'Core', -mysql;
  __PACKAGE__->table('pick');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer' },
    kind => { data_type => 'enum', extra => { list => [ "it's", 'plain', 'a\\b' ] } },
    tags => { data_type => 'set',  is_nullable => 1, extra => { list => [ 'x', 'y' ] } },
    b    => { data_type => 'bit',  is_nullable => 1, size => 8 },
    b1   => { data_type => 'bit',  is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  K120::Schema->register_class(Pick => __PACKAGE__);
}
{
  package K120::Schema::Result::Child;
  use DBIO 'Core', -mysql;
  __PACKAGE__->table('child');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer' },
    a  => { data_type => 'integer' },
    b  => { data_type => 'integer' },
    t  => { data_type => 'text', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(child_ab => [ 'a', 'b' ]);
  __PACKAGE__->mysql_index(dup_ab  => { columns => [ 'a', 'b' ] });
  __PACKAGE__->mysql_index(order_ba => { columns => [ 'b', 'a' ] });
  __PACKAGE__->mysql_index(only_a  => { columns => ['a'] });
  __PACKAGE__->mysql_index(ft_t    => { columns => ['t'], using => 'FULLTEXT' });
  K120::Schema->register_class(Child => __PACKAGE__);
}

my $ddl = DBIO::MySQL::DDL->install_ddl('K120::Schema');
my ($pick)  = grep { /CREATE TABLE `pick`/ } split /\n\n/, $ddl;
my ($child) = $ddl;

like $pick, qr/^\s*`kind` enum\('it''s','plain','a\\\\b'\) NOT NULL,$/m,
  'a: enum lists its members, the apostrophe doubled and the backslash doubled';
like $pick, qr/^\s*`tags` set\('x','y'\),$/m, 'a: so does set';
like $pick, qr/^\s*`b` bit\(8\),$/m, 'b: bit keeps its size';
like $pick, qr/^\s*`b1` bit,$/m, 'b: a bit without size stays as it was';

like $child, qr/UNIQUE KEY `child_ab` \(`a`, `b`\)/, 'c: the unique constraint is written';
unlike $child, qr/`dup_ab`/, 'c: an index over its columns is not';
like $child, qr/INDEX `order_ba` ON `child` \(`b`, `a`\)/, 'c: another column order is';
like $child, qr/INDEX `only_a` ON `child` \(`a`\)/, 'c: a subset is';
like $child, qr/FULLTEXT INDEX `ft_t`/, 'c: a FULLTEXT index is';

done_testing;
