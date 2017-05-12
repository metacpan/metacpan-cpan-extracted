use strict;
use warnings;
use Test::More tests => 6;
BEGIN {
    use_ok('AnyMongo');
    use_ok('AnyMongo::Database');
    use_ok('AnyMongo::Connection');
    use_ok('AnyMongo::Collection');
    use_ok('AnyMongo::Cursor');
    use_ok('AnyMongo::MongoSupport');
}


