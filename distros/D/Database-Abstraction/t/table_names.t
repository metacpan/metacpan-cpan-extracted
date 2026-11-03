#!perl -w

# A table may be called anything that is a safe identifier, including the name
# of one of the object's own fields.  Before 0.54 the DBI handle was kept in the
# object under the table's name, so a table called "data" shared its slot with
# the rows slurped into memory: reading it died with "Not an ARRAY reference",
# and so did DESTROY, which took whatever was in that slot for the handle.
# Database::BI's SQLite export names its table "data", so its own files could
# not be read back.

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::Most;

eval { require DBI; require DBD::SQLite; 1 }
	or plan skip_all => 'DBD::SQLite not available';

# Each is the name of a field Database::Abstraction keeps in the object.
my @NAMES = qw(data id directory berkeley logger cache no_entry columns);

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

for my $name (@NAMES) {
	my $class = "Database::$name";
	eval "package $class; use parent 'Database::Abstraction'; 1" or die $@;	## no critic (ProhibitStringyEval)

	subtest "SQLite table '$name'" => sub {
		my $dir  = tempdir(CLEANUP => 1);
		my $file = File::Spec->catfile($dir, "$name.sql");
		my $dbh  = DBI->connect("dbi:SQLite:dbname=$file", '', '', { RaiseError => 1, PrintError => 0 });
		$dbh->do(qq{CREATE TABLE "$name" (entry TEXT, colour TEXT)});
		$dbh->do(qq{INSERT INTO "$name" VALUES (?, ?)}, undef, @$_) for [ 'a', 'red' ], [ 'b', 'blue' ];
		$dbh->disconnect;

		{
			my $db = $class->new(directory => $dir);
			my $rows = $db->selectall_arrayref();
			is(ref $rows, 'ARRAY', 'selectall_arrayref returns rows');
			is_deeply([ sort map { $_->{colour} } @$rows ], [qw(blue red)], 'all of them');
			is($db->fetchrow_hashref(entry => 'b')->{colour}, 'blue', 'fetchrow_hashref finds one');
			is($db->count(), 2, 'count');
			is_deeply([ sort @{ $db->columns } ], [qw(colour entry)], 'columns');
			my @each;
			$db->each_row(sub { push @each, $_[0]->{entry} });
			is_deeply([ sort @each ], [qw(a b)], 'each_row');
		}
		ok(1, 'the object is destroyed');
	};

	subtest "CSV table '$name'" => sub {
		my $dir = tempdir(CLEANUP => 1);
		open my $fh, '>', File::Spec->catfile($dir, "$name.csv") or die $!;
		print $fh "entry,colour\na,red\nb,blue\n";
		close $fh;

		my $db = $class->new(directory => $dir, sep_char => ',');
		my $rows = $db->selectall_arrayref();
		is(ref $rows, 'ARRAY', 'selectall_arrayref returns rows');
		is_deeply([ sort map { $_->{colour} } @$rows ], [qw(blue red)], 'all of them');
		is($db->fetchrow_hashref(entry => 'a')->{colour}, 'red', 'fetchrow_hashref finds one');
	};
}

is_deeply(\@warnings, [], 'nothing warned, DESTROY included') or diag(explain(\@warnings));

done_testing();
