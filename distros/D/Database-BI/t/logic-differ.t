use strict;
use warnings;
use Test::Most;
use Hash::Util qw(lock_keys);
use Test::Mojo;

# Logic proof for the differ operator of _apply_filter_spec.
#
# Major Premise: f=a:differ:b keeps a row exactly when text(a) ne text(b),
#   where text(c) is the cell, or '' when the cell is undef or the key absent.
# Each partition below is one class of (text(a), text(b)); one row proves the
# class, so no class is tried twice.

Test::Mojo->new('Database::BI');	# loads the controller
my $FILTER = \&Database::BI::Controller::Dashboard::_apply_filter_spec;

# Locked hashes, as a SQL source gives: reading a missing key would croak.
sub row {
	my (%cells) = @_;
	my %row = (id => delete $cells{id}, a => undef, b => undef);
	@row{ keys %cells } = values %cells;
	lock_keys(%row);
	return \%row;
}

sub kept {
	my ($rows) = @_;
	return join ',', map { $_->{id} } @{ $FILTER->($rows, 'a:differ:b') };
}

my %partition = (
	'identical text'                 => [row(id => 1, a => 'x', b => 'x'),     ''],
	'both empty strings'             => [row(id => 2, a => '',  b => ''),      ''],
	'both undef'                     => [row(id => 3),                         ''],
	'undef against empty string'     => [row(id => 4, a => undef, b => ''),    ''],
	'different text'                 => [row(id => 5, a => 'x', b => 'y'),     '5'],
	'case differs'                   => [row(id => 6, a => 'Ann', b => 'ann'), '6'],
	'spacing differs'                => [row(id => 7, a => 'x', b => 'x '),    '7'],
	'one side empty'                 => [row(id => 8, a => 'x', b => ''),      '8'],
	'one side undef'                 => [row(id => 9, a => undef, b => 'x'),   '9'],
	'numbers equal as text only'     => [row(id => 10, a => '1.0', b => '1'),  '10'],
);
for my $name (sort keys %partition) {
	my ($row, $want) = @{ $partition{$name} };
	is(kept([$row]), $want, $name);
}

# A row that lacks the second column is a row whose cell there is empty.
my %narrow = (id => 11, a => 'x');
lock_keys(%narrow);
is(kept([\%narrow]), '11', 'a missing key reads as empty, and a locked hash survives');

# Symmetry: swapping the columns cannot change which rows stay.
my @rows = map { $_->[0] } values %partition;
is(join(',', sort map { $_->{id} } @{ $FILTER->(\@rows, 'b:differ:a') }),
   join(',', sort map { $_->{id} } @{ $FILTER->(\@rows, 'a:differ:b') }),
   'differ is symmetric');

# Irreflexive: no cell differs from itself, so the result is empty.
is(scalar @{ $FILTER->(\@rows, 'a:differ:a') }, 0, 'a column never differs from itself');

# Fail fast: the input array is never altered or reused as the answer.
my $out = $FILTER->(\@rows, 'a:differ:b');
isnt($out, \@rows, 'a new array is returned');
is(scalar @rows, scalar keys %partition, 'and the input is untouched');

# The value is a column name, so a colon-free value is all it needs: a spec
# with no value names the empty column, which is absent, so cells compare to ''.
is(scalar @{ $FILTER->([row(id => 1, a => 'x')], 'a:differ') }, 1,
   'differ with no column named compares against empty');

done_testing;
