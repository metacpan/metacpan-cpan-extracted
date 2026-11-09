use strict;
use warnings;

use Test::More;
our $N;

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::Sybase::DDL qw(sybase_column_type);

# karr k97 (conformance, core ADR 0060). What ASE cannot hold is refused by
# install_ddl before the server is asked, naming table and column, in the words
# "refused" and the reason -- where the server's own answers were
#
#   enum             Msg 2715 "Can't find type 'ENUM'"
#   bit(8)           the size dropped, silently
#   a nullable bit   Msg 2718 "can't specify Null values on a column of type BIT"
#   double           Msg 2715 "Can't find type 'DOUBLE'" (ASE says DOUBLE PRECISION)
#   other.t          Msg 2734 (a dot is owner.name; refused by Quote, k92)

is sybase_column_type('double'), 'DOUBLE PRECISION', 'double is DOUBLE PRECISION';

sub schema_with {
  my ($table, @columns) = @_;
  my $n = ++$main::N;
  my $result = "K97::R$n";
  my $schema = "K97::S$n";
  {
    no strict 'refs';
    @{"${result}::ISA"} = ('DBIO::Core');
    @{"${schema}::ISA"} = ('DBIO::Schema');
  }
  $result->table($table);
  $result->add_columns(id => { data_type => 'integer', is_nullable => 0 }, @columns);
  $result->set_primary_key('id');
  $schema->register_class(T => $result);
  return $schema;
}

sub refusal {
  my ($table, @columns) = @_;
  my $schema = schema_with($table, @columns);
  return eval { DBIO::Sybase::DDL->install_ddl($schema); 1 } ? '' : "$@";
}

my $enum = refusal('pick',
  kind => { data_type => 'enum', extra => { list => [ 'a', 'b' ] }, is_nullable => 0 });
like $enum, qr/is refused/, 'enum: refused';
like $enum, qr/\btable 'pick'/, '... naming the table';
like $enum, qr/\bcolumn 'kind'/, '... and the column';
like $enum, qr/type 'enum'.*is refused: ASE has no enum type/s, '... and the reason';

my $size = refusal('sized', b => { data_type => 'bit', size => 8, is_nullable => 0 });
like $size, qr/\btable 'sized', column 'b'/, 'bit(8): names table and column';
like $size, qr/size '8' on type 'bit'.*is refused: bit has no length in ASE/s, '... and refuses the size';

my $null = refusal('flags', f => { data_type => 'boolean', is_nullable => 1 });
like $null, qr/\btable 'flags', column 'f'/, 'a nullable boolean: names table and column';
like $null, qr/NULL in a bit column is refused: ASE cannot hold NULL in a BIT column \(Msg 2718\)/,
  '... and refuses it, naming the server message';

is refusal('flags', f => { data_type => 'boolean', is_nullable => 0 }), '',
  'a boolean NOT NULL is written';
is refusal('flags', f => { data_type => 'bit' }), '', '... so is a bit without is_nullable (NOT NULL by ADR 0043)';
is refusal('sized', b => { data_type => 'varchar', size => 8, is_nullable => 1 }), '',
  'a size on a varchar is no business of this check';

my $dot = refusal('other.t');
like $dot, qr/a name with a dot is refused/, 'other.t: refused';
like $dot, qr/'other\.t'/, '... naming the table';

done_testing;
