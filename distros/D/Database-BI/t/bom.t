#!/usr/bin/env perl

# A file saved by Excel or Notepad as "UTF-8 with BOM" starts with the bytes
# EF BB BF.  Read as they are, they become part of the first column's name
# (so it is no longer a safe identifier, and a header-less file's first cell
# no longer looks like a date).  DataSource reads past them; these check the
# names and the cells that come back, for each kind of file that can carry one.
#
#   prove -l t/bom.t

use strict;
use warnings;

use Test::Most;
use Test::Mojo;
use File::Temp qw(tempdir);
use Mojo::DOM;
use Mojo::File;
use Mojo::Util qw(url_escape);

my $t = Test::Mojo->new('Database::BI');
$t->app->config->{model_dir} = tempdir(CLEANUP => 1);

my $BOM = "\xEF\xBB\xBF";

# fixture($name, $bytes) -> $path, each in a folder of its own: two files with
# one stem are one table.
sub fixture {
	my ($name, $bytes) = @_;
	my $path = Mojo::File->new(tempdir(CLEANUP => 1))->child($name);
	$path->spew($bytes);
	return "$path";
}

# table($path) -> (\@headers, \@first_row) from the /open page.
sub table {
	my ($path) = @_;
	$t->get_ok('/open?path=' . url_escape($path))->status_is(200);
	my $dom = Mojo::DOM->new($t->tx->res->body);
	my @headers = map { s/\A\s+|\s+\z//gr =~ s/\s+/ /gr }
		$dom->find('#bi-table thead th')->map('all_text')->each;
	my $row = $dom->at('#bi-table tbody tr');
	my @cells = $row ? $row->find('td')->map('all_text')->each : ();
	return (\@headers, \@cells);
}

sub no_bom_ok {
	my ($list, $name) = @_;
	ok(!(grep { /\x{FEFF}|\xEF\xBB\xBF/ } @{$list}), $name);
}

for my $case (
	[ 'CSV', 'bom.csv', "Name,Score\nada,10\nbob,20\n", [qw(Name Score)], 'ada' ],
	[ 'TSV', 'bom.tsv', "Name\tScore\nada\t10\nbob\t20\n", [qw(Name Score)], 'ada' ],
	[ 'PSV', 'bom.psv', "Name|Score\nada|10\nbob|20\n", [qw(Name Score)], 'ada' ],
	[ 'JSON', 'bom.json', qq{[{"Name":"ada","Score":10},{"Name":"bob","Score":20}]}, [qw(Name Score)], 'ada' ],
) {
	my ($kind, $file, $text, $want, $first) = @{$case};
	subtest "A $kind file that starts with a byte-order mark" => sub {
		my ($plain_h, $plain_c) = table(fixture($file, $text));
		my ($h, $c) = table(fixture($file, $BOM . $text));
		for my $col (@{$want}) {
			ok((grep { $_ eq $col } @{$h}), "column $col is named as written");
		}
		no_bom_ok($h, 'no header holds the mark');
		no_bom_ok($c, 'no cell holds the mark');
		ok((grep { $_ eq $first } @{$c}), "the first row is there ($first)");
		is_deeply($h, $plain_h, 'the same headers as without the mark');
		is_deeply($c, $plain_c, 'the same first row as without the mark');
	};
}

subtest 'A header-less CSV that starts with a byte-order mark' => sub {
	# No cell of the first line is a safe identifier, so it is data.
	my $text = "2026-01-05,-12.50,Coffee shop\n2026-01-06,(3.00),Tea room\n";
	my ($plain_h, $plain_c) = table(fixture('nohead.csv', $text));
	my ($h, $c) = table(fixture('nohead.csv', $BOM . $text));
	ok((grep { $_ eq 'Date' } @{$h}), 'still read as header-less (Date column made up)');
	no_bom_ok($h, 'no header holds the mark');
	no_bom_ok($c, 'no cell holds the mark');
	ok((grep { $_ eq '2026-01-05' } @{$c}), 'the first date is as written');
	is_deeply($h, $plain_h, 'the same headers as without the mark');
	is_deeply($c, $plain_c, 'the same first row as without the mark');
};

subtest 'A file whose name is not an identifier, with a byte-order mark' => sub {
	# Read through a link of a safe name, and the copy without the mark too.
	my ($h, $c) = table(fixture('my scores.csv', $BOM . "Name,Score\nada,10\n"));
	is_deeply($h, [qw(Name Score)], 'the columns are named as written');
	is_deeply($c, [qw(ada 10)], 'the row is as written');
};

done_testing();
