use strict;
use warnings;

# Browse your files: tick several files and open them as one table, as the
# Combine data panel does.  Every file is a path: spec, the first one l= and
# the rest c=.  A folder of reports (DMARC XML) is a long URL, a long trail and
# a long title, and all three have to cope.
#
#   prove -l t/browse-combine.t

use Test::More;
use Test::Mojo;
use Mojo::DOM;
use Mojo::File;
use Mojo::Util qw(url_escape);
use File::Temp ();

my $dir   = Mojo::File->new(File::Temp::tempdir(CLEANUP => 1))->realpath;
my $store = File::Temp::tempdir(CLEANUP => 1);

my $N = 120;
for my $i (1 .. $N) {
	my $name = sprintf('report-with-a-fairly-long-name-%03d.csv', $i);
	$dir->child($name)->spew("ip,count\n10.0.0.$i,$i\n");
}

my $t = Test::Mojo->new('Database::BI', { data_dir => $dir->to_string, model_dir => $store });
my $HTML = { Accept => 'text/html' };

subtest 'the folder page offers a tick for each file' => sub {
	$t->get_ok('/browse?path=' . url_escape($dir->to_string), $HTML)->status_is(200);
	my $dom = Mojo::DOM->new($t->tx->res->body);
	is($dom->find('input.browser-pick')->size, $N, 'one checkbox a file');
	ok($dom->at('#browse-pick-all'), 'a Select all');
	ok($dom->at('#browse-combine[disabled]'), 'Combine selected waits for two files');
	my $first = $dom->at('input.browser-pick')->{value};
	is($first, $dir->child('report-with-a-fairly-long-name-001.csv')->to_string, 'the value is the file path');
	is($dom->find('a.browser-file')->size, $N, 'the files still open one at a time');
};

subtest 'a folder with one file has nothing to combine' => sub {
	my $one = Mojo::File->new(File::Temp::tempdir(CLEANUP => 1))->realpath;
	$one->child('only.csv')->spew("a,b\n1,2\n");
	$t->get_ok('/browse?path=' . url_escape($one->to_string), $HTML)->status_is(200);
	my $dom = Mojo::DOM->new($t->tx->res->body);
	is($dom->find('input.browser-pick')->size, 0, 'no checkbox');
	ok(!$dom->at('#browse-combine'), 'no Combine selected');
};

subtest 'every file of the folder stacks into one table' => sub {
	my @files = map { $dir->child(sprintf('report-with-a-fairly-long-name-%03d.csv', $_))->to_string } 1 .. $N;
	my $url = '/combine?l=' . url_escape("path:$files[0]")
		. join('', map { '&c=' . url_escape("path:$_") } @files[1 .. $#files])
		. '&per_page=0&back2=' . url_escape('/browse?path=' . url_escape($dir->to_string));
	cmp_ok(length($url), '>', 8192, 'longer than the start line Mojolicious allows by default');

	$t->get_ok($url, $HTML)->status_is(200);
	my $body = $t->tx->res->body;
	for my $n (1, 60, $N) {
		like($body, qr{<td[^>]*>10\.0\.0\.$n</td>}, "the rows of file $n are there");
	}
	like($body, qr/\+ \d+ more/, 'the title names a few files and counts the rest');
	unlike($body, qr/report-with-a-fairly-long-name-050\.csv \+/, 'and does not list them all');

	my $dom = Mojo::DOM->new($body);
	my $trail = join ' ', map { $_->all_text } $dom->at('nav[aria-label="Breadcrumb"] .crumbs')->children->each;
	like($trail, qr/Files: \S+/, 'the trail goes back to the folder');
	cmp_ok(length($trail), '<', 400, 'and is short');
	my $key = $dom->at('[data-table]')->{'data-table'};
	cmp_ok(length($key), '<=', 120, 'the saved-layout key is short');
};

subtest 'srccol= names the file each row came from' => sub {
	my @files = map { $dir->child(sprintf('report-with-a-fairly-long-name-%03d.csv', $_))->to_string } 1 .. 3;
	my $q = '/combine?l=' . url_escape("path:$files[0]")
		. join('', map { '&c=' . url_escape("path:$_") } @files[1, 2]);

	$t->get_ok("$q&srccol=source_file", $HTML)->status_is(200);
	my $body = $t->tx->res->body;
	like($body, qr{<th[^>]*>\s*source_file}, 'the column is in the table head');
	for my $n (1 .. 3) {
		like($body, qr{<td[^>]*>report-with-a-fairly-long-name-00$n\.csv</td>}, "file $n is named in its row");
	}
	like($body, qr{<input type="hidden" name="srccol" value="source_file">}, 'a panel passes it on');
	like($body, qr{&amp;srccol=source_file}, 'and so does the filter bar');

	$t->get_ok($q, $HTML)->status_is(200);
	unlike($t->tx->res->body, qr/source_file/, 'without srccol there is no column');

	$t->get_ok("$q&srccol=" . url_escape('x"><b>'), $HTML)->status_is(200);
	unlike($t->tx->res->body, qr/<b>/, 'a name that is not an identifier is ignored');

	$t->get_ok("$q&srccol=ip&format=json&per_page=0", $HTML)->status_is(200);
	like($t->tx->res->body, qr/>\s*ip_\s*</, 'a name a file already uses gets an underscore');

	$t->get_ok('/export?format=csv&srccol=source_file&l=' . url_escape("path:$files[0]")
		. '&c=' . url_escape("path:$files[1]"))->status_is(200);
	like($t->tx->res->body, qr/source_file/, 'Export has it too');
};

subtest 'the Browse button asks for it' => sub {
	$t->get_ok('/browse?path=' . url_escape($dir->to_string), $HTML)->status_is(200)
		->content_like(qr/srccol=source_file/);
};

done_testing;
