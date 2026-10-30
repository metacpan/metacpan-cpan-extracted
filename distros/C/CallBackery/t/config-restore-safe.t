use FindBin;

use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';
use lib $FindBin::Bin.'/lib';

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use CallBackeryTest qw(setupTestConfig);
use File::Temp qw(tempdir);
use DBI;

setupTestConfig();

my $t = Test::Mojo->new('CallBackery');
my $cfg = $t->app->config;
my $db  = $t->app->database;

require Archive::Zip;
my $dir = tempdir(CLEANUP => 1);
sub main::probe { open my $fh, '>', "$dir/tokenizer"; return sub {} }

my $blob = sub {
    my ($name,$content) = @_;
    my $zip = Archive::Zip->new;
    $zip->addString($content,$name);
    open my $fh, '>', \my $zipData;
    $zip->writeToFileHandle($fh,0);
    close $fh;
    return $cfg->getCrypt('secret')->encrypt($cfg->pack16($zipData));
};

my $perlFts = q{CREATE VIRTUAL TABLE v USING fts4(tokenize=perl 'main::probe')};
for my $sql (".shell touch $dir/shell\n",
        "ATTACH DATABASE '$dir/attach' AS a;\nCREATE TABLE a.t (x);\n",
        "CREATE TABLE f AS SELECT data FROM fsdir('$FindBin::Bin/callbackery.cfg');\n",
        "PRAGMA schema_version=1;\n",
        "$perlFts;\nINSERT INTO v VALUES ('x');\n",
        "PRAGMA writable_schema=ON;\nINSERT INTO sqlite_schema(type,name,tbl_name,rootpage,sql) VALUES('table','v','v',0,'"
            .($perlFts =~ s/'/''/gr)."');\nPRAGMA writable_schema=OFF;\nINSERT INTO v VALUES ('x');\n") {
    ok !eval { $cfg->restoreConfigBlob($blob->('{DATABASEDUMP}',"CREATE TABLE probe (x);\n$sql"),'secret'); 1 },
        "a dump with '".($sql =~ s/\n.*//sr)."' is refused";
}
is_deeply [glob "$dir/*"], [], 'and it ran no command and created no file';

# a full text index, as sqlite3 .dump writes it, still restores
$db->mojoSqlDb->query('CREATE VIRTUAL TABLE ftsprobe USING fts4(body)');
$db->mojoSqlDb->query(q{INSERT INTO ftsprobe VALUES ('hello world')});
my $backup = $cfg->getConfigBlob('secret');
$db->mojoSqlDb->query('DROP TABLE ftsprobe');
ok eval { $cfg->restoreConfigBlob($backup,'secret'); 1 }, 'a backup with a full text table restores' or diag $@;
is $db->mojoSqlDb->query(q{SELECT count(*) AS n FROM ftsprobe WHERE ftsprobe MATCH 'world'})->hash->{n}, 1,
    'and the full text search works';

my $rawDb = sub {
    my $sql = shift;
    my $raw = tempdir(CLEANUP => 1).'/raw.db';
    my $dbh = DBI->connect("dbi:SQLite:dbname=$raw",'','',{RaiseError => 1});
    $dbh->do('CREATE TABLE plain (x)');
    if ($sql) {
        $dbh->do('PRAGMA writable_schema=ON');
        $dbh->do(q{INSERT INTO sqlite_master(type,name,tbl_name,rootpage,sql) VALUES('table','v','v',0,?)},undef,$sql);
    }
    $dbh->disconnect;
    my $zip = Archive::Zip->new;
    $zip->addFile({filename => $raw, zipName => '{DATABASE}'});
    open my $fh, '>', \my $zipData;
    $zip->writeToFileHandle($fh,0);
    close $fh;
    return $cfg->getCrypt('secret')->encrypt($cfg->pack16($zipData));
};
ok !eval { $cfg->restoreConfigBlob($rawDb->($perlFts),'secret'); 1 },
    'a database file with a Perl tokenizer table is refused';
like "$@", qr/Perl tokenizer/, 'with an error that says why';
ok eval { $cfg->restoreConfigBlob($rawDb->(),'secret'); 1 },
    'a plain database file restores' or diag $@;

done_testing();
