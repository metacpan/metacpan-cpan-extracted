use strict;
use warnings;
use Test::More;
use Class::MOP;
use DBIx::ObjectMapper::Engine::DBI;
use DateTime::Format::SQLite;

my $CHECK_BIT = 1;
eval "require Bit::Vector";
$CHECK_BIT = 0 if $@;

sub build_pkg($) {
    my $t = shift;
    my $pkg = 'DBIx::ObjectMapper::Metadata::Table::Column::Type::' . $t;
    Class::MOP::load_class($pkg);
    return $pkg;
}

{
    my $type = 'Undef';
    my $pkg = build_pkg $type;
    my $obj = $pkg->new;
    is $obj->type, lc($type);
    ok $obj->from_storage('val');
    ok $obj->to_storage('val');
};

{
    my $type = 'String';
    my $pkg = build_pkg $type;
    my $obj = $pkg->new( 10, 'utf8' );
    is $obj->type, lc($type);
    ok $obj->utf8;
    is $obj->size, 10;
    ok $obj->from_storage('val');
    ok $obj->to_storage('val');
};

{
    my $type = 'Text';
    my $pkg = build_pkg $type;
    my $obj = $pkg->new('utf8');
    is $obj->type, lc($type);
    ok $obj->utf8;
    ok $obj->from_storage('val');
    ok $obj->to_storage('val');
};

{
    my $type = 'Int';
    my $pkg = build_pkg $type;
    my $obj = $pkg->new;
    is $obj->type, lc($type);
    ok $obj->from_storage(1);
    ok $obj->to_storage(2);
};

{
    my $type = 'SmallInt';
    my $pkg = build_pkg $type;
    my $obj = $pkg->new;
    is $obj->type, lc($type);
    ok $obj->from_storage(1);
    ok $obj->to_storage(2);
};

{
    my $type = 'BigInt';
    my $pkg = build_pkg $type;
    my $obj = $pkg->new;
    is $obj->type, lc($type);
    ok $obj->from_storage(1);
    ok $obj->to_storage(2);
};

{
    my $type = 'Numeric';
    my $pkg = build_pkg $type;
    my $obj = $pkg->new( 5, 3 );
    is $obj->type, lc($type);
    is $obj->size, '5,3';
    is $obj->{precision}, 5;
    is $obj->{scale}, 3;
    is $obj->from_storage(1.018), 1.018;
    is $obj->to_storage(2.008), 2.008;
};

{
    my $type = 'Float';
    my $pkg = build_pkg $type;
    my $obj = $pkg->new;
    is $obj->type, lc($type);
    is $obj->from_storage(1.018), 1.018;
    is $obj->to_storage(2.008), 2.008;
};

{
    my $type = 'Datetime';
    my $pkg = build_pkg $type;
    my $obj = $pkg->new( realtype => 'datetime' );
    is $obj->type, lc($type);
    is $obj->default_type, 'datetime';
    $obj->{datetime_parser} = 'DateTime::Format::SQLite';
    my $from_dt = $obj->from_storage('2010-01-01 18:00:09');
    is $from_dt->year, 2010;
    is $from_dt->month, 1;
    is $from_dt->day, 1;
    is $from_dt->hour, 18;
    is $from_dt->minute, 0;
    is $from_dt->second, 9;
    is $obj->to_storage($from_dt), '2010-01-01 18:00:09';
};

{
    my $type = 'Date';
    my $pkg = build_pkg $type;
    my $obj = $pkg->new();
    is $obj->type, lc($type);
    is $obj->default_type, 'date';
    $obj->{datetime_parser} = 'DateTime::Format::SQLite';
    my $from_dt = $obj->from_storage('2010-01-03');
    is $from_dt->year, 2010;
    is $from_dt->month, 1;
    is $from_dt->day, 3;
    is $from_dt->hour, 0;
    is $from_dt->minute, 0;
    is $from_dt->second, 0;
    is $obj->to_storage($from_dt), '2010-01-03';
};

{
    my $type = 'Time';
    my $pkg = build_pkg $type;
    my $obj = $pkg->new;
    is $obj->type, lc($type);
    is $obj->default_type, 'time';
    $obj->{datetime_parser} = 'DateTime::Format::SQLite';
    my $from_dt = $obj->from_storage('10:56:30');
    is $from_dt->hour, 10;
    is $from_dt->minute, 56;
    is $from_dt->second, 30;
    is $obj->to_storage($from_dt), '10:56:30';
};

