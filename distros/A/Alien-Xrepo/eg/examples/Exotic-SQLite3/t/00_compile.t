use v5.40;
use blib;
use Test2::V0;
use Exotic::SQLite3;
#
my $sqlite = Exotic::SQLite3->new;
isa_ok $sqlite, ['Exotic::SQLite3'],       'isa Exotic::SQLite3';
isa_ok $sqlite, ['Alien::Xrepo::Runtime'], 'isa Alien::Xrepo::Runtime';
is [ $sqlite->package_names ], ['sqlite3'], 'package_names is sqlite3';
#
done_testing;
