use strict;
use warnings;
use Test::More;
use DBIO::Optional::Dependencies ();

# LIVE (karr k29): a belongs_to onto a key in another column order than the
# foreign column names. The server takes REFERENCES parent(b, a) only for a
# key (b, a); install_ddl writes the pairs in the order of the target key, the
# server accepts the statement, and deploy -> introspect -> diff stays empty.
# Creates and drops only the tables "zz_ix_k29_*".

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_informix')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_informix');
my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_INFORMIX_$_" } qw/DSN USER PASS/};
plan skip_all => 'Set $ENV{DBIO_TEST_INFORMIX_DSN}, _USER and _PASS to run this test' unless $dsn;

use DBIO::Core;
use DBIO::Schema;
use DBIO::Informix::DDL;
use DBIO::Informix::Deploy;
use DBIO::Informix::Introspect;

my $seq = 0;
sub build_schema {
  my (%o) = @_;
  my $sc = 'K29Ord::S' . ++$seq;
  no strict 'refs';
  @{"${sc}::ISA"} = ('DBIO::Schema');
  $sc->storage_type('DBIO::Informix::Storage');
  my $int = sub { map { $_ => { data_type => 'integer' } } @_ };
  my $p = "${sc}::Result::Parent";
  my $c = "${sc}::Result::Child";
  @{"${p}::ISA"} = @{"${c}::ISA"} = ('DBIO::Core');
  $INC{ ($_ =~ s{::}{/}gr) . '.pm' } = 1 for $p, $c;
  $p->table('zz_ix_k29_parent');
  $p->add_columns($int->(qw/a b/));
  $p->set_primary_key(@{ $o{pk} });
  $p->add_unique_constraint(zz_ix_k29_parent_uc => $o{uc}) if $o{uc};
  $c->table('zz_ix_k29_child');
  $c->add_columns($int->(qw/id x y/));
  $c->set_primary_key('id');
  $c->belongs_to(parent => $p, { 'foreign.a' => 'self.x', 'foreign.b' => 'self.y' });
  $sc->register_class(Parent => $p);
  $sc->register_class(Child => $c);
  return $sc->connect($dsn, $user, $pass, { RaiseError => 1, PrintError => 0 });
}

my @tables = qw(zz_ix_k29_child zz_ix_k29_parent);
my $dbh = build_schema(pk => ['a'])->storage->dbh;
sub cleanup { eval { $dbh->do("DROP TABLE $_") } for @tables }
cleanup();
END { cleanup() if $dbh }

sub ours { my ($op) = @_; ($op->can('table_name') ? $op->table_name : '') =~ /\Azz_ix_k29_/ }

for my $case (
  [ 'a primary key (b, a)',       pk => [qw/b a/] ],
  [ 'a unique constraint (b, a)', pk => ['a'], uc => [qw/b a/] ],
) {
  my ($label, @opt) = @$case;
  my $schema = build_schema(@opt);
  like(DBIO::Informix::DDL->install_ddl($schema),
    qr/FOREIGN KEY \(y, x\) REFERENCES parent\(b, a\)|FOREIGN KEY \("?y"?, "?x"?\) REFERENCES "?zz_ix_k29_parent"?\("?b"?, "?a"?\)/i,
    "$label: the key is written in the order of the target key");
  ok eval { DBIO::Informix::Deploy->new(schema => $schema)->install; 1 },
    "... the server takes it" or diag $@;

  my $fks = introspect($dbh)->{foreign_keys}{zz_ix_k29_child} // [];
  is scalar @$fks, 1, '... and holds the foreign key';

  my @open = grep { ours($_) } @{ DBIO::Informix::Deploy->new(schema => build_schema(@opt))->diff->operations };
  is scalar @open, 0, '... deploy -> introspect -> diff is empty' or diag join "\n", map { $_->as_sql } @open;
  cleanup();
}

sub introspect { DBIO::Informix::Introspect->new(dbh => $_[0])->model }

done_testing;
