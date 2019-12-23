=pod

=encoding utf-8

=head1 PURPOSE

Test that Data::Validate::CSV can parse some CSV.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

use Data::Validate::CSV;
use Data::Validate::CSV::Types qw( Table );

my $table = Table->new(
	input      => \*DATA,
	has_header => !!1,
	schema     => {
		tableSchema => {
			columns => [
				{ name => 'Country', datatype => { base => 'string', format => '^..$' } },
				{ name => 'Holiday', datatype => 'string' },
				{                    datatype => { base => 'gMonthDay', format => 'd MMM' }, separator => ';' },
			],
		}
	},
);

my @rows = $table->all_rows;

is(scalar(@rows), 4, 'read 4 rows of data');

###############################################################################

note 'row 1';

my $row = shift @rows;

is(
	$row->row_number,
	1,
	'$row->row_number'
);

is_deeply(
	$row->values,
	[ "gb", "Guy Fawkes' Night", ["--11-05"] ],
	'$row->values'
);

is_deeply(
	$row->errors,
	[],
	'$row->errors'
);

note 'row 1, cell 1';

is(
	$row->cells->[0]->value,
	'gb',
	'$row->cells->[0]->value'
);

is(
	$row->cells->[0]->inflated_value,
	'gb',
	'$row->cells->[0]->inflated_value'
);

is(
	$row->cells->[0]->row_number,
	'1',
	'$row->cells->[0]->row_number'
);

is(
	$row->cells->[0]->col_number,
	'1',
	'$row->cells->[0]->col_number'
);

is_deeply(
	$row->cells->[0]->errors,
	[],
	'$row->cells->[0]->errors'
);

is(
	$row->cells->[0]->col->name,
	'Country',
	'$row->cells->[0]->col->name'
);

note 'row 1, cell 2';

is(
	$row->cells->[1]->value,
	"Guy Fawkes' Night",
	'$row->cells->[1]->value'
);

is(
	$row->cells->[1]->inflated_value,
	"Guy Fawkes' Night",
	'$row->cells->[1]->inflated_value'
);

is(
	$row->cells->[1]->row_number,
	'1',
	'$row->cells->[1]->row_number'
);

is(
	$row->cells->[1]->col_number,
	'2',
	'$row->cells->[1]->col_number'
);

is(
	$row->cells->[1]->col->name,
	'Holiday',
	'$row->cells->[1]->col->name'
);

is_deeply(
	$row->cells->[1]->errors,
	[],
	'$row->cells->[1]->errors'
);

note 'row 1, cell 3';

is_deeply(
	$row->cells->[2]->value,
	["--11-05"],
	'$row->cells->[2]->value'
);

subtest '$row->cells->[2]->inflated_value' => sub {
	my @inflateds = @{ $row->cells->[2]->inflated_value };
	is(scalar(@inflateds), 1, 'got one inflated value');
	my $dt = shift @inflateds;
	isa_ok($dt, 'DateTime::Incomplete', '$dt');
	is(0+$dt->month, 11, '$dt->month');
	is(0+$dt->day, 5, '$dt->day');
};

is(
	$row->cells->[2]->row_number,
	'1',
	'$row->cells->[2]->row_number'
);

is(
	$row->cells->[2]->col_number,
	'3',
	'$row->cells->[2]->col_number'
);

is(
	$row->cells->[2]->col->name,
	'dates',
	'$row->cells->[2]->col->name'
);

is_deeply(
	$row->cells->[2]->errors,
	[],
	'$row->cells->[2]->errors'
);

###############################################################################

$row = shift @rows;

note 'row 2';

is(
	$row->row_number,
	2,
	'$row->row_number'
);

is_deeply(
	$row->values,
	[ "lots of places", "Christmas", ["--12-25"] ],
	'$row->values'
);

is(
	scalar(@{$row->errors}),
	1,
	'$row->errors'
);

like(
	$row->errors->[0],
	qr/fails additional constraints/,
	'$row->errors->[0]'
);

note 'row 2, cell 1';

is(
	$row->cells->[0]->value,
	'lots of places',
	'$row->cells->[0]->value'
);

is(
	$row->cells->[0]->inflated_value,
	'lots of places',
	'$row->cells->[0]->inflated_value'
);

is(
	$row->cells->[0]->row_number,
	'2',
	'$row->cells->[0]->row_number'
);

