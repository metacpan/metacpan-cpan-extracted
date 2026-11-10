#!/usr/bin/env perl

# A quote inside a quoted field.  A spreadsheet writes it as two quotes
# ("Adeste Fidelis ""Overture"""), which was shown as ""Overture"": the file
# was read with a backslash escape, as files that write "Joe\"s Bar" need.
# Database::Abstraction (>= 0.56) and DataSource now choose the escape per
# file, the same way (_csv_escape_char), for files with a header and without.
#
#   prove -l t/csv-quotes.t

use strict;
use warnings;

use File::Temp qw(tempdir);
use Mojo::File;
use Test::Most;
use Test::Mojo;

my $data_dir  = Mojo::File->new(tempdir(CLEANUP => 1));
my $model_dir = tempdir(CLEANUP => 1);

my $t = Test::Mojo->new('Database::BI', { data_dir => $data_dir->to_string, model_dir => $model_dir });

plan skip_all => 'Database::Abstraction 0.56 reads doubled quotes'
	unless eval { require Database::Abstraction; Database::Abstraction->VERSION(0.56); 1 };

# The cells of one column of a table page, in order.
sub column {
	my ($table, $column) = @_;
	$t->get_ok("/view/$table?per_page=100")->status_is(200);
	my $dom  = $t->tx->res->dom;
	my @head = $dom->find('#bi-table thead th')->map('all_text')->each;
	my ($at) = grep { $head[$_] eq $column } 0 .. $#head;
	return [ $dom->find('#bi-table tbody tr')->map(sub { $_->find('td')->[$at]->all_text })->each ];
}

subtest 'two quotes are one' => sub {
	$data_dir->child('band.csv')->spew(qq{id,title\n1,"Adeste Fidelis ""Overture"""\n2,"A, B"\n3,Plain\n});
	is_deeply(column('band', 'title'), [ 'Adeste Fidelis "Overture"', 'A, B', 'Plain' ], 'as the spreadsheet wrote them');
};

subtest 'a backslash escape still reads' => sub {
	$data_dir->child('bar.csv')->spew(qq{id,name\n1,"Joe\\"s Bar"\n2,""\n3,Plain\n});
	is_deeply(column('bar', 'name'), [ 'Joe"s Bar', '', 'Plain' ], 'and an empty quoted field changes nothing');
};

subtest 'the id column is chosen past a doubled quote' => sub {
	# The scan that picks the id parses with the file's escape too: code is
	# empty in two rows of three, ref in one, so ref is the id and no row is lost.
	$data_dir->child('pick.csv')->spew(qq{code,ref,title\n,r1,"A ""b"", c"\nx,,"B"\n,r3,C\n});
	is_deeply(column('pick', 'title'), [ 'A "b", c', 'B', 'C' ], 'every row is shown');
};

subtest 'a file with no header' => sub {
	$data_dir->child('bank.csv')->spew(qq{2026-01-02,-12.50,"Joe's ""Diner"""\n2026-01-03,40.00,"Pay, Inc"\n});
	is_deeply(column('bank', 'Description'), [ q{Joe's "Diner"}, 'Pay, Inc' ], 'two quotes are one');
	$data_dir->child('bank2.csv')->spew(qq{2026-01-02,-12.50,"Joe\\"s Diner"\n2026-01-03,40.00,"Pay, Inc"\n});
	is_deeply(column('bank2', 'Description'), [ q{Joe"s Diner}, 'Pay, Inc' ], 'and a backslash escape');
};

subtest '_csv_escape_char' => sub {
	my $file = $data_dir->child('x.txt');
	for my $case ([ qq{a,"b ""c"""\n}, '"' ], [ qq{a,"b \\"c\\""\n}, '\\' ], [ qq{a,"b"\n}, '\\' ],
		[ qq{a,"x ""y"""\nb,"p \\"q\\""\n}, '\\' ]) {
		$file->spew($case->[0]);
		is(Database::BI::Model::DataSource::_csv_escape_char("$file"), $case->[1], "escape for $case->[0]");
	}
	is(Database::BI::Model::DataSource::_csv_escape_char("$data_dir/missing.csv"), '\\', 'a file that will not open');
};

done_testing();
