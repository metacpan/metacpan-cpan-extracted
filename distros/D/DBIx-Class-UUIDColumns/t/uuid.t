#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use DBIC::Test tests => 14;
};

my $schema = DBIC::Test->init_schema;
my $row;

$row = $schema->resultset('Test')->create({ });
ok DBIC::Test::is_uuid( $row->id ), 'got something that looks like a UUID from Auto';

DBIC::Test::Schema::Test->uuid_class('CustomUUIDMaker');
Class::C3->reinitialize();
$row = $schema->resultset('Test')->create({ });
ok DBIC::Test::is_uuid( $row->id ), 'got something that looks like a UUID from CustomUUIDMaker';

is(DBIx::Class::UUIDColumns::UUIDMaker->as_string, undef);

SKIP: {
    skip 'Data::UUID not installed', 2 unless eval 'require Data::UUID';

    DBIC::Test::Schema::Test->uuid_class('::Data::UUID');
    Class::C3->reinitialize();
    is(DBIC::Test::Schema::Test->uuid_class, 'DBIx::Class::UUIDColumns::UUIDMaker::Data::UUID');
    $row = $schema->resultset('Test')->create({ });
    ok DBIC::Test::is_uuid( $row->id ), 'got something that looks like a UUID from Data::UUID';
};

SKIP: {
    skip 'Data::GUID not installed', 1 unless eval 'require Data::GUID';

    DBIC::Test::Schema::Test->uuid_class('::Data::GUID');
    Class::C3->reinitialize();
    $row = $schema->resultset('Test')->create({ });
    ok DBIC::Test::is_uuid( $row->id ), 'got something that looks like a UUID from Data::GUID';
};

SKIP: {
    skip 'APR::UUID not installed', 1 unless eval 'require APR::UUID and $^O ne \'openbsd\'';

    DBIC::Test::Schema::Test->uuid_class('::APR::UUID');
    Class::C3->reinitialize();
    $row = $schema->resultset('Test')->create({ });
    ok DBIC::Test::is_uuid( $row->id ), 'got something that looks like a UUID from APR::UUID';
};

SKIP: {
    skip 'UUID not installed', 1 unless eval 'require UUID';

    DBIC::Test::Schema::Test->uuid_class('::UUID');
    Class::C3->reinitialize();
    $row = $schema->resultset('Test')->create({ });
    ok DBIC::Test::is_uuid( $row->id ), 'got something that looks like a UUID from UUID';
};

SKIP: {
    skip 'Win32::Guidgen not installed', 1 unless eval 'require Win32::Guidgen';

    DBIC::Test::Schema::Test->uuid_class('::Win32::Guidgen');
    Class::C3->reinitialize();
    $row = $schema->resultset('Test')->create({ });
    ok DBIC::Test::is_uuid( $row->id ), 'got something that looks like a UUID from Win32::Guidgen';
};

SKIP: {
    skip 'Win32API::GUID not installed', 1 unless eval 'require Win32API::GUID';

    DBIC::Test::Schema::Test->uuid_class('::Win32API::GUID');
    Class::C3->reinitialize();
    $row = $schema->resultset('Test')->create({ });
    ok DBIC::Test::is_uuid( $row->id ), 'got something that looks like a UUID from Win32API::GUID';
};

SKIP: {
    skip 'Data::Uniqid not installed', 1 unless eval 'require Data::Uniqid';

    DBIC::Test::Schema::Test->uuid_class('::Data::Uniqid');
    Class::C3->reinitialize();
    $row = $schema->resultset('Test')->create({ });
    ok $row->id, 'got something from Data::Uniqid';
};

SKIP: {
    skip 'UUID::Random not installed', 1 unless eval 'require UUID::Random';

    DBIC::Test::Schema::Test->uuid_class('::UUID::Random');
    Class::C3->reinitialize();
    $row = $schema->resultset('Test')->create({ });
    ok $row->id, 'got something from UUID::Random';
};

eval {
    DBIC::Test::Schema::Test->uuid_class('::JunkIDMaker');
};
if ($@ && $@ =~ /could not be loaded/i) {
    pass;
} else {
    fail('uuid_class dies when class can not be loaded');
};

eval {
    DBIC::Test::Schema::Test->uuid_class('BadUUIDMaker');
};
if ($@ && $@ =~ /is not a UUIDMaker subclass/i) {
    pass;
} else {
    fail('uuid_class dies when class no isa DBIx::Class::UUIDColumns::UUIDMaker');
};

1;
