use strict;
use warnings;
use Test::More;

use DBIO::MySQL::DDL;

sub build {
  my ($tag, $order) = @_;
  my $ns = "RelOrder$tag";

  eval qq{
    package ${ns}::Schema;
    use DBIO 'Schema';
    __PACKAGE__->load_components('MySQL');

    package ${ns}::Schema::Result::$_;
    use DBIO;
    __PACKAGE__->table(lc '$_');
    __PACKAGE__->add_columns(id => { data_type => 'integer', is_auto_increment => 1 });
    __PACKAGE__->set_primary_key('id');
    1;
  } or die $@ for qw(Alpha Beta);

  eval qq{
    package ${ns}::Schema::Result::Child;
    use DBIO;
    __PACKAGE__->table('child');
    __PACKAGE__->add_columns(
      id       => { data_type => 'integer', is_auto_increment => 1 },
      alpha_id => { data_type => 'integer' },
      beta_id  => { data_type => 'integer' },
    );
    __PACKAGE__->set_primary_key('id');
    1;
  } or die $@;

  my %rel = (
    alpha => sub { "${ns}::Schema::Result::Child"->belongs_to(alpha => "${ns}::Schema::Result::Alpha", 'alpha_id') },
    beta  => sub { "${ns}::Schema::Result::Child"->belongs_to(beta  => "${ns}::Schema::Result::Beta",  'beta_id') },
  );
  $rel{$_}->() for @$order;

  "${ns}::Schema"->register_class($_ => "${ns}::Schema::Result::$_") for qw(Alpha Beta Child);
  return DBIO::MySQL::DDL->install_ddl("${ns}::Schema");
}

# karr k96 point 2. _mysql_column_type delegates the portable base types to
# DBIO::Schema::Type::canonical_column. That function refuses a column whose
# declaration is broken (a size that is neither a scalar nor an arrayref). The
# refusal used to be swallowed by an eval, and the column fell into the legacy
# alias path: a timestamp with a broken size came out as the bare alias, as if
# it had been declared without a size at all. A broken declaration is the
# caller's error and has to arrive there, not be rendered as a different column.
subtest 'ddl-column-declaration-error' => sub {
  for my $type (qw(timestamp char numeric)) {
    my $ok = eval {
      DBIO::MySQL::DDL::_mysql_column_type({ data_type => $type, size => {} });
      1;
    };
    ok !$ok, "$type with a hashref size is refused";
    like $@, qr/size for column .* must be a scalar or an arrayref, got a HASH reference/,
      "$type: the refusal is core's, naming the declaration";
  }

  # The same refusal reaches install_ddl, i.e. whoever deploys the schema.
  {
    package K96::Schema;
    use DBIO 'Schema';
    __PACKAGE__->load_components('MySQL');
  }
  {
    package K96::Schema::Result::Ev;
    use DBIO;

    __PACKAGE__->table('ev');
    __PACKAGE__->add_columns(
      id => { data_type => 'integer', is_auto_increment => 1 },
      at => { data_type => 'timestamp', size => {} },
    );
    __PACKAGE__->set_primary_key('id');
  }
  K96::Schema->register_class(Ev => 'K96::Schema::Result::Ev');

  my $ddl = eval { DBIO::MySQL::DDL->install_ddl('K96::Schema') };
  like $@, qr/must be a scalar or an arrayref/, 'install_ddl does not render the column as a bare alias'
    or diag $ddl;

  # What stays: well-formed declarations render as before.
  is(DBIO::MySQL::DDL::_mysql_column_type({ data_type => 'char', size => [10] }),
    'CHAR(10)', 'a well-formed size still renders');
};

# karr k96 point 4. DDL walks $source->relationships to derive the foreign
# keys. Since core 7e64e7e6b that list is sorted by name, so the DDL of a
# table does not depend on the order in which its belongs_to were declared.
# This pins the property on this side: the same schema declared with its
# relationships in opposite order yields the same script.
subtest 'ddl-relationship-order' => sub {
  my $forward = build('Fwd', [qw(alpha beta)]);
  my $reverse = build('Rev', [qw(beta alpha)]);

  like $forward, qr/FOREIGN KEY/, 'the script carries the foreign keys';
  is $reverse, $forward, 'relationships declared in the opposite order give the same script';
};

# OFFLINE half of karr k115 (t/142 has the live half): the type
# uniqueidentifier, as DBIO::Test::Schema::ArtistGUID declares it.
#
# WHY IT MATTERS. MySQL and MariaDB have no uniqueidentifier. install_ddl wrote
# the name through, so the CREATE TABLE of the shared test schema was refused
# (1064) and nothing that deploys it could run. The family spells a GUID as its
# string form, VARCHAR(36) (dbio-sybase k52). AUTO_INCREMENT is for integers
# only: a GUID column that asks for is_auto_increment (the key of ArtistGUID,
# whose value the storage generates, not the server) must not get it, or the
# server refuses the table as well (1063).
subtest 'ddl-uniqueidentifier' => sub {
  {
    package K115::Schema;
    use DBIO 'Schema';
    __PACKAGE__->load_components('MySQL');
  }
  {
    package K115::Schema::Result::Guid;
    use DBIO 'Core', -mysql;
    __PACKAGE__->table('guid_t');
    __PACKAGE__->add_columns(
      id   => { data_type => 'uniqueidentifier', is_auto_increment => 1 },
      alt  => { data_type => 'uniqueidentifier', is_nullable => 1, size => 99 },
      up   => { data_type => 'UniqueIdentifier', is_nullable => 1 },
      n    => { data_type => 'int', is_auto_increment => 0 },
      memo => { data_type => 'clob', is_nullable => 1 },
      cost => { data_type => 'money', is_nullable => 1 },
    );
    __PACKAGE__->set_primary_key('id');
    K115::Schema->register_class(Guid => __PACKAGE__);
  }
  {
    package K115::Schema::Result::Count;
    use DBIO 'Core', -mysql;
    __PACKAGE__->table('count_t');
    __PACKAGE__->add_columns(id => { data_type => 'int', is_auto_increment => 1 });
    __PACKAGE__->set_primary_key('id');
    K115::Schema->register_class(Count => __PACKAGE__);
  }

  my $ddl = DBIO::MySQL::DDL->install_ddl('K115::Schema');
  my ($guid)  = grep { /`guid_t`/ } split /\n\n/, $ddl;
  my ($count) = grep { /`count_t`/ } split /\n\n/, $ddl;

  unlike $guid, qr/uniqueidentifier/i, 'the server has no such type, it is not written';
  like $guid, qr/^\s*`id` varchar\(36\) NOT NULL,$/m, 'a: the key is VARCHAR(36), without AUTO_INCREMENT';
  like $guid, qr/^\s*`alt` varchar\(36\),$/m, 'b: a size on it does not move the width';
  like $guid, qr/^\s*`up` varchar\(36\),$/m, 'c: the type name is read case-insensitive';
  unlike $guid, qr/AUTO_INCREMENT/, 'd: no AUTO_INCREMENT on a string column';
  like $count, qr/`id` int NOT NULL AUTO_INCREMENT/i, 'e: an integer column keeps AUTO_INCREMENT';

  # The shared test schema declares two more names the server does not know,
  # found when it was deployed live (t/142): clob and money.
  like $guid, qr/^\s*`memo` longtext,$/m, 'f: clob is LONGTEXT';
  like $guid, qr/^\s*`cost` decimal\(19,4\),$/m, 'g: money is DECIMAL(19,4)';
};

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
subtest 'ddl-enum-bit-unique-index' => sub {
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
};

done_testing;
