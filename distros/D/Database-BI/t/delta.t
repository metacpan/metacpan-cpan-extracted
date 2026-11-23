use strict;
use warnings;
use Test::Most;
use Test::Mojo;
use File::Temp qw(tempdir);
use Mojo::File qw(path);
use Mojo::Util qw(url_escape);

# Delta: f=<a>:differ:<b> keeps the rows where the two columns hold identical
# text and removes every other row.

my $data = tempdir(CLEANUP => 1);
path($data, 'p.csv')->spurt(join '', map {"$_\n"}
	'id,billed,paid,note',
	'1,10,10,a',
	'2,10,12,b',
	'3,Ann,Ann,c',
	'4,Ann,ann,d',
	'5,,,e',
	'6,x,,f');

my $t = Test::Mojo->new('Database::BI');
$t->app->config->{data_dir}  = $data;
$t->app->config->{model_dir} = tempdir(CLEANUP => 1);
my $l = 'l=' . url_escape("path:$data/p.csv");

# The rows that stay, read as JSON (ids in order).
sub ids {
	my ($qs) = @_;
	my $tx = $t->ua->get("/export?$l&format=json&$qs");
	return join ',', map { $_->{id} } @{ $tx->res->json || [] };
}

is(ids('f=billed:differ:paid'), '2,4,6', 'only rows where the two columns differ stay');
is(ids('f=paid:differ:billed'), '2,4,6', 'the order of the two columns does not matter');
is(ids('f=billed:differ:billed'), '', 'a column never differs from itself');
is(ids('f=billed:differ:paid&f=id:gt:2'), '4,6', 'it combines with other filters');

# Identical means identical: case counts, and so do spaces.
ok(ids('f=billed:differ:paid') =~ /4/, 'Ann and ann differ, so row 4 stays');
ok(ids('f=billed:differ:paid') !~ /5/, 'two empty cells are identical, so row 5 goes');

# Both columns must exist.
$t->get_ok("/export?$l&format=json&f=billed:differ:nosuch")->status_is(400)
  ->content_like(qr/nosuch/, 'an unknown second column is refused, and named');
$t->get_ok("/export?$l&format=json&f=nosuch:differ:paid")->status_is(400);

# The table page shows it as a filter chip and keeps only matching rows.
$t->get_ok("/open?path=" . url_escape("$data/p.csv") . '&f=billed:differ:paid')->status_is(200)
  ->content_like(qr/data-spec="billed:differ:paid"/, 'shown as a filter chip')
  ->content_like(qr/<td[^>]*>b<\/td>/, 'a row that differs is shown')
  ->content_unlike(qr/<td[^>]*>e<\/td>/, 'a row that matches is not');

# The button sits to the right of Combine data and has its panel.
my $page = $t->get_ok("/open?path=" . url_escape("$data/p.csv"))->tx->res->body;
like($page, qr/id="btn-combine".*?id="btn-delta"/s, 'Delta follows Combine data');
like($page, qr/id="delta-panel"/, 'and has a panel');
like($page, qr/'delta-panel'/, 'listed in BI_PANELS');
like($page, qr/class="join-fields delta-fields"/, 'its two menus are a plain row, not the three-column merge grid');
like($page, qr/function sameWidth\(\)/, 'and are given one width, that of the longest column name');

# A SQL-backed source: the filter is never pushed to SQL, and locked rows are only read.
SKIP: {
	eval { require DBI; require DBD::SQLite; 1 } or skip 'DBD::SQLite not installed', 2;
	my $db  = tempdir(CLEANUP => 1);
	my $dbh = DBI->connect("dbi:SQLite:dbname=$db/pay.sql", '', '', { RaiseError => 1 });
	$dbh->do('CREATE TABLE pay (id INTEGER PRIMARY KEY, billed TEXT, paid TEXT)');
	$dbh->do(q{INSERT INTO pay VALUES (1,'10','10'),(2,'10','12'),(3,'7','7')});
	$dbh->disconnect;
	my $q = 'l=' . url_escape("path:$db/pay.sql");
	$t->get_ok("/export?$q&format=json&f=billed:differ:paid")->status_is(200);
	is(join(',', map { $_->{id} } @{ $t->tx->res->json }), '2', 'SQLite rows too');
}

# The rows per page the reader chose survive Merge and Combine, whose forms
# rebuild the link from hidden fields (per_page was lost: back to 200).
my $sized = $t->get_ok('/open?path=' . url_escape("$data/p.csv") . '&per_page=25')->tx->res->body;
for my $form (qw(join-form combine-form)) {
	my ($html) = $sized =~ m{(<form id="$form".*?</form>)}s;
	like($html // '', qr/<input type="hidden" name="per_page" value="25">/, "$form carries per_page=25");
}
my $plain = $t->get_ok('/open?path=' . url_escape("$data/p.csv"))->tx->res->body;
my ($pj) = $plain =~ m{(<form id="join-form".*?</form>)}s;
unlike($pj // '', qr/name="per_page"/, 'and adds nothing when the size was not chosen');

done_testing;
