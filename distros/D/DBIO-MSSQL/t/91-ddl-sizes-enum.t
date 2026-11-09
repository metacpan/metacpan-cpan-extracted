use strict;
use warnings;
use Test::More;

use DBIO::MSSQL::DDL qw(_mssql_column_type);
use DBIO::MSSQL::Diff::Table;
use DBIO::MSSQL::Diff::Column;

# karr k71 (ADR 0060 cases ddl-type-size-char, ddl-type-size-bit, ddl-enum-value-apostrophe).
#
# WHY: a declared length is the user's data model. 'character' with size 10
# was written bare, which SQL Server reads as char(1): valid SQL, a column ten
# times too narrow. What SQL Server cannot hold at all -- an enum, a bit with
# a length -- is refused with a message that names the place, instead of SQL
# the server rejects ("Cannot find data type enum") or a column that is not
# the one declared.

my @COLS = (
  Sized => [ id => { data_type => "integer" },
             c  => { data_type => "character", size => 10, is_nullable => 1 },
             v  => { data_type => "character varying", size => 12, is_nullable => 1 },
             f  => { data_type => "bit", size => 1, is_nullable => 1 } ],
  Bits  => [ id => { data_type => "integer" },
             b  => { data_type => "bit", size => 8, is_nullable => 1 } ],
  Pick  => [ id => { data_type => "integer" },
             kind => { data_type => "enum", extra => { list => [ "it's", "plain" ] } } ],
);

# one schema class with just the named source
my $n = 0;
sub ddl_for {
  my ($name) = @_;
  my %cols = @COLS;
  my $class = "SzDdl${\ ++$n}";
  eval <<"CODE" or die $@;
package $class;
use DBIO "Schema";
__PACKAGE__->load_components("MSSQL");
package ${class}::Result::$name;
use base "DBIO::Core";
__PACKAGE__->table(lc "$name");
__PACKAGE__->add_columns(\@{ \$cols{$name} });
__PACKAGE__->set_primary_key("id");
1;
CODE
  $class->register_class($name => "${class}::Result::$name");
  return DBIO::MSSQL::DDL->install_ddl($class);
}


like(_mssql_column_type({ data_type => 'character', size => 10 }),
  qr/^n?char\(10\)\z/, 'character with size 10 keeps its length');
is(_mssql_column_type({ data_type => 'char', size => 10 }),
  _mssql_column_type({ data_type => 'character', size => 10 }),
  'character is char');
like(_mssql_column_type({ data_type => 'character varying', size => 12 }),
  qr/^n?varchar\(12\)\z/, 'character varying keeps its length');
is(_mssql_column_type({ data_type => 'bit' }), 'bit', 'bit without size');
is(_mssql_column_type({ data_type => 'bit', size => 1 }), 'bit', 'bit with size 1');

{
  my $ddl = ddl_for("Sized");
  like($ddl, qr/\bc n?char\(10\)/, "install_ddl writes char(10)");
  like($ddl, qr/\bv n?varchar\(12\)/, "install_ddl writes varchar(12)");
  like($ddl, qr/\bf bit\b/, "bit with size 1 is bit");
}

for my $case (
  [ Bits => qr/table .bits.*column .b.*.bit.*no length/s, "bit with size 8" ],
  [ Pick => qr/.enum.*table .pick.*column .kind.*no enum type.*varchar/s, "enum" ],
) {
  my ($name, $re, $label) = @$case;
  eval { ddl_for($name) };
  like($@, $re, "install_ddl refuses $label, naming table, column, type, reason");
}


for my $info ({ data_type => 'enum', list => [1] }, { data_type => "enum('a','b')" }) {
  eval { _mssql_column_type($info) };
  like($@, qr/'enum'.*no enum type/, "enum refused: $info->{data_type}");
}

# the diff ops are the same function
eval {
  DBIO::MSSQL::Diff::Table->new(action => 'create', table_name => 'pick',
    columns => [ { column_name => 'kind', data_type => 'enum' } ])->as_sql;
};
like($@, qr/table 'pick'.*column 'kind'.*enum/s, 'Diff::Table refuses enum');
eval {
  DBIO::MSSQL::Diff::Column->new(action => 'add', table_name => 'pick',
    column_name => 'b', new_info => { data_type => 'bit', size => 8 })->as_sql;
};
like($@, qr/table 'pick'.*column 'b'.*bit.*no length/s, 'Diff::Column add refuses bit(8)');

done_testing;
