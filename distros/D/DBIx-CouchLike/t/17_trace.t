# -*- mode:perl -*-
use strict;
use Test::More;

use Test::Requires qw/ DBD::SQLite IO::Scalar /;
BEGIN {
    use_ok 'DBIx::CouchLike';
}

my $dbh = require 't/connect.pl';
ok $dbh;

my $couch = DBIx::CouchLike->new({ dbh => $dbh, table => "foo" });
isa_ok $couch => "DBIx::CouchLike";
$couch->create_table;

{
    my $trace;
    $couch->trace( IO::Scalar->new(\$trace) );
    $couch->get("abcdefg");
    like $trace, qr/SELECT.+FROM\s+foo_data/;
    like $trace, qr/'abcdefg'/;
}


$dbh->commit unless $ENV{DSN};
$dbh->disconnect;
done_testing;
