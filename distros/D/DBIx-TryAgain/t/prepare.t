#!perl

use Test::More;
use DBIx::TryAgain;

use DBD::SQLite;
use File::Temp;
use Data::Dumper;

use strict;

my $dbfile = File::Temp->new(UNLINK => 0);
unlink $dbfile;

my $dbh = DBIx::TryAgain->connect("dbi:SQLite:dbname=$dbfile","","", { PrintError => 0 } );
ok $dbh, "Connected to database" or do {
    diag "connect error ".$DBI::errstr;
    exit;
};

$dbh->try_again_max_retries(3);
$dbh->try_again_on_messages([ qr[no such table.*] ]);
$dbh->try_again_on_prepare(1);

ok $dbh->try_again_on_prepare, "set dbh attribute";

my $sth = $dbh->prepare("select * from thistabledoesnotexist");
ok !$sth, "Prepare failed";
is $dbh->{private_dbix_try_again_tries}, 3, "Tried 3 times";
is_deeply $dbh->{private_dbix_try_again_slept}, [1,1,2], "slept with fibonacci delay";

$sth = $dbh->prepare("select * from thistabledoesnotexist");
ok !$sth, "Prepare failed again";
is $dbh->{private_dbix_try_again_tries}, 3, "Tried 3 times";
is_deeply $dbh->{private_dbix_try_again_slept}, [1,1,2], "slept with fibonacci delay";

unlink $dbfile;
done_testing();

