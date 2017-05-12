use strict;

use Test::More tests => 9;

use_ok( 'Data::Tabular' );

use Digest::MD5  qw(md5 md5_hex md5_base64);

my $t1 = Data::Tabular->new(
    headers => [ 'animal', 'color', 'owner', 'jan', 'feb', 'amount', 'date' ],
    data => [
	[ 'cat', 'black', 'jane', 1, 2, 1.01, '2006-05-11T13:01:02.001' ],
	[ 'cat', 'black', 'joey', 2, 3, 1.01, '2002-01-01T' ],
	[ 'cat', 'white', 'jack', 3, 4, 1.01, '2002-01-01T' ],
	[ 'cat', 'white', 'john', 4, 5, 1.01, '2002-01-01T' ],
	[ 'bat', 'gray',  'john', 4, 5, -99999.99, '2002-01-01T' ],
	[ 'bat', 'gray',  'john', 1, 1, 1, '2002-01-01T' ],
	[ 'dog', 'white', 'john', 5, 6, 1.01, '2002-01-01T' ],
	[ 'dog', 'white', 'joey', 6, 7, 1.01, '2002-01-01T' ],
	[ 'dog', 'black', 'jack', 7, 8, 1.01, '2002-01-01T' ],
	[ 'dog', 'black', 'jane', 8, 90900, 100007.01, '2002-01-01T' ],
	[ 'rabbit', 'black', 'jane', 8, 9, 1.01, '2006-01-01T' ],
    ],
    extra_headers => [ qw ( extra1 extra2 extra3 extra4 ) ],
    extra => {
        extra1 => sub { 'H' },
        extra2 => sub { 'I' },
        extra3 => sub { my $self = shift; $self->sum('jan', 'feb'); },
        extra4 => sub { my $self = shift; $self->average('jan', 'feb'); },
    },
    group_by => {
	groups => [
	    {
		pre => sub { my $self = shift; ($self->header(text => "First"), $self->titles() ) },
		post => sub { my $self = shift; (
		    $self->totals(title => "Totals", sum_list => ['jan', 'feb', 'extra3', 'extra4', 'amount' ]),
		    $self->averages(title => "Averages ", sum_list => ['jan', 'feb', 'extra3', 'extra4', 'amount' ]),
		    $self->header(text => "Last"),
		); },
	    },
	    {
		column => 'animal',
		pre => sub { my $self = shift; $self->header(text => "This is a header animal (" . $self->get('animal') . ")"); },
	    },
	],
    },
);

my $xls;

SKIP: {
    my $skip;
    eval { require Spreadsheet::WriteExcel; };
    $skip++ if $@;
    skip 'Need Spreadsheet::WriteExcel', 3 if $skip;
    my $workbook = Spreadsheet::WriteExcel->new("/tmp/test2.xls");
    my $worksheet = $workbook->add_worksheet();
    my $output = $t1->output();

    $output->set_type(name => 'date', type => 'time');
    $output->set_type(name => 'jan', type => 'number');
    $output->set_type(name => 'feb', type => 'number');
    $output->set_type(name => 'extra3', type => 'number');
    $output->set_type(name => 'extra4', type => 'number');
    $output->set_type(name => 'amount', type => 'dollar');
    $output->{headers} = [
	'animal', 'color', 'owner', 'jan', 'feb', 'extra3', 'extra4', 'amount', 'extra1', 'extra2', 'date'
    ];

    my $t2 = $t1->xls(workbook => $workbook, worksheet => $worksheet, output => $output);

    my $table = $t2->table;

    ok(ref($table) eq 'Data::Tabular::Group', 'table type');

    is($table->row_count, 20, 'rows');

    ok(1, 'html');
}


SKIP: {
    my $skip;
    eval {
	require Spreadsheet::ParseExcel;
    };
    $skip++ if $@;
    skip 'Need Spreadsheet::ParseExcel', 5 if $skip;
    my $book = Spreadsheet::ParseExcel::Workbook->Parse("/tmp/test2.xls");
    my $worksheet = $book->{Worksheet}[0];
    is($worksheet->Cell(0, 0)->Value, 'First', 'First');

    is($worksheet->Cell(3, 5)->Value, 3);

    is($worksheet->Cell(17, 5)->Value, '90999');
    is($worksheet->Cell(18, 5)->Value, '8272.63636363636');

    ok(1, 'xls');
}

