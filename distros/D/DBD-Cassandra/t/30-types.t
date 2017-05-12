use 5.010;
use warnings;
use strict;
use DBI;
use Test::More;
use utf8;
use Ref::Util qw/is_ref/;

my $input= "__as__input";
my $warn= "__warn";

my $type_table= [
    # Type name, test input, test output (undef for error, $input for copying the input, $warn if we expect a perl warning)
    ['ascii',       'asd',  $input],
    ['ascii',       '∫∫',   undef],
    ['bigint',      5,      $input],
    ['bigint',      'asd',  $warn],
    ['blob',        'asd',  $input],
    ['boolean',     1,      !!1],
    ['boolean',     0,      !1],
    ['boolean',     2,      !!1],
    ['boolean',     'asd',  !!1],
    ['double',      0.15,   $input],
    ['float',       0.2,    0.200000002980232], # Yeah.
    ['int',         5,      $input],
    ['text',        '∫∫',   $input],
    ['timestamp',   time(), $input],
    ['varchar',     '∫∫',   $input],
    ['uuid',        '34945442-c1d4-47db-bddd-5d2138b42cbc', $input],
    ['uuid',        '34945442-c1d4-47db-bddd-5d2138b42cbc-abcdef', '34945442-c1d4-47db-bddd-5d2138b42cbc'],
    ['uuid',        'bad16', 'bad16000-0000-0000-0000-000000000000'],
    ['timeuuid',    '34945442-c1d4-47db-bddd-5d2138b42cbc', undef], # that's not a valid timeuuid
    ['timeuuid',    '568ef050-5aca-11e5-9c6b-eb15c19b7bc8', $input],
    ['timeuuid',    'bad16', undef],
    ['tinyint',     127,    $input],
    ['tinyint',     0,      $input],
    ['tinyint',     -128,   $input],
    ['tinyint',     -129,   $warn],
    ['smallint',    32767,  $input],
    ['smallint',    0,      $input],
    ['smallint',    -32768, $input],
    ['smallint',    -32769, 32767],
    ['time',        '12:00',      '12:00:00'],
    ['time',        '24:00',      '0:00:00'],
    ['time',        '13:30:54.234', $input],
    ['time',        '14',         '14:00:00'], # Why would someone want that?

    # List types...
    ['list<int>', [1, 2], $input],
    ['list<text>', ['∫∫', 'test string'], $input],
    ['set<text>', ['test string', '∫∫'], $input],
    ['frozen<set<text>>', ['test string', '∫∫'], $input],
    ['map<varchar,int>', {test => 5, asd => 1}, $input],
    ['map<varchar,frozen<list<int>>>', { test => [1, 3, 5], foo => [2, 4, 6] }, $input],
    ['list<frozen<map<int,boolean>>>', [ { 1 => !!0, 2 => !0 }, { 3 => !0, 4 => !!0 } ], $input],
    ['set<frozen<map<int,boolean>>>', [ { 1 => !!0, 2 => !0 }, { 3 => !0, 4 => !!0 } ], $input],
    ['map<int,frozen<list<int>>>', { 1 => [2, 3], 4 => [5, 6] }, $input],

    # Date is probably our only non-trivial implementation. Test it a bit harder.
    ['date',        '2000-01-01', $input],
    ['date',        '2000-01-02', $input],
    ['date',        '2000-02-28', $input],
    ['date',        '2000-02-29', $input],
    ['date',        '2000-03-01', $input],
    ['date',        '2001-01-01', $input],
    ['date',        '2101-01-01', $input],
    ['date',        '2401-01-01', $input],
    ['date',        '2400-01-01', $input],
    ['date',        '2800-01-01', $input],
    ['date',        '1600-01-01', $input],
    ['date',        '2100-01-01', $input],
    ['date',        '2200-01-01', $input],
    ['date',        '2300-01-01', $input],
    ['date',        '1900-01-01', $input],
    ['date',        '1800-01-01', $input],
    ['date',        '2016-01-01', $input],
    ['date',        '2016-02-29', $input],
    ['date',        '2016-03-01', $input],
    ['date',        '1970-01-01', $input],
    ['date',        '1969-12-31', $input],
    ['date',        '100000-12-31', $input],
    ['date',        '1970-01-11', $input],
    ['date',        '0001-01-01', '1-01-01'],
    ['date',        '0000-01-01', '0-01-01'],
    ['date',        '-0001-01-01', '-1-01-01'],
    ['date',        '275760-09-13', $input],
    ['date',        '2015-02-29', '2015-03-01'],
    ['date',        '2015-12-32', '2016-01-01'],
    ['date',        '5881580-07-11', $input],
    ['date',        '-5877641-06-23', $input],
];

unless ($ENV{CASSANDRA_HOST}) {
    plan skip_all => "CASSANDRA_HOST not set";
}

plan tests => 2+@$type_table;

my $tls= $ENV{CASSANDRA_TLS} // '';
my $dbh= DBI->connect("dbi:Cassandra:host=$ENV{CASSANDRA_HOST};keyspace=dbd_cassandra_tests;tls=$tls", $ENV{CASSANDRA_USER}, $ENV{CASSANDRA_AUTH}, {RaiseError => 1});
ok($dbh);

my $i= 0;
for my $type (@$type_table) {
    my ($typename, $test_val, $output_val)= @$type;
    my $tablename= $typename; $tablename =~ s/\W/_/g;
    $dbh->do("create table if not exists test_type_$tablename (id bigint primary key, test $typename)");
    my $random_id= ++$i;
    eval {
        my $did_warn;
        local $SIG{__WARN__}= sub {
            my $warn= shift;
            $did_warn= $warn || 1;
        };

        $dbh->do("insert into test_type_$tablename (id, test) values (?, ?)", undef, $random_id, $test_val);
        my $row= $dbh->selectrow_arrayref("select test from test_type_$tablename where id=$random_id", { async => 1 });
        if (!defined $output_val) {
            ok(0);
        } elsif (!is_ref($output_val) && $output_val eq $warn) {
            ok($did_warn);
        } elsif (!is_ref($output_val) && $output_val eq $input) {
            is_deeply([$row->[0]], [$test_val], "input match $typename");
        } else {
            is_deeply([$row->[0]], [$output_val], "perfect match $typename");
        }
        if ($did_warn && !is_ref($output_val) && $output_val ne $warn) {
            diag("Warning: $did_warn");
        }
        1;
    } or do {
        if (!defined $output_val) {
            ok(1, "$typename raise error");
        } else {
            warn $@;
            ok(0, "$typename raised error");
        }
    };
}

# Counter needs special testing
COUNTER: {
    $dbh->do("create table if not exists test_type_counter (id bigint primary key, test counter)");
    my $random_id= sprintf '%.f', rand(10000);
    eval {
        $dbh->do("update test_type_counter set test=test+5 where id=?", undef, $random_id);
        my $row= $dbh->selectrow_arrayref("select test from test_type_counter where id=$random_id");
        ok($row->[0] == 5);
        1;
    } or do {
        ok(0);
    };
}

$dbh->disconnect;
