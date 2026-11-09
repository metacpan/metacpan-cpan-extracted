use strict;
use warnings;
use Test::More;

# Offline: install_ddl reads the canonical index declaration of the result
# source (Cake idx, indices; ADR 0061 in core, karr k51). It used to read none,
# so a class declaring its indexes that way got its CREATE TABLE and no index,
# silently. The Diff's target model is deployed through install_ddl into a
# temp database (DBIO::Firebird::Deploy), so these are the statements an
# upgrade creates.

use DBIO::Firebird::DDL;

sub index_stmts {
  my ($schema) = @_;
  my $ddl = DBIO::Firebird::DDL->install_ddl($schema);
  my %by_name;
  for my $stmt (split /\n\n/, $ddl) {
    next unless $stmt =~ /^CREATE\b.*?\bINDEX\s+"((?:[^"]|"")+)"\s/;
    $by_name{$1} = $stmt;
  }
  return \%by_name;
}

sub result_schema {
  my ($ns, $setup) = @_;
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('Firebird'); 1" or die $@;
  my $class = "${ns}::Result::Doc";
  eval "package $class; use DBIO 'Core'; 1" or die $@;
  $class->table('docs');
  $class->add_columns(
    id   => { data_type => 'integer' },
    name => { data_type => 'varchar', size => 64 },
    slug => { data_type => 'varchar', size => 64 },
  );
  $class->set_primary_key('id');
  $setup->($class->result_source_instance) if $setup;
  $ns->register_class(Doc => $class);
  return $ns;
}

my $ok = result_schema('K51::Ok', sub {
  my ($src) = @_;
  $src->add_index_declaration({ name => 'idx_name', columns => ['name'] });
  $src->add_index_declaration({ name => 'idx_slug_u', columns => ['slug'], type => 'unique' });
  $src->add_index_declaration({ name => 'idx_two', columns => ['slug', 'name'], driver => { firebird => {} } });
  $src->add_index_declaration({ name => 'Mixed "Case"', columns => ['name'] });
});
my $i = index_stmts($ok);
is $i->{idx_name}, 'CREATE INDEX "idx_name" ON "docs" ("name");',
  'a declaration produces a quoted CREATE INDEX';
is $i->{idx_slug_u}, 'CREATE UNIQUE INDEX "idx_slug_u" ON "docs" ("slug");',
  "type => 'unique' is a CREATE UNIQUE INDEX";
is $i->{idx_two}, 'CREATE INDEX "idx_two" ON "docs" ("slug", "name");',
  'an empty firebird block is the plain index, column order kept';
ok $i->{'Mixed ""Case""'}, 'the index name is quoted through _firebird_quote_ident';

# A declared name that equals the auto-named unique index of a column: once.
my $same = result_schema('K51::Same', sub {
  my ($src) = @_;
  $src->add_column(code => { data_type => 'varchar', size => 8, is_unique => 1 });
  $src->add_index_declaration({ name => 'docs_code_idx', columns => ['code'], type => 'unique' });
});
my $n = () = DBIO::Firebird::DDL->install_ddl($same) =~ /INDEX "docs_code_idx"/g;
is $n, 1, 'the canonical declaration wins on the name of the column unique index';

# Refusals.
my %refuse = (
  'type other than unique' => [
    { name => 'bad_type', columns => ['name'], type => 'fulltext' }, qr/bad_type.*type 'fulltext'/s ],
  'options' => [
    { name => 'bad_opt', columns => ['name'], options => { fillfactor => 70 } }, qr/bad_opt.*options/s ],
  'only another driver block' => [
    { name => 'only_pg', columns => ['name'], driver => { pg => { where => 'x' } } },
    qr/only_pg.*'pg'.*none for 'firebird'/s ],
  'expression key in the firebird block' => [
    { name => 'bad_expr', columns => ['name'], driver => { firebird => { expression => 'upper(name)' } } },
    qr/bad_expr.*expression/s ],
  'where key in the firebird block' => [
    { name => 'bad_where', columns => ['name'], driver => { firebird => { where => 'name is not null' } } },
    qr/bad_where.*where/s ],
);
my $c = 0;
for my $what (sort keys %refuse) {
  my ($decl, $re) = @{ $refuse{$what} };
  my $ns = result_schema('K51::Refuse' . ++$c, sub { $_[0]->add_index_declaration($decl) });
  eval { DBIO::Firebird::DDL->install_ddl($ns) };
  like $@, $re, "refused: $what";
}

done_testing;
