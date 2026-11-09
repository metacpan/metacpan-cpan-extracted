use strict;
use warnings;
use Test::More;
use DBIO::Optional::Dependencies ();

# LIVE (karr k25): views through install, diff and upgrade. A view is created,
# one over another created in dependency order (against the alphabet), a
# changed definition is replaced, a view the schema lacks is dropped, a name
# that is a table in the database and a view in the schema is refused (the
# rows are not dropped), and the diff afterwards is empty.
# Creates and drops only "zz_ix_k25v_*".

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_informix')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_informix');
my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_INFORMIX_$_" } qw/DSN USER PASS/};
plan skip_all => 'Set $ENV{DBIO_TEST_INFORMIX_DSN}, _USER and _PASS to run this test' unless $dsn;

use DBIO::Core;
use DBIO::Schema;
use DBIO::Informix::Deploy;
use DBIO::Informix::Introspect;

my $seq = 0;
# views: name => definition; the base table is zz_ix_k25v_base
sub build {
  my (%views) = @_;
  my $sc = 'K25View::S' . ++$seq;
  no strict 'refs';
  @{"${sc}::ISA"} = ('DBIO::Schema');
  $sc->storage_type('DBIO::Informix::Storage');
  my $base = "${sc}::Result::Base";
  @{"${base}::ISA"} = ('DBIO::Core');
  $base->table('zz_ix_k25v_base');
  $base->add_columns(id => { data_type => 'integer' }, val => { data_type => 'integer', is_nullable => 1 });
  $base->set_primary_key('id');
  $sc->register_class(Base => $base);
  for my $name (sort keys %views) {
    my $vc = "${sc}::Result::V_$name";
    @{"${vc}::ISA"} = ('DBIO::Core');
    $vc->table_class('DBIO::ResultSource::View');
    $vc->table($name);
    $vc->add_columns(id => { data_type => 'integer' });
    $vc->result_source_instance->is_virtual(0);
    $vc->result_source_instance->view_definition($views{$name});
    $sc->register_class("V_$name" => $vc);
  }
  return $sc->connect($dsn, $user, $pass, { RaiseError => 1, PrintError => 0 });
}

my $dbh = build()->storage->dbh;
my @names = qw(zz_ix_k25v_a_outer zz_ix_k25v_z_inner zz_ix_k25v_one);
sub cleanup {
  eval { $dbh->do("DROP VIEW $_") } for @names;
  eval { $dbh->do('DROP TABLE zz_ix_k25v_one') };
  eval { $dbh->do('DROP TABLE zz_ix_k25v_base') };
}
cleanup();
END { cleanup() if $dbh }

sub ours { my ($op) = @_; ($op->can('table_name') ? $op->table_name : '') =~ /\Azz_ix_k25v_/ }
sub open_ops { [ grep { ours($_) } @{ DBIO::Informix::Deploy->new(schema => $_[0])->diff->operations } ] }
sub views { my $m = DBIO::Informix::Introspect->new(dbh => $dbh)->model;
  [ sort grep { /\Azz_ix_k25v_/ && $m->{tables}{$_}{kind} eq 'view' } keys %{ $m->{tables} } ] }

my %v1 = (
  zz_ix_k25v_a_outer => 'SELECT id FROM zz_ix_k25v_z_inner',
  zz_ix_k25v_z_inner => 'SELECT id FROM zz_ix_k25v_base',
);
my $s1 = build(%v1);
ok eval { DBIO::Informix::Deploy->new(schema => $s1)->install; 1 }, 'install: a view over a view named earlier in the alphabet' or diag $@;
is_deeply views(), [qw(zz_ix_k25v_a_outer zz_ix_k25v_z_inner)], '... both views exist';
is scalar @{ open_ops(build(%v1)) }, 0, '... the diff has nothing to say' or diag join "\n", map { $_->as_sql } @{ open_ops(build(%v1)) };

# change the inner one and the outer one together; drop-and-create in order
my %v2 = (
  zz_ix_k25v_a_outer => 'SELECT id FROM zz_ix_k25v_z_inner WHERE id > 1',
  zz_ix_k25v_z_inner => 'SELECT id FROM zz_ix_k25v_base WHERE id > 0',
);
my $s2 = build(%v2);
my $ops = open_ops($s2);
cmp_ok scalar @$ops, '>=', 4, 'changed definitions of two stacked views: reported (drop and create each)';
ok eval { DBIO::Informix::Deploy->new(schema => $s2)->upgrade; 1 }, 'the upgrade runs, the outer dropped first and created last' or diag $@;
is scalar @{ open_ops(build(%v2)) }, 0, '... and the diff is empty afterwards';

# a view the schema no longer has
my $s3 = build(zz_ix_k25v_z_inner => $v2{zz_ix_k25v_z_inner});
ok eval { DBIO::Informix::Deploy->new(schema => $s3)->upgrade(allow_destructive => 1); 1 }, 'upgrade drops the view the schema lacks' or diag $@;
is_deeply views(), ['zz_ix_k25v_z_inner'], '... the other stays';

# a table in the database, a view in the schema: refused, rows stay
$dbh->do('CREATE TABLE zz_ix_k25v_one (id INTEGER NOT NULL, PRIMARY KEY (id))');
$dbh->do('INSERT INTO zz_ix_k25v_one VALUES (1)');
my $s4 = build(zz_ix_k25v_one => 'SELECT id FROM zz_ix_k25v_base', zz_ix_k25v_z_inner => $v2{zz_ix_k25v_z_inner});
ok !eval { DBIO::Informix::Deploy->new(schema => $s4)->upgrade(allow_destructive => 1); 1 }, 'a table that the schema declares as a view: the upgrade is refused';
like "$@", qr/table and view/, '... naming the kind change';
is $dbh->selectrow_array('SELECT COUNT(*) FROM zz_ix_k25v_one'), 1, '... the table and its row are still there';

done_testing;
