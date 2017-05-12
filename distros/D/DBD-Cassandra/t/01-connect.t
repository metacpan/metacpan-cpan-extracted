use 5.010;
use warnings;
use strict;
use Test::More;

# Fake running under 'perl -l'
$\= "\n";

unless ($ENV{CASSANDRA_HOST}) {
    plan skip_all => "CASSANDRA_HOST not set";
}

plan tests => 3;

use DBI;
my $tls= $ENV{CASSANDRA_TLS} // '';
my $dbh= DBI->connect("dbi:Cassandra:host=$ENV{CASSANDRA_HOST};tls=$tls", $ENV{CASSANDRA_USER}, $ENV{CASSANDRA_AUTH}, {RaiseError => 1});
ok($dbh);

is($dbh->ping(), 1);
$dbh->disconnect;

is($dbh->ping(), 0);
