use strict;
use warnings;

use Test::More;
use Test::Needs;

# Database::Abstraction is not a dependency of Class::Shared.  It is a good
# example of what the backend is for, so it is used when it is installed
# and skipped when it is not.
use Test::Needs { 'Database::Abstraction' => '0.57' };

use Class::Shared ();

BEGIN {
	test_needs 'Test::Permissions';

	plan skip_all => 'a backend needs unix sockets in an owner-only directory, '
		. 'which this perl cannot provide (Class::Shared is Unix-only)'
		unless Class::Shared::_has_unix_sockets()
			&& Test::Permissions::can_revoke_create();
}

use File::Spec ();
use File::Temp qw(tempdir);
use lib 't/lib';

use Class::Shared::Frontend;
use Shared::Cities;

# A table small enough to read, with a name that is not ASCII, so that the
# way text crosses the socket is part of what is compared.
my @rows = (
	[1, 'Ramsgate', 'GB',    40_000],
	[2, 'Paris',    'FR', 2_100_000],
	[3, 'Lyon',     'FR',   520_000],
	[4, 'Berlin',   'DE', 3_600_000],
	[5, "Z\x{fc}rich", 'CH',   420_000],
	[6, "M\x{fc}nchen", 'DE', 1_500_000],
);

my $dir = tempdir(CLEANUP => 1);
my $data = File::Spec->catdir($dir, 'data');

mkdir($data, 0700) or BAIL_OUT("cannot make $data: $!");

my $csv = File::Spec->catfile($data, 'Cities.csv');

open(my $fh, '>:encoding(UTF-8)', $csv) or BAIL_OUT("cannot write $csv: $!");
print {$fh} "entry,name,country,population\n"
	or BAIL_OUT("cannot write $csv: $!");

for my $row (@rows) {
	print {$fh} join(',', @{$row}), "\n" or BAIL_OUT("cannot write $csv: $!");
}

close($fh) or BAIL_OUT("cannot close $csv: $!");

my $shared = Class::Shared::Frontend->new(
	'Shared::Cities',
	dir  => $dir,
	ctor => [directory => $data],
);

# The same table, opened here, in this process.  Whatever it answers is what a
# frontend must answer: the backend adds no behaviour of its own.
my $direct = Shared::Cities->new(directory => $data);

is($shared->shared_status->{classes}[0], 'Shared::Cities', 'the backend loaded the class');

# --------------------------------------------- the same answers as the class

# Each is a call that returns plain data, as a frontend needs.  A query with no
# ORDER BY returns rows in no particular order, so those are sorted by their
# key first: the order is the class's to choose, not what is being tested.
my $by_key = sub { return [sort { $a->{entry} <=> $b->{entry} } @{ $_[0] }] };

for my $case (
	['count',                              'count',             []],
	['columns',                            'columns',           []],
	['one row, by key',                    'fetchrow_hashref',  [entry => 2]],
	['one row, no match',                  'fetchrow_hashref',  [entry => 99]],
	['a column, by key (AUTOLOAD)',        'name',              [entry => 3]],
	['all rows that match',                'selectall_arrayref', [country => 'FR'], $by_key],
	['all rows that match, none',          'selectall_arrayref', [country => 'XX']],
	['a name that is not ASCII',           'name',              [entry => 5]],
	['an aggregate, grouped',              'aggregate',
		[by => ['country'], measures => [{ col => 'population', fn => 'sum', as => 'total' }]]],
	['a query run inside the backend',     'larger_than',       [1_000_000]],
) {
	my ($name, $method, $args, $normalise) = @{$case};

	my $expected = $direct->$method(@{$args});
	my $got = $shared->$method(@{$args});

	($expected, $got) = map { $normalise->($_) } $expected, $got if $normalise;

	is_deeply($got, $expected, "$name: the same as calling the class directly");
}

# ------------------------------------------------- spot checks on the values

# These pin the data itself, so that "the same as the class" is not "the same
# wrong answer".
is($shared->count, scalar @rows, 'count is the number of rows in the file');
is_deeply($shared->columns, [sort qw(entry name country population)], 'columns are the header, sorted');
is($shared->fetchrow_hashref(entry => 2)->{name}, 'Paris', 'a row is found by its key');
is(scalar @{ $shared->selectall_arrayref(country => 'FR') }, 2, 'two rows are in FR');

{
	my $big = $shared->larger_than(1_000_000);

	is_deeply([map { $_->{name} } @{$big}], ['Berlin', 'Paris', "M\x{fc}nchen"],
		'larger_than returns plain rows, largest first');
}

# --------------------------------------------------- one table, many clients

{
	my $second = Class::Shared::Frontend->new(
		'Shared::Cities',
		dir  => $dir,
		ctor => [directory => $data],
	);

	is($shared->shared_pid, $second->shared_pid, 'a second frontend reaches the same backend');
	is($second->shared_status->{objects}, 2, 'which now holds one object for each frontend');
	is($second->count, scalar @rows, 'and the second frontend reads the same table');
}

# ------------------------------------------ what the class returns, exactly

# Database::Abstraction may lock the rows it returns (it does when it holds the
# table in memory), so that a caller cannot change the table by changing a row.
# A lock is part of the data and Storable carries it across.  Whether there is
# one depends on how the class answered, so what is compared is the behaviour:
# a row from the frontend is as changeable, or as locked, as the class's own,
# and either way the table itself is not changed.
{
	my $direct_row = $direct->fetchrow_hashref(entry => 1);
	my $shared_row = $shared->fetchrow_hashref(entry => 1);

	my $direct_refused = eval { $direct_row->{name} = 'Changed'; 1 } ? '' : $@;
	my $shared_refused = eval { $shared_row->{name} = 'Changed'; 1 } ? '' : $@;

	is(length($shared_refused) ? 1 : 0, length($direct_refused) ? 1 : 0,
		'a row from the frontend can be changed exactly when the class\'s own row can');
	is($shared->fetchrow_hashref(entry => 1)->{name}, 'Ramsgate', 'and changing it leaves the table as it was');
}

# ------------------------------------------------------------ a failing class

# The error is the class's own, and the connection stays usable afterwards.
{
	my $missing = File::Spec->catdir($dir, 'no-such-data');

	my $lost = eval {
		Class::Shared::Frontend->new('Shared::Cities', dir => $dir, ctor => [directory => $missing])->count;
		1;
	};

	ok(!$lost, 'a table that cannot be found is an error');

	# The wording is Database::Abstraction's own, so it is not pinned here: what
	# the backend promises is to name the class and pass the class's reason on.
	like($@, qr/could not construct Shared::Cities/, 'the error names the class');
	like($@, qr/\Q$missing\E/, 'and carries the class\'s own reason, which names the missing directory');
	is($shared->count, scalar @rows, 'the other frontends are not affected');
}

$shared->shared_shutdown;

ok(!-S $shared->shared_socket_path, 'the backend removed its socket on shutdown');

done_testing();
