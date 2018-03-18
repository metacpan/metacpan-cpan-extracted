use Dwarf::Pragma;
use Data::Dumper;
use Test::More 0.88;
use Test::PostgreSQL;
use App;
use Dwarf::Util qw/read_file/;

my $pgsql = Test::PostgreSQL->new()
	or plan skip_all => $Test::PostgreSQL::errstr;

my $c = App->new;

# DB の接続先を Test::PostgreSQL に上書き
$c->conf(db => {
	master => {
		dsn => $pgsql->dsn,
	}
});

# Teng 再読み込み
$c->load_plugin('Teng');

do {
	my $txn = $c->db->txn_scope;
	$c->db->do(read_file($c->base_dir . "/sql/01_sessions.sql"));
	my $itr = $c->db->search_by_sql('select count(*) from sessions');
	ok $itr->next->count >= 0, '(select count(*) from sessions) >= 0';
	$txn->commit;
};

done_testing();

