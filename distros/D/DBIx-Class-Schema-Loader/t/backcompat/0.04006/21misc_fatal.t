use DBIx::Class::Schema::Loader::Optional::Dependencies
    -skip_all_without => 'test_backcompat';

use strict;
use warnings;
use Test::More;
use lib qw(t/backcompat/0.04006/lib);
use make_dbictest_db;

{
    $INC{'DBIx/Class/Storage/xyzzy.pm'} = 1;
    package DBIx::Class::Storage::xyzzy;
    use base qw/ DBIx::Class::Storage /;
    sub new { bless {}, shift }
    sub connect_info { @_ }

    package DBICTest::Schema;
    use base qw/ DBIx::Class::Schema::Loader /;
    __PACKAGE__->loader_options( really_erase_my_files => 1 );
    __PACKAGE__->storage_type( '::xyzzy' );
}

plan tests => 1;

eval { DBICTest::Schema->connect($make_dbictest_db::dsn) };
like(
    $@,
    qr/Could not load loader_class "DBIx::Class::Schema::Loader::xyzzy": /,
    'Bad storage type dies correctly'
);