is(
	$row->cells->[0]->col_number,
	'1',
	'$row->cells->[0]->col_number'
);

is(
	scalar(@{$row->cells->[0]->errors}),
	1,
	'$row->cells->[0]->errors'
);

like(
	$row->cells->[0]->errors->[0],
	qr/fails additional constraints/,
	'$row->cells->[0]->errors->[0]'
);

is(
	$row->cells->[0]->col->name,
	'Country',
	'$row->cells->[0]->col->name'
);

note 'row 2, cell 2';

is(
	$row->cells->[1]->value,
	"Christmas",
	'$row->cells->[1]->value'
);

is(
	$row->cells->[1]->inflated_value,
	"Christmas",
	'$row->cells->[1]->inflated_value'
);

is(
	$row->cells->[1]->row_number,
	'2',
	'$row->cells->[1]->row_number'
);

is(
	$row->cells->[1]->col_number,
	'2',
	'$row->cells->[1]->col_number'
);

is(
	$row->cells->[1]->col->name,
	'Holiday',
	'$row->cells->[1]->col->name'
);

is_deeply(
	$row->cells->[1]->errors,
	[],
	'$row->cells->[1]->errors'
);

note 'row 2, cell 3';

is_deeply(
	$row->cells->[2]->value,
	["--12-25"],
	'$row->cells->[2]->value'
);

subtest '$row->cells->[2]->inflated_value' => sub {
	my @inflateds = @{ $row->cells->[2]->inflated_value };
	is(scalar(@inflateds), 1, 'got one inflated value');
	my $dt = shift @inflateds;
	isa_ok($dt, 'DateTime::Incomplete', '$dt');
	is(0+$dt->month, 12, '$dt->month');
	is(0+$dt->day, 25, '$dt->day');
};

is(
	$row->cells->[2]->row_number,
	'2',
	'$row->cells->[2]->row_number'
);

is(
	$row->cells->[2]->col_number,
	'3',
	'$row->cells->[2]->col_number'
);

is(
	$row->cells->[2]->col->name,
	'dates',
	'$row->cells->[2]->col->name'
);

is_deeply(
	$row->cells->[2]->errors,
	[],
	'$row->cells->[2]->errors'
);

###############################################################################

$row = shift @rows;

note 'row 3';

is(
	$row->row_number,
	3,
	'$row->row_number'
);

is_deeply(
	$row->values,
	[ "us", "National Gorilla Suit Day", ["--01-31"], "apparently"],
	'$row->values'
);

is_deeply(
	$row->errors,
	[],
	'$row->errors'
);

note 'row 3, cell 1';

is(
	$row->cells->[0]->value,
	'us',
	'$row->cells->[0]->value'
);

is(
	$row->cells->[0]->inflated_value,
	'us',
	'$row->cells->[0]->inflated_value'
);

is(
	$row->cells->[0]->row_number,
	'3',
	'$row->cells->[0]->row_number'
);

is(
	$row->cells->[0]->col_number,
	'1',
	'$row->cells->[0]->col_number'
);

is_deeply(
	$row->cells->[0]->errors,
	[],
	'$row->cells->[0]->errors'
);

is(
	$row->cells->[0]->col->name,
	'Country',
	'$row->cells->[0]->col->name'
);

note 'row 3, cell 2';

is(
	$row->cells->[1]->value,
	"National Gorilla Suit Day",
	'$row->cells->[1]->value'
);

is(
	$row->cells->[1]->inflated_value,
	"National Gorilla Suit Day",
	'$row->cells->[1]->inflated_value'
);

is(
	$row->cells->[1]->row_number,
	'3',
	'$row->cells->[1]->row_number'
);

is(
	$row->cells->[1]->col_number,
	'2',
	'$row->cells->[1]->col_number'
);

is(
	$row->cells->[1]->col->name,
	'Holiday',
	'$row->cells->[1]->col->name'
);

is_deeply(
	$row->cells->[1]->errors,
	[],
	'$row->cells->[1]->errors'
);

note 'row 3, cell 3';

is_deeply(
	$row->cells->[2]->value,
	["--01-31"],
	'$row->cells->[2]->value'
);

