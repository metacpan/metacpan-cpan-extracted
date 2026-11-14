#!perl -w

# Key pushdown on the array backend: a secondary database with no criteria of
# its own is asked for only the primary's keys ({ -in => [...] }) instead of
# being read in full.
#
#   - results are the same with and without pushdown, on the slurp and the
#     SQL paths, and for TSV and JSON tables
#   - a left join still keeps primary rows that have no secondary row
#   - pushdown doesn't apply to outer joins, to a secondary the caller already
#     restricted by join column, past $MAX_PUSHDOWN_KEYS keys, or to an object
#     whose selectall_arrayref isn't Database::Abstraction's own
#   - the secondary's own criteria and base filters still apply
#   - a database that croaks on -in is read in full instead, and a genuine
#     error still reaches the caller

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use Test::Most;

use lib 't/lib';

BEGIN {
	eval { require Database::Abstraction; 1 }
		or plan(skip_all => 'Database::Abstraction needed');
}

use Database::Join;

# Two tables named after their packages, as Database::Abstraction expects
{
	package Database::pdservice;
	our @ISA = ('Database::Abstraction');
}
{
	package Database::pdperson;
	our @ISA = ('Database::Abstraction');
}
# Implements the interface itself, with equality matching only
{
	package PDEqualityDA;
	sub new { my ($class, %a) = @_; return bless { %a, calls => [] }, $class }
	sub columns { return [ 'entry', 'title' ] }
	sub updated { return 0 }
	sub selectall_arrayref {
		my ($self, $criteria) = @_;
		push @{ $self->{calls} }, $criteria;
		my @rows = @{ $self->{rows} };
		for my $col (keys %{ $criteria // {} }) {
			my $v = $criteria->{$col};
			@rows = grep { defined($_->{$col}) && $_->{$col} eq $v } @rows;
		}
		return \@rows;
	}
	sub DESTROY {}
}

# Write a !-separated CSV file
sub write_csv
{
	my ($dir, $table, @rows) = @_;

	my $file = File::Spec->catfile($dir, "$table.csv");
	open(my $out, '>', $file) or die "$file: $!";
	print $out join('!', @{$_}), "\n" foreach(@rows);
	close $out or die "$file: $!";
}

# Records every criteria hashref given to Database::Abstraction's
# selectall_arrayref.  Replacing the method in Database::Abstraction itself
# keeps it the object's own, so pushdown still applies.
my @calls;
my $real_select = \&Database::Abstraction::selectall_arrayref;
our $croak_on_in = 0;
{
	no warnings 'redefine';
	*Database::Abstraction::selectall_arrayref = sub {
		my ($self, @args) = @_;
		my $criteria = ref($args[0]) eq 'HASH' ? $args[0] : { @args };
		push @calls, { table => ref($self), criteria => $criteria };
		die "Unknown operator '-in'\n"
			if($croak_on_in && grep { ref($_) eq 'HASH' && exists $_->{'-in'} } values %{$criteria});
		return $real_select->($self, @args);
	};
}

# The criteria the person table was given in the last query
sub person_criteria
{
	return [ map { $_->{criteria} } grep { $_->{table} eq 'Database::pdperson' } @calls ];
}

# Query with and without pushdown, so the results can be compared
sub both_ways
{
	my ($join, @criteria) = @_;

	@calls = ();
	my $pushed = $join->selectall_arrayref(@criteria);
	my $pushed_calls = [ @calls ];

	no warnings 'redefine';
	local *Database::Join::_understands_in = sub { 0 };
	@calls = ();
	my $plain = $join->selectall_arrayref(@criteria);

	@calls = @{$pushed_calls};
	return ($pushed, $plain);
}

my $dir = tempdir(CLEANUP => 1);
write_csv($dir, 'pdservice',
	[ 'entry', 'person', 'notes' ],
	[ 1, 'I1', 'Army' ],
	[ 2, 'I3', 'Navy' ],
	[ 3, 'I1', 'Home Guard' ],
	[ 4, 'I9', 'not in pdperson' ],
);
write_csv($dir, 'pdperson',
	[ 'entry', 'title', 'notes' ],
	[ 'I1', 'Alice', 'a' ],
	[ 'I2', 'Bob', 'b' ],
	[ 'I3', 'Carol', 'c' ],
	[ 'I4', 'Dave', 'd' ],
);

# Small files are slurped into memory; max_slurp_size => 1 forces the SQL path
foreach my $path([ 'slurp', {} ], [ 'SQL', { max_slurp_size => 1 } ]) {
	my ($name, $opts) = @{$path};

	subtest "$name path" => sub {
		my $service = Database::pdservice->new(directory => $dir, %{$opts});
		my $person = Database::pdperson->new(directory => $dir, %{$opts});
		my %common = (
			databases => [ $service, $person ],
			join_column => 'person',
			join_map => { 1 => 'entry' },
			collision_prefix => { 1 => 'p' },
		);

		my $inner = Database::Join->new(%common, join_type => 'inner');
		my ($pushed, $plain) = both_ways($inner);
		is_deeply($pushed, $plain, 'inner: same rows with and without pushdown');
		is_deeply([ map { $_->{title} } @{$pushed} ], [ 'Alice', 'Alice', 'Carol' ], 'inner: the right rows');
		is_deeply(person_criteria(), [ { entry => { '-in' => [ 'I1', 'I3', 'I9' ] } } ],
			'inner: the secondary is asked for the primary keys only, once, sorted');

		my $left = Database::Join->new(%common, join_type => 'left');
		($pushed, $plain) = both_ways($left);
		is_deeply($pushed, $plain, 'left: same rows with and without pushdown');
		is(scalar(@{$pushed}), 4, 'left: a primary row with no secondary row is kept');
		ok((grep { $_->{person} eq 'I9' && !exists $_->{title} } @{$pushed}), 'left: and has no secondary columns');

		my $outer = Database::Join->new(%common, join_type => 'outer');
		($pushed, $plain) = both_ways($outer);
		is_deeply($pushed, $plain, 'outer: same rows');
		is_deeply(person_criteria(), [ {} ], 'outer: no pushdown, every secondary key is wanted');

		($pushed, $plain) = both_ways($inner, person => 'I3');
		is_deeply(person_criteria(), [ { entry => 'I3' } ], "the caller's join-column criterion stands");
		is_deeply([ map { $_->{title} } @{$pushed} ], [ 'Carol' ], 'and gives the right row');

		($pushed, $plain) = both_ways($left, title => 'Alice');
		is_deeply($pushed, $plain, "the secondary's own criteria still apply");
		is_deeply(person_criteria(), [ { title => 'Alice', entry => { '-in' => [ 'I1', 'I3', 'I9' ] } } ],
			'combined with the pushed-down keys');

		my $filtered = Database::Join->new(%common, join_type => 'left', filters => { 1 => { title => 'Carol' } });
		($pushed, $plain) = both_ways($filtered);
		is_deeply($pushed, $plain, 'a base filter still applies, and still makes the secondary an inner partner');
		is_deeply([ map { $_->{person} } @{$pushed} ], [ 'I3' ], 'only the filtered key survives');
	};
}

subtest 'more keys than MAX_PUSHDOWN_KEYS' => sub {
	my $big = tempdir(CLEANUP => 1);
	write_csv($big, 'pdservice', [ 'entry', 'person', 'notes' ], map { [ $_, "I$_", '' ] } 1 .. 1000);
	write_csv($big, 'pdperson', [ 'entry', 'title', 'notes' ], [ 'I1', 'Alice', '' ]);
	# The SQL path, since slurping this file crashes perl inside
	#	Data::Reuse::reuse() (Database::Abstraction 0.56), with or without
	#	no_fixate.  That is not Database::Join's doing
	my $join = Database::Join->new(
		databases => [
			Database::pdservice->new(directory => $big, max_slurp_size => 1),
			Database::pdperson->new(directory => $big, max_slurp_size => 1),
		],
		join_column => 'person', join_map => { 1 => 'entry' }, join_type => 'inner',
	);
	my ($pushed, $plain) = both_ways($join);
	is_deeply(person_criteria(), [ {} ], '1000 keys: the secondary is read in full');
	is_deeply($pushed, $plain, 'with the same result');
};

subtest 'a database that implements selectall_arrayref itself' => sub {
	my $equality = PDEqualityDA->new(rows => [ { entry => 'I1', title => 'Alice' } ]);
	my $join = Database::Join->new(
		databases => [ Database::pdservice->new(directory => $dir), $equality ],
		join_column => 'person', join_map => { 1 => 'entry' }, join_type => 'left',
	);
	my $rows = $join->selectall_arrayref();
	is_deeply($equality->{calls}, [ {} ], 'is not given -in, which it would treat as a value');
	is(scalar(grep { ($_->{title} // '') eq 'Alice' } @{$rows}), 2, 'and its rows are merged');
};

subtest 'a database that croaks on -in' => sub {
	my $join = Database::Join->new(
		databases => [ Database::pdservice->new(directory => $dir), Database::pdperson->new(directory => $dir) ],
		join_column => 'person', join_map => { 1 => 'entry' }, join_type => 'inner',
	);
	local $croak_on_in = 1;
	my ($pushed, $plain) = both_ways($join);
	is_deeply($pushed, $plain, 'is read in full instead, with the same result');
	is_deeply(person_criteria(), [ { entry => { '-in' => [ 'I1', 'I3', 'I9' ] } }, {} ], 'after one -in attempt');

	$join->selectall_arrayref();
	unlike($@, qr/-in/, "the failed attempt doesn't leak into \$@");
};

subtest 'a genuine error still reaches the caller' => sub {
	my $empty = tempdir(CLEANUP => 1);
	write_csv($empty, 'pdservice', [ 'entry', 'person', 'notes' ], [ 1, 'I1', '' ]);
	my $join = Database::Join->new(
		databases => [ Database::pdservice->new(directory => $empty), Database::pdperson->new(directory => $dir) ],
		join_column => 'person', join_map => { 1 => 'entry' },
	);
	# Point the secondary at a directory with no pdperson file, after new()
	# has read its columns
	$join->{_dbs}[1] = Database::pdperson->new(directory => $empty);
	throws_ok { $join->selectall_arrayref() } qr/Can't find a file called 'pdperson'/, 'a missing file croaks';
};

# The other formats' fixtures, which are slurped
foreach my $format([ 'TSV', 'djtsv_a', 'djtsv_b' ], [ 'JSON', 'djjson_a', 'djjson_b' ]) {
	my ($name, $a_class, $b_class) = @{$format};
	subtest $name => sub {
		my $ok = eval {
			require "Database/$a_class.pm";
			require "Database/$b_class.pm";
			1;
		};
		plan(skip_all => "$name fixtures need modules that are not installed: $@") unless($ok);

		my $data = File::Spec->catfile($Bin, 'data');
		my ($first, $second) = eval { (("Database::$a_class")->new(directory => $data), ("Database::$b_class")->new(directory => $data)) };
		plan(skip_all => "$name fixtures can't be opened: $@") unless($second);

		foreach my $type('inner', 'left') {
			my $join = Database::Join->new(databases => [ $first, $second ], join_column => 'entry', join_type => $type);
			my ($pushed, $plain) = both_ways($join);
			is_deeply($pushed, $plain, "$type: same rows with and without pushdown");
		}
	};
}

done_testing();
