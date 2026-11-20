#!/usr/bin/perl

# A join of a join: the outer join ATTACHes the inner join's temp file and
# reads its _dj_result table.  When the outer join then materialises its own
# _dj_result, an unqualified DROP TABLE IF EXISTS found the attached copy
# first and deleted it, so the next statement failed with
# "no such table: ext0._dj_result".

use strict;
use warnings;

use Test::Most;

use lib 't/lib';
use_ok('Database::Join');

{
	package StubDA;
	sub new { my ($c, %a) = @_; return bless {%a}, $c }
	sub columns { return $_[0]{cols} }
	sub selectall_arrayref {
		my ($self, $crit) = @_;
		$crit //= {};
		return [ grep {
			my $r = $_;
			!grep { !defined $r->{$_} || $r->{$_} ne $crit->{$_} } keys %{$crit}
		} map { +{%{$_}} } @{ $self->{rows} } ];
	}
}

my $bands = StubDA->new(
	cols => [qw(id title type)],
	rows => [
		{ id => 1, title => 'March A', type => 10 },
		{ id => 2, title => 'Waltz B', type => 20 },
		{ id => 3, title => 'March C', type => 10 },
	],
);
my $notes = StubDA->new(
	cols => [qw(id note)],
	rows => [ { id => 1, note => 'n1' }, { id => 2, note => 'n2' }, { id => 3, note => 'n3' } ],
);
my $types = StubDA->new(
	cols => [qw(type name)],
	rows => [ { type => 10, name => 'March' }, { type => 20, name => 'Waltz' } ],
);

for my $backend (qw(sqlite auto)) {
	subtest "join of a join, backend $backend" => sub {
		my $inner = Database::Join->new(
			databases => [$bands, $notes], join_column => 'id',
			backend => $backend, max_array_rows => 1,
		);
		my $outer = Database::Join->new(
			databases => [$inner, $types], join_column => 'type',
			backend => $backend, max_array_rows => 1,
		);

		my $rows;
		lives_ok { $rows = $outer->selectall_arrayref } 'outer join runs';
		is scalar @{ $rows // [] }, 3, 'three rows';
		is_deeply [ sort map { $_->{name} } @{ $rows // [] } ], [qw(March March Waltz)],
			'columns from all three sources present';

		my $src;
		lives_ok { $src = $outer->dbi_source } 'outer dbi_source materialises';
		is $src->{table}, '_dj_result', 'table name';
		is $src->{dbh}->selectrow_array('SELECT COUNT(*) FROM _dj_result'), 3,
			'outer _dj_result holds the rows';

		# The inner join's own result must survive the outer one being built.
		my $isrc = $inner->dbi_source;
		is $isrc->{dbh}->selectrow_array('SELECT COUNT(*) FROM _dj_result'), 3,
			'inner _dj_result still present';
	};
}

done_testing;