{
    my $type = 'Boolean';
    my $pkg = build_pkg $type;
    my $obj = $pkg->new;
    is $obj->type, lc($type);
    ok $obj->from_storage(1);
    ok $obj->to_storage(1);
};

{
    my $type = 'Binary';
    my $pkg = build_pkg $type;
    my $obj = $pkg->new;
    is $obj->type, lc($type);
    my $engine = DBIx::ObjectMapper::Engine::DBI->new({ dsn => 'DBI:SQLite:' });
    $obj->set_engine_option($engine);
    ok $obj->from_storage(pack('C', 10));
    my $to_st = $obj->to_storage(pack('C', 10));

    # SQLite use normail bind
    is $to_st, pack('C', 10);

    # other db like below
    #is ref($to_st), 'SCALAR';
    #is $$to_st, "'\n'";
};

{
    my $type = 'Bit';
    my $pkg = build_pkg $type;
    my $obj = $pkg->new(6);
    is $obj->type, lc($type);
    if( $CHECK_BIT ) {
        my $bit = Bit::Vector->new_Dec(6, 32);
        is $obj->to_storage($bit), 100000;
        ok my $rbit = $obj->from_storage(32);
        ok $bit->equal($rbit);
        ok $bit->equal($obj->from_storage($bit->to_Bin)),
            'to bin:' . $bit->to_Bin;
        ok $bit->equal($obj->from_storage(32)), 'to dec: 32';
        ok $bit->equal($obj->from_storage(0x20)), 'to hex: 0x20';
        ok $bit->equal($obj->from_storage("B'100000'")), 'to bin';
    }
};

{
    my $type = 'Mush';
    my $pkg = build_pkg $type;
    my $obj = $pkg->new;
    is $obj->type, lc($type);
    my $struct = $obj->to_storage( { a => 1, b => 2, c => 3 } );
    is_deeply $obj->from_storage($struct), { a => 1, b => 2, c => 3 };
};

my ($dsn, $user, $pass) = @ENV{map { "MAPPER_TEST_PG_${_}" } qw/DSN USER PASS/};

my $pg_engine;
if( $dsn && $user ) {
    $pg_engine = DBIx::ObjectMapper::Engine::DBI->new({
        dsn => $dsn,
        username => $user,
        password => $pass,
    });
}

{ # pg only
    my $type = 'Interval';
    my $pkg = build_pkg $type;
    my $obj = $pkg->new;
    is $obj->type, lc($type);
    if( $pg_engine ) {
        $obj->set_engine_option($pg_engine);
        my $from_dt = $obj->from_storage('1 days');
        is $from_dt->days, 1;
        is $obj->to_storage($from_dt), '@ 1 days';
    }
};

{ # pg only
    my $type = 'Array';
    my $pkg = build_pkg $type;
    my $obj = $pkg->new;
    is $obj->type, lc($type);

    if( $pg_engine ) {
        $obj->set_engine_option($pg_engine);
        is_deeply $obj->from_storage([1,2,3]), [1,2,3];
        is_deeply $obj->to_storage([1,2,3]), \[1,2,3];
    }
};

{ # URI
    my $type = 'Uri';
    my $pkg = build_pkg $type;
    my $obj = $pkg->new;
    is $obj->type, lc($type);

    ok my $uri = $obj->from_storage('http://www.example.com/foo/bar?a=1&b=2');
    is $uri->host, 'www.example.com';
    is $uri->path, '/foo/bar';
    is_deeply { $uri->query_form }, { a => 1, b => 2 };
    is $obj->to_storage($uri), 'http://www.example.com/foo/bar?a=1&b=2';
};

{ # YAML
    my $type = 'Yaml';
    my $pkg = build_pkg $type;
    my $obj = $pkg->new;
    is $obj->type, lc($type);
    my $struct = { a => 1, b => 2, c => [1 ,2 ,3 ] };
    ok my $yaml = $obj->to_storage($struct);
    is_deeply $obj->from_storage($yaml), $struct;
};

done_testing;
