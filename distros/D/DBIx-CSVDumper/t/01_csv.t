use strict;
use warnings;
use utf8;
use Test::More;

use File::Temp qw/tempdir tempfile/;
use DBIx::CSVDumper;
use Test::Requires qw/DBD::SQLite DBI/;

my $dir = tempdir(CLEANUP => 1);
my (undef, $db) = tempfile(DIR => $dir, SUFFIX => '.db');

my $dbh = DBI->connect(
    "dbi:SQLite:dbname=$db" , '', '', {
         sqlite_unicode => 1,
     },
);

$dbh->do('CREATE TABLE item (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(255) NOT NULL
);');

my @datas = (
    [1  => 'hoge'],
    [2  => 'fuga'],
    [3  => '日本語'],
);

for my $data (@datas) {
    $dbh->do('
        INSERT INTO item (id, name) VALUES (?, ?);
    ', undef, $data->[0], $data->[1]);
}


my $dumper = DBIx::CSVDumper->new(
    csv_args => {
        eol => "\n",
    },
);
my (undef, $file) = tempfile(DIR => $dir, SUFFIX => '.csv');
my $sth = $dbh->prepare('SELECT * FROM item');
$sth->execute;
$dumper->dump(
    sth     => $sth,
    file    => $file,
);
my $content = do {local $/; open my $fh, '<:utf8', $file;<$fh>};
is $content, qq{"id","name"
"1","hoge"
"2","fuga"
"3","日本語"
};

done_testing;
