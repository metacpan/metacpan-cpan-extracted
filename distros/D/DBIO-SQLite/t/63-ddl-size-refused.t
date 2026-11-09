use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::SQLite::DDL;

# karr k75 -- a size the column's base type cannot read is refused, loud.
#
# DBIO::Schema::Type::canonical_column croaks on a size that is neither a
# scalar nor an arrayref (a hashref, a code ref): it would reach the SQL as a
# stringified address. _sqlite_column_type used to wrap that call in an eval
# and went on silently down the alias path, which wrote something else --
# TIMESTAMP for a timestamp (the portable base type is TEXT), CHAR(HASH(0x..))
# for a char. The refusal belongs to whoever asks for the DDL.

# One schema class per call: sources register on the class, and a second
# column of the same table name would be skipped as already seen.
my $N = 0;
sub schema_with {
  my ($data_type, $size) = @_;
  my $schema = "SizeRefused" . ++$N;
  my $result = "${schema}::Result::Item";
  {
    no strict 'refs';
    @{"${schema}::ISA"} = ('DBIO::Schema');
    @{"${result}::ISA"} = ('DBIO::Core');
  }
  $schema->load_components('SQLite');
  $result->table('item');
  $result->add_columns(
    id => { data_type => 'integer' },
    c  => { data_type => $data_type, size => $size },
  );
  $result->set_primary_key('id');
  $schema->register_class(Item => $result);
  return $schema->connect(sub { die 'no connection needed' });
}

for my $type (qw(timestamp char)) {
  for my $size ({ p => 3 }, sub { 3 }, \3) {
    my $what = ref $size;
    throws_ok { DBIO::SQLite::DDL->install_ddl(schema_with($type, $size)) }
      qr/size for column 'c' \(base type '$type'\) must be a scalar or an arrayref, got a $what reference/,
      "$type with a $what reference as size is refused, naming the column";
  }
}

# What is accepted stays accepted.
for my $case (
  [ timestamp => 3,      'TEXT' ],
  [ timestamp => [3],    'TEXT' ],
  [ timestamp => undef,  'TEXT' ],
  [ char      => 24,     'CHAR(24)' ],
  [ char      => [24],   'CHAR(24)' ],
  [ char      => undef,  'CHAR(255)' ],
) {
  my ($type, $size, $native) = @$case;
  my $ddl = DBIO::SQLite::DDL->install_ddl(schema_with($type, $size));
  like($ddl, qr/"c" \Q$native\E[,\s]/,
    "$type with size " . (defined $size ? (ref $size ? '[' . join(',', @$size) . ']' : $size) : 'undef')
    . " is $native");
}

done_testing;
