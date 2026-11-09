use strict;
use warnings;
use Test::More;

# Offline: install_ddl reads the canonical index declaration of the result
# source (Cake idx, indices; ADR 0061 in core, core k377 for the driver name
# 'informix'), also the non-unique and the multi-column index. The Diff's target
# model is deployed through install_ddl into a throwaway database, so these are
# the statements an upgrade creates (karr k25).

use DBIO::Informix::DDL;

sub index_stmts {
  my ($schema) = @_;
  my $ddl = DBIO::Informix::DDL->install_ddl($schema);
  my %by_name;
  for my $stmt (split /\n\n/, $ddl) {
    next unless $stmt =~ /^CREATE\b.*?\bINDEX\s+("(?:[^"]|"")+"|\w+)\s/;
    (my $n = $1) =~ s/\A"|"\z//g;
    $by_name{$n} = $stmt;
  }
  return \%by_name;
}

sub result_schema {
  my ($ns, $setup) = @_;
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('Informix'); 1" or die $@;
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

my $ok = result_schema('K25::Ok', sub {
  my ($src) = @_;
  $src->add_index_declaration({ name => 'idx_name', columns => ['name'] });
  $src->add_index_declaration({ name => 'idx_slug_u', columns => ['slug'], type => 'unique' });
  $src->add_index_declaration({ name => 'idx_two', columns => ['slug', 'name'], driver => { informix => {} } });
  $src->add_index_declaration({ name => 'Mixed "Case"', columns => ['name', 'id'] });
});
my $i = index_stmts($ok);
is $i->{idx_name}, 'CREATE INDEX idx_name ON docs (name);',
  'a declaration produces a CREATE INDEX, also a non-unique one';
is $i->{idx_slug_u}, 'CREATE UNIQUE INDEX idx_slug_u ON docs (slug);',
  "type => 'unique' is a CREATE UNIQUE INDEX";
is $i->{idx_two}, 'CREATE INDEX idx_two ON docs (slug, name);',
  'an empty informix block is the plain index, column order kept';
ok $i->{'Mixed ""Case""'}, 'the index name is quoted';

# A declared name that equals the auto-named unique index of a column: once.
my $same = result_schema('K25::Same', sub {
  my ($src) = @_;
  $src->add_column(code => { data_type => 'varchar', size => 8, is_unique => 1 });
  $src->add_index_declaration({ name => 'docs_code', columns => ['code'], type => 'unique' });
});
# karr k27 changed this claim: the column's is_unique and a declaration over
# the same column used to be merged into one index silently; they are two
# declarations over the same columns and are refused, naming both (t/72).
eval { DBIO::Informix::DDL->install_ddl($same) };
like "$@", qr/'docs_code'.*unique column 'code'.*-350/s,
  'is_unique on a column and a declared index over it: refused, both named';

# Refusals.
my %refuse = (
  'type other than unique' => [
    { name => 'bad_type', columns => ['name'], type => 'fulltext' }, qr/bad_type.*type 'fulltext'/s ],
  'options' => [
    { name => 'bad_opt', columns => ['name'], options => { fillfactor => 70 } }, qr/bad_opt.*options/s ],
  'only another driver block' => [
    { name => 'only_pg', columns => ['name'], driver => { pg => { where => 'x' } } },
    qr/only_pg.*'pg'.*none for 'informix'/s ],
  'expression key in the informix block' => [
    { name => 'bad_expr', columns => ['name'], driver => { informix => { expression => 'upper(name)' } } },
    qr/bad_expr.*expression/s ],
  'where key in the informix block' => [
    { name => 'bad_where', columns => ['name'], driver => { informix => { where => 'name is not null' } } },
    qr/bad_where.*where/s ],
);
my $c = 0;
for my $what (sort keys %refuse) {
  my ($decl, $re) = @{ $refuse{$what} };
  my $ns = result_schema('K25::Refuse' . ++$c, sub { $_[0]->add_index_declaration($decl) });
  eval { DBIO::Informix::DDL->install_ddl($ns) };
  like $@, $re, "refused: $what";
}

done_testing;
