use strict;
use warnings;

# Every page shows where it is: Home, then each page between Home and this
# one, then this page, which is not a link.  The trail is followed up from the
# page's own URL (a chart's back=, drilled rows' back2=, a file's folder), so
# these tests open pages the way the user would reach them and read the
# trail back.
#
#   prove -l t/breadcrumb.t

use Test::More;
use Test::Mojo;
use Mojo::DOM;
use Mojo::File;
use Mojo::JSON qw(encode_json);
use Mojo::Util qw(url_escape);
use File::Temp ();

my $data_dir  = Mojo::File->new(File::Temp::tempdir(CLEANUP => 1));
my $model_dir = Mojo::File->new(File::Temp::tempdir(CLEANUP => 1))->to_string;

$data_dir->child('sales.csv')->spew(
	"code,region,amount\nA1,North,10\nA2,South,5\nB1,North,7\n");

my $t = Test::Mojo->new('Database::BI', {
	data_dir  => $data_dir->to_string,
	model_dir => $model_dir,
});

# The trail on a page as [ text, href ], href undef for the current page.
sub crumbs {
	my ($url) = @_;
	my $body = $t->get_ok($url)->tx->res->body;
	my $dom  = Mojo::DOM->new($body);
	my @navs = $dom->find('nav[aria-label="Breadcrumb"]')->each;
	is(scalar @navs, 1, "one breadcrumb on $url") or return [];
	return [ map { [ $_->all_text, $_->tag eq 'a' ? $_->{href} : undef ] }
		$navs[0]->at('.crumbs')->children->each ];
}

# Just the names, Home included.
sub names { [ map { $_->[0] } @{ $_[0] } ] }

my $bar     = '/bar?l=table:sales&cat=region&val=amount';
my $drilled = '/view/sales?f=' . url_escape('region:eq:North') . '&back2=' . url_escape($bar);

subtest 'a table is the first step below Home' => sub {
	my $c = crumbs('/view/sales');
	is_deeply(names($c), ["\x{2190} Home", 'sales'], 'Home > sales');
	is($c->[0][1], '/', 'Home links to /');
	ok(!defined $c->[-1][1], 'the current page is not a link');
};

subtest 'a chart names what it shows and links to its table' => sub {
	my $c = crumbs($bar);
	is_deeply(names($c), ["\x{2190} Home", 'sales', 'Bar chart: amount by region'],
		'Home > sales > Bar chart: amount by region');
	is($c->[1][1], '/view/sales', 'the table crumb links to the table');
};

subtest 'drilling into a chart keeps the chart in the trail' => sub {
	my $c = crumbs($drilled);
	is_deeply(names($c),
		["\x{2190} Home", 'sales', 'Bar chart: amount by region', 'sales (region = North)'],
		'Home > sales > Bar chart > the filtered rows');
	is($c->[2][1], $bar, 'the chart crumb returns to the same chart');
};

subtest 'a chart of drilled rows goes one step further' => sub {
	my $pie = '/pie?l=table:sales&cat=region&val=amount&f=' . url_escape('region:eq:North')
		. '&back=' . url_escape($drilled);
	my $c = crumbs($pie);
	is(scalar @$c, 5, 'five steps');
	is($c->[3][0], 'sales (region = North)', 'the drilled rows are named by their filter');
	is($c->[3][1], $drilled, 'and link back to them');
	is($c->[4][0], 'Pie chart: amount by region', 'the pie is the current page');
};

subtest 'a file opened from the browser sits under its folder' => sub {
	my $file = $data_dir->child('sales.csv')->to_string;
	my $c = crumbs('/open?path=' . url_escape($file));
	is($c->[-1][0], 'sales.csv', 'the file is the current page');
	like($c->[-2][0], qr/\AFiles: /, 'its folder comes before it');
	like($c->[-2][1], qr{\A/browse\?path=}, 'and links to the file browser');
};

subtest 'folder levels follow the folder view' => sub {
	my $c = crumbs('/folder?l=table:sales&col=code&prefix=A');
	my @n = @{ names($c) };
	is($n[1], 'sales', 'the table comes first');
	is($n[2], 'Folder view: code', 'then the folder view');
	like($c->[2][1] // '', qr{\A(?:/folder)?\?l=table%3Asales}, 'which is a link, the trail going on below it');
	ok(!defined $c->[-1][1], 'the deepest level is the current page');
};

subtest 'a saved canvas is named' => sub {
	my $id = $t->post_ok('/api/analyses', { 'Content-Type' => 'application/json' },
		encode_json({
			name     => 'Quarterly',
			datasets => [ { spec => 'table:sales', alias => 'left' } ],
			visuals  => [ { kind => 'table', title => 'All', encode => { columns => [qw(code region amount)] } } ],
		})
	)->status_is(201)->tx->res->json->{id};
	is_deeply(names(crumbs("/a/$id")), ["\x{2190} Home", 'Quarterly'], 'Home > Quarterly');
};

subtest 'a missing canvas is a page with a breadcrumb, not plain text' => sub {
	my $body = $t->get_ok('/a/doesnotexist')->status_is(404)
		->content_type_like(qr{text/html})->tx->res->body;
	like($body, qr/aria-label="Breadcrumb"/, 'the breadcrumb is there');
	unlike($body, qr/id="canvas-error-delete"/, 'nothing to delete');
};

subtest 'a page that is not there has the breadcrumb and navigation' => sub {
	is_deeply(names(crumbs('/view/nosuchtable')), ["\x{2190} Home", 'nosuchtable'],
		'a missing table is named');
	$t->status_is(404)->content_like(qr/There is no table called/)
		->content_unlike(qr/\Q$data_dir\E/, 'and the data directory is not given away');
	is_deeply(names(crumbs('/no/such/page')), ["\x{2190} Home", 'Page not found'],
		'an unknown address');
	$t->status_is(404)->content_like(qr{href="/browse"}, 'with the site navigation');
	$t->get_ok('/api/analyses/nosuch')->status_is(404)->content_type_like(qr/json/,
		'an API 404 is still JSON');
};

subtest 'a back link to another site or scheme is not followed' => sub {
	for my $back ('javascript:alert(1)', 'http://evil.example/view/sales', '//evil.example/x') {
		my $c = crumbs('/bar?l=table:sales&cat=region&back=' . url_escape($back));
		is_deeply(names($c), ["\x{2190} Home", 'sales', 'Bar chart: Count by region'],
			"back=$back falls back to the chart's own table");
		ok(!(grep { ($_->[1] // '') =~ /evil|javascript/ } @$c), 'and is not linked');
	}
};

subtest 'markup in a parameter is not repeated in the trail' => sub {
	my $c = crumbs('/folder?l=table:sales&col=' . url_escape('"><img src=x onerror=alert(1)>'));
	is($c->[-1][0], 'Folder view', 'the page is named generally');
	$t->content_unlike(qr/onerror=alert/, 'the payload is nowhere on the page');
};

subtest 'a long chain of back links is cut short' => sub {
	my $url = $bar;
	$url = $bar . '&back=' . url_escape($url) for 1 .. 20;
	my $c = crumbs($url);
	cmp_ok(scalar @$c, '<=', 9, 'no more than eight steps below Home');
	is($c->[-1][0], 'Bar chart: amount by region', 'the current page is still last');
};

done_testing();
