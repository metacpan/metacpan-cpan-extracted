use strict;
use Test::More;

use Crypt::MySQL ();

unless (eval { require DBD::mysql } && eval { require DBI }) {
    plan skip_all => "no DBD::mysql";
}
else {
    plan tests => 1;
}

SKIP: {
    my $dbh = eval { 
        DBI->connect("dbi:mysql:test", "root", "", {
            RaiseError => 1, PrintError => 1
        });
    };
    skip "could not connect to MySQL", 1 unless $dbh;

    my $tm = time. "";
    
    my $sth = $dbh->prepare("SELECT PASSWORD(?)");
    $sth->execute($tm);
    my($real_mysql) = $sth->fetchrow_array;
    $sth->finish;
    
    my $sth2 = $dbh->prepare('SELECT VERSION()');
    $sth2->execute;
    my($verstr) = $sth2->fetchrow_array;
    $sth2->finish;
    
    $dbh->disconnect;

    my($ver) = $verstr =~ m/^([0-9]+\.[0-9]+)/;
    
    if ($ver >= 4.1) {
        is($real_mysql, Crypt::MySQL::password41($tm));
    }
    else {
        is($real_mysql, Crypt::MySQL::password($tm));  
    } 
}
