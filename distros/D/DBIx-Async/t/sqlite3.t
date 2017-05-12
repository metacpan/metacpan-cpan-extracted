use strict;
use warnings;

use Test::More;
use Test::Fatal;
use curry;
use Scalar::Util qw(weaken);
use DBIx::Async;
use Future::Utils qw(fmap_void repeat);
use IO::Async::Loop;

plan skip_all => 'sqlite3 not found' unless eval { require DBD::SQLite; };

my $loop = IO::Async::Loop->new;
my $dbh;
is(exception {
	$dbh = DBIx::Async->connect(
		'dbi:SQLite:dbname=:memory:',
		'',
		'', {
			AutoCommit => 1,
			RaiseError => 1,
		}
	)
}, undef, 'can create dbh');
$loop->add($dbh);

ok(my $f = $dbh->do(q{CREATE TABLE our_table(id integer primary key autoincrement, content text)}), 'attempt to create table');
isa_ok($f, 'IO::Async::Future');
$loop->await($f);
ok($f->is_done, 'completed successfully');

# Check for missing/present table handling
like(exception {
	$dbh->do(q{select * from not_found_table})->get;
}, qr/no such table/i, 'we get an exception for a missing table');
is(exception {
	$dbh->do(q{select * from our_table})->get;
}, undef, '... but no exception for a valid table');

{
	my $sth_copy;
	{ # Add some data
		isa_ok(my $sth = $dbh->prepare(q{insert into our_table (content) values (?)}), 'DBIx::Async::Handle');
		(fmap_void {
			$sth->execute(shift)
		} foreach => [qw(first second third)])->get;
		is(exception { $sth->finish->get }, undef, 'can finish the statement without error');
		weaken($sth_copy = $sth);
	}
	is($sth_copy, undef, 'statement handle has gone away');
}

{ # Add more data in a transaction, then throw it away
	$dbh->begin_work->get;
	isa_ok(my $sth = $dbh->prepare(q{insert into our_table (content) values (?)}), 'DBIx::Async::Handle');
	(fmap_void {
		$sth->execute(shift)
	} foreach => [qw(fourth fifth)])->get;
	is(exception { $sth->finish->get }, undef, 'can finish the statement without error');
	is(exception { $dbh->rollback->get }, undef, 'can roll back without error');
}

{ # Read the data back again
	isa_ok(my $sth = $dbh->prepare(q{select content from our_table order by id}), 'DBIx::Async::Handle');
	$sth->execute;
	my @result;
	(repeat {
		$sth->fetchrow_hashref;
	} while => sub {
		my $v = shift->get;
		return 0 unless $v;
		push @result, $v->{content};
		1
	})->get;
	$sth->finish->get;
	is_deeply(\@result, [qw(first second third)], 'have expected results');
}

done_testing;

