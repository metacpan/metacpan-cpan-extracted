use strict;
use warnings FATAL => 'all';

use Test::More tests => 24;
use Test::TempDatabase;
use Carp;

BEGIN { use_ok('DBIx::EnumConstraints'); }

my $test_db = Test::TempDatabase->create(dbname => 'ec_test_db'
	, dbi_args => { AutoCommit => 1, PrintError => 0
		, HandleError => sub { confess(shift); } });
my $dbh = $test_db->handle;
$dbh->do(<<ENDS);
create language plpgsql;
create table t1 (kind smallint not null, 
		a text, b text, c text, d text);
ENDS

my $ec = DBIx::EnumConstraints->new({
	table => 't1', name => 'kind', fields => [
		[ qw() ]
		, [ qw() ]
		, [ qw() ]
	],
});
isa_ok($ec, 'DBIx::EnumConstraints');

$dbh->do($ec->make_constraints);
eval { $dbh->do("insert into t1 (kind) values (0)"); };
like($@, qr/t1_kind_size/);

eval { $dbh->do("insert into t1 (kind) values (4)"); };
like($@, qr/t1_kind_size/);

$ec = DBIx::EnumConstraints->new({
	table => 't1', name => 'kind', fields => [
		[ qw(a b c) ]
		, [ qw(b d) ]
		, [ qw(c) ]
	],
});
$dbh->do('select drop_t1_kind_constraints()');
$dbh->do($ec->make_constraints);

eval { $dbh->do("insert into t1 (kind) values (3)"); };
like($@, qr/t1_kind_c_in_chk/);

ok($dbh->do("insert into t1 (kind, c) values (3, 'c')"));

eval { $dbh->do("insert into t1 (kind, a, c) values (3, 'a', 'c')"); };
like($@, qr/t1_kind_a_out_chk/);

my $ec20 = DBIx::EnumConstraints->new({ table => t1 => name => 'kind' });
$ec20->load_fields_from_db($dbh);
is_deeply($ec20->fields, $ec->fields);

$dbh->do('select drop_t1_kind_constraints()');
ok($dbh->do("insert into t1 (kind) values (20)"));
ok($dbh->do("insert into t1 (kind, a) values (3, 'a')"));

my (@vals, @in, @out);
$ec->for_each_kind(sub {
	my ($idx, $ins, $outs) = @_;
	push @vals, $idx;
	push @in, $ins;
	push @out, $outs;
});
is_deeply(\@vals, [ qw(1 2 3) ]);
is_deeply(\@in, [ [ qw(a b c) ], [ qw(b d) ], [ 'c' ] ]);
is_deeply(\@out, [ [ qw(d) ], [ qw(a c) ], [ qw(a b d) ] ]);

# test optional
my $ec2 = DBIx::EnumConstraints->new({
	table => t1 => name => 'kind', fields => [
		[ qw(a) ]
		, [ qw(b?) ]
	],
});

$dbh->do("delete from t1");
$dbh->do($ec2->make_constraints);

ok($dbh->do("insert into t1 (kind) values (2)"));
ok($dbh->do("insert into t1 (kind, b) values (2, 'b')"));

my $ec3 = DBIx::EnumConstraints->new({
	table => t1 => name => 'kind', fields => [
		[ qw(a) ]
		, [ qw(b) ]
	], column_groups => { a => [ 'c' ], b => [ 'd' ] } 
});

@vals = @in = @out = ();
$ec3->for_each_kind(sub {
	my ($idx, $ins, $outs) = @_;
	push @vals, $idx;
	push @in, $ins;
	push @out, $outs;
});
is_deeply(\@vals, [ qw(1 2) ]);
is_deeply(\@in, [ [ qw(a c) ], [ qw(b d) ] ]);
is_deeply(\@out, [ [ qw(b d) ], [ qw(a c) ] ]);

$dbh->do("delete from t1");
$dbh->do('select drop_t1_kind_constraints()');
$dbh->do($ec3->make_constraints);

my $ec4 = DBIx::EnumConstraints->new({ table => t1 => name => 'kind' });
$ec4->load_fields_from_db($dbh);
my (@v4, @i4, @o4);
$ec4->for_each_kind(sub {
	my ($idx, $ins, $outs) = @_;
	push @v4, $idx;
	push @i4, $ins;
	push @o4, $outs;
});
is_deeply(\@v4, \@vals);
is_deeply(\@i4, \@in);
is_deeply(\@o4, \@out);
is(@{ $ec4->fields }, 2);

$dbh->do("delete from t1");
$dbh->do('select drop_t1_kind_constraints()');
$ec3 = DBIx::EnumConstraints->new({
	table => t1 => name => 'kind', fields => [
		[ qw(a) ], []
	], column_groups => { a => [ 'c' ], b => [ 'd' ] } 
});
$dbh->do($ec3->make_constraints);

$ec4 = DBIx::EnumConstraints->new({ table => t1 => name => 'kind' });
$ec4->load_fields_from_db($dbh);
is(@{ $ec4->fields }, 2);

$dbh->do("delete from t1");
$dbh->do('select drop_t1_kind_constraints()');
$ec3 = DBIx::EnumConstraints->new({
	table => t1 => name => 'kind', fields => [
		[ qw(a) ], map { [] } (1 .. 11)
	], column_groups => { a => [ 'c' ], b => [ 'd' ] } 
});
$dbh->do($ec3->make_constraints);

$ec4 = DBIx::EnumConstraints->new({ table => t1 => name => 'kind' });
$ec4->load_fields_from_db($dbh);
is(@{ $ec4->fields }, 12);

