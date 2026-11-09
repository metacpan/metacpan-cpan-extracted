use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
  eval { require DBD::SQLite; 1 } or plan skip_all => 'DBD::SQLite required';
}

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::ResultSource::View ();
use DBIO::SQLite::DDL ();
use DBIO::SQLite::Deploy ();
use DBIO::SQLite::Diff ();

# karr k79, shared case ddl-qualified-source-name. SQLite has no schemas to
# qualify a name with, and table('other.t') as a string used to create one
# table whose name is literally other.t. A string name with a dot is refused,
# before any statement is written, with the pointer to the scalar-ref form,
# which is literal SQL by the schema's own declaration and stays as it is.

my $n = 0;
sub schema_with {
  my (%arg) = @_;
  my $ns = 'Qual' . ++$n;
  my $code = "package ${ns}::Schema; use base 'DBIO::Schema'; "
    . "__PACKAGE__->load_components('SQLite');\n";
  my @monikers;
  for my $src (@{ $arg{sources} }) {
    my ($moniker, $name, $extra) = @$src;
    push @monikers, $moniker;
    $code .= "package ${ns}::Result::$moniker; use base 'DBIO::Core';\n";
    $code .= "__PACKAGE__->table_class('DBIO::ResultSource::View');\n"
      if $extra && $extra->{view};
    $code .= "__PACKAGE__->table($name);\n";
    if ($extra && $extra->{view}) {
      $code .= "__PACKAGE__->result_source_instance->is_virtual("
        . ($extra->{virtual} ? 1 : 0) . ");\n"
        . "__PACKAGE__->result_source_instance->view_definition('SELECT 1 AS id');\n";
    }
    $code .= "__PACKAGE__->add_columns(id => { data_type => 'integer', is_auto_increment => 1 });\n"
      . "__PACKAGE__->set_primary_key('id');\n";
    if ($extra && $extra->{belongs_to}) {
      $code .= "__PACKAGE__->add_columns(parent_id => { data_type => 'integer' });\n"
        . "__PACKAGE__->belongs_to(parent => '${ns}::Result::$extra->{belongs_to}', 'parent_id');\n";
    }
  }
  $code .= "package ${ns}::Schema;\n"
    . join '', map { "__PACKAGE__->register_class($_ => '${ns}::Result::$_');\n" } @monikers;
  eval "$code; 1" or die $@;
  return "${ns}::Schema";
}

# --- the refusal

my $qualified = schema_with(sources => [ [ Qualified => q{'other.t'} ] ]);
throws_ok { DBIO::SQLite::DDL->install_ddl($qualified) }
  qr/refus.*'other\.t'.*\\'other\.t'/s,
  'table(\'other.t\') is refused, naming the name and the scalar-ref form';
isa_ok $@, 'DBIO::Exception', 'the refusal';
ok !$@->isa('DBIO::Exception::Server'), 'and is the driver\'s, not the server\'s';

{
  my $schema = $qualified->connect('dbi:SQLite::memory:');
  throws_ok { $schema->deploy } qr/refus.*'other\.t'/s, 'deploy refuses it';
  my $tables = $schema->storage->dbh->selectcol_arrayref(
    q{SELECT name FROM sqlite_master WHERE type = 'table'});
  is_deeply $tables, [], 'and has created nothing';
  throws_ok { DBIO::SQLite::Deploy->new(schema => $schema)->diff }
    qr/refus.*'other\.t'/s, 'so does the diff, which builds its target from the same DDL';
}

# --- every place a name goes in

throws_ok {
  DBIO::SQLite::DDL->install_ddl(schema_with(sources => [
    [ Parent => q{'other.p'} ],
    [ Child  => q{'child'}, { belongs_to => 'Parent' } ],
  ]))
} qr/refus.*'other\.p'/s, 'the target of a foreign key is a name like any other';

throws_ok {
  DBIO::SQLite::DDL->install_ddl(schema_with(sources => [
    [ V => q{'other.v'}, { view => 1 } ],
  ]))
} qr/refus.*'other\.v'/s, 'a view is refused the same way';

lives_ok {
  DBIO::SQLite::DDL->install_ddl(schema_with(sources => [
    [ V => q{'other.v'}, { view => 1, virtual => 1 } ],
  ]))
} 'a virtual view has no database object and no name to refuse';

throws_ok {
  DBIO::SQLite::Diff->target_from_compiled({ tables => { 'other.t' => {
    table_name => 'other.t', columns => [], primary_key => [],
  } } })
} qr/refus.*'other\.t'/s, 'a compiled model with such a name is refused too';

# --- what is not refused

{
  my $ddl = DBIO::SQLite::DDL->install_ddl(schema_with(sources => [
    [ Lit => q{\\'main.lit'} ],
    [ Odd => q{'odd "t" `n`'} ],
    [ Spc => q{'My Table'} ],
  ]));
  like $ddl, qr/^CREATE TABLE main\.lit \(/m,
    'a scalar-ref name with a dot is literal SQL and is written as given';
  like $ddl, qr/^CREATE TABLE "My Table" \(/m, 'a name with a space is a name';
  like $ddl, qr/^CREATE TABLE "odd ""t"" `n`" \(/m, 'so are quotes in it';
}

done_testing;
