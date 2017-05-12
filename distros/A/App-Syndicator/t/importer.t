use strict;
use warnings;
use Test::More qw/no_plan/;
use Data::Dumper;
BEGIN { use_ok('App::Syndicator::DB') };

my $db = App::Syndicator::DB->new(
    dsn => "DBI:SQLite:dbname=:memory:",
    sources => [ "http://blogs.perl.org/atom.xml" ],
);

ok $db, 'created db';

my $r = $db->fetch;

ok $r, "fetched $r entries";