subtest '$row->cells->[2]->inflated_value' => sub {
	my @inflateds = @{ $row->cells->[2]->inflated_value };
	is(scalar(@inflateds), 1, 'got one inflated value');
	my $dt = shift @inflateds;
	isa_ok($dt, 'DateTime::Incomplete', '$dt');
	is(0+$dt->month, 1, '$dt->month');
	is(0+$dt->day, 31, '$dt->day');
};

is(
	$row->cells->[2]->row_number,
	'3',
	'$row->cells->[2]->row_number'
);

is(
	$row->cells->[2]->col_number,
	'3',
	'$row->cells->[2]->col_number'
);

is(
	$row->cells->[2]->col->name,
	'dates',
	'$row->cells->[2]->col->name'
);

is_deeply(
	$row->cells->[2]->errors,
	[],
	'$row->cells->[2]->errors'
);

###############################################################################

$row = shift @rows;

note 'row 4';

is(
	$row->row_number,
	4,
	'$row->row_number'
);

is_deeply(
	$row->values,
	[ "lots of places", "New Year", ["--12-31","--01-01"] ],
	'$row->values'
);

is(
	scalar(@{$row->errors}),
	1,
	'$row->errors'
);

like(
	$row->errors->[0],
	qr/fails additional constraints/,
	'$row->errors->[0]'
);

note 'row 4, cell 1';

is(
	$row->cells->[0]->value,
	'lots of places',
	'$row->cells->[0]->value'
);

is(
	$row->cells->[0]->inflated_value,
	'lots of places',
	'$row->cells->[0]->inflated_value'
);

is(
	$row->cells->[0]->row_number,
	'4',
	'$row->cells->[0]->row_number'
);

is(
	$row->cells->[0]->col_number,
	'1',
	'$row->cells->[0]->col_number'
);

is(
	scalar(@{$row->cells->[0]->errors}),
	1,
	'$row->cells->[0]->errors'
);

like(
	$row->cells->[0]->errors->[0],
	qr/fails additional constraints/,
	'$row->cells->[0]->errors->[0]'
);

is(
	$row->cells->[0]->col->name,
	'Country',
	'$row->cells->[0]->col->name'
);

note 'row 4, cell 2';

is(
	$row->cells->[1]->value,
	"New Year",
	'$row->cells->[1]->value'
);

is(
	$row->cells->[1]->inflated_value,
	"New Year",
	'$row->cells->[1]->inflated_value'
);

is(
	$row->cells->[1]->row_number,
	'4',
	'$row->cells->[1]->row_number'
);

is(
	$row->cells->[1]->col_number,
	'2',
	'$row->cells->[1]->col_number'
);

is(
	$row->cells->[1]->col->name,
	'Holiday',
	'$row->cells->[1]->col->name'
);

is_deeply(
	$row->cells->[1]->errors,
	[],
	'$row->cells->[1]->errors'
);

note 'row 4, cell 3';

is_deeply(
	$row->cells->[2]->value,
	["--12-31","--01-01"],
	'$row->cells->[2]->value'
);

subtest '$row->cells->[2]->inflated_value' => sub {
	my @inflateds = @{ $row->cells->[2]->inflated_value };
	is(scalar(@inflateds), 2, 'got two inflated values');
	my $dt = shift @inflateds;
	isa_ok($dt, 'DateTime::Incomplete', '$dt');
	is(0+$dt->month, 12, '$dt->month');
	is(0+$dt->day, 31, '$dt->day');
	$dt = shift @inflateds;
	isa_ok($dt, 'DateTime::Incomplete', '$dt');
	is(0+$dt->month, 1, '$dt->month');
	is(0+$dt->day, 1, '$dt->day');
};

is(
	$row->cells->[2]->row_number,
	'4',
	'$row->cells->[2]->row_number'
);

is(
	$row->cells->[2]->col_number,
	'3',
	'$row->cells->[2]->col_number'
);

is(
	$row->cells->[2]->col->name,
	'dates',
	'$row->cells->[2]->col->name'
);

is_deeply(
	$row->cells->[2]->errors,
	[],
	'$row->cells->[2]->errors'
);

###############################################################################

done_testing;

__DATA__
country,holiday,dates
gb,"Guy Fawkes' Night",5 Nov
lots of places,"Christmas",25 Dec
us,"National Gorilla Suit Day",31 Jan,apparently
lots of places,"New Year",31 Dec;1 Jan
