#!perl
use strict;

BEGIN
{
    require Test::More;
    if (! eval { require DBD::SQLite }) {
        Test::More->import(skipall => 'DBD::SQLite not available');
    } else {
        Test::More->import(tests => 6);
    }
}

package MyDATA;
use strict;
use base qw(Class::DBI);
use Class::DBI::Plugin::Senna
    index_filename => 't/test_index',
    index_column   => 'data'
;
__PACKAGE__->set_db(Main => 'dbi:SQLite:dbname=t/test.db', undef, undef, { AutoCommit => 1});
__PACKAGE__->table('MyDATA');
__PACKAGE__->columns(All => qw(id data));

1;

package main;
use strict;

MyDATA->db_Main->do(qq{
    CREATE TABLE MyDATA (
        id PRIMARY KEY,
        data TEXT
    );
});

my $id = 'a';
while (<DATA>) {
    chomp;
    MyDATA->create({ id => $id++, data => $_ });
}

my $iter = MyDATA->fulltext_search("しまった");
isa_ok($iter, 'Class::DBI::Plugin::Senna::Iterator');
is($iter->count, 2);
while (my $e = $iter->next) {
    ok($e);
}

my $obj = MyDATA->retrieve('b');
$obj->data("いづれの御時にか、女御、更衣あまたさぶらひたまひけるなかに、いとやむごとなき際にはあらぬが、すぐれて時めきたまふありけり。");
$obj->update;

my($rs) = MyDATA->fulltext_search("すぐれて時めきたまふありけり");
is($rs && $rs->id, 'b');

if ($rs) {
    $rs->delete;
    ($rs) = MyDATA->fulltext_search("すぐれて時めきたまふありけり");
    ok(!$rs);
} else {
    ok(0);
}

END {
    eval {MyDATA->senna_index->remove};
    eval {unlink("t/test.db")};
}
__DATA__
祇園精舎の鐘の声、諸行無常の響きあり。娑羅双樹の花の色、盛者必衰の理をあらわす。おごれる人も久しからず、唯春の夜の夢のごとし。たけき者も遂にはほろびぬ、偏に風の前の塵に同じ。
秦の趙高（ちょうこう）、漢の王莽（おうもう）、梁の周伊（しゅい）、唐の禄山（ろくさん−安禄山）らも旧主先皇の政治に従わず、楽しみをきわめ諫言も聞かず、天下の乱れも知らず、民衆の憂いも顧みないので亡びてしまった。
我が国でも、承平の平将門、天慶の藤原純友（すみとも）、康和の源義親（よしちか）、平治の藤原信頼（のぶより）、これらもまもなく亡びてしまった。
最近では、六波羅の入道前太政大臣平朝臣清盛公という人の有様を聞くと、言葉にできないほどだ。
その先祖は桓武天皇の第五の皇子。一品式部卿葛原（かずらはら）親王の九代の子孫にあたる讃岐守正盛（さぬきのかみまさもり）の子孫であり、刑部卿忠盛（ただもり）朝臣の嫡男である。かの親王の子、高視王（たかみおう）は無官無位でした。その子高望王（たかもちおう）のとき初めて平の姓を賜って上総介になりましたが、すぐ皇族をはなれて人臣に連なった。その子の鎮守府将軍良望（よしもち。後に国香（くにか）と名を改めた。）から正盛までの六代の間は、諸国の受領であったが、宮中に昇殿を許されなかった。
