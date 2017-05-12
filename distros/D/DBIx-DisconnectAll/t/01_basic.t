use strict;
use warnings;
use Test::More;
use DBI;
use DBIx::DisconnectAll;
use Test::Requires 'DBD::SQLite';

my $dbh = DBI->connect('dbi:SQLite::memory:', '', '',{ RaiseError=>1 });
ok($dbh);
ok($dbh->{Active});

my $dbh2 = DBI->connect('dbi:SQLite::memory:', '', '',{ RaiseError=>1 });
ok($dbh2);
ok($dbh2->{Active});

my %avail = map { $_ => 1 } DBI->available_drivers;
my @dbh;
if ( $ENV{MYSQL_TESTUSER} && $ENV{MYSQL_TESTPASSWORD} &&  $avail{mysql} ) {
    note("use DBD::mysql");
    my $dbh3 = DBI->connect('dbi:mysql:;', $ENV{MYSQL_TESTUSER}, $ENV{MYSQL_TESTPASSWORD},{ RaiseError=>1 });
    ok($dbh3);
    ok($dbh3->{Active});
    push @dbh, $dbh3;
}
if ( $avail{Sponge} ) {
    DBI->install_driver('Sponge');
}

dbi_disconnect_all();

ok($dbh);
ok(!$dbh->{Active});
ok($dbh2);
ok(!$dbh2->{Active});

for my $dbh3 ( @dbh ) {
    ok($dbh3);
    ok(!$dbh3->{Active}); 
}

done_testing();

