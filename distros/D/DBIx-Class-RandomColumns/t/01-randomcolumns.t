#!perl -wT
use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
    use lib 't/lib';
    use TestDB;

    eval 'require DBD::SQLite';
    if ($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 36;
    }
};

my $schema = TestDB->init_schema;

for my $table (qw(Foo Bar)) {
    my $rs = $schema->resultset($table);
    my ($row, $random_columns);

    lives_ok {
        $row = $rs->new_result({number1 => 4711, string1 => 'foo'})
    } 'creating a row with new_result()';

    lives_ok {$random_columns = $row->random_columns } 'getting random_columns';

    isa_ok $random_columns, 'HASH', 'random_columns() returns a hash';

    is_deeply $random_columns, {
        id => {set => ['0'..'9', 'a'..'z'], size => 20, check => undef},
        number1 => {min => 0, max => 2**31-1, check => undef},
        number2 => {min => -2**31, max => 2**31-1, check => undef},
        number3 => {min => 0, max => 2**31-1, check => undef},
        number4 => {min => -5, max => 3, check => undef},
        string1 => {set => ['0'..'9', 'a'..'z'], size => 32, check => undef},
        string3 => {set => [0..9], size => 3, check => 1},
        string4 => {set => ['0'..'9', 'a'..'z'], size => 32, check => undef},
    }, 'random_columns discloses configuration';
    lives_and {
        like $row->get_random_value('string4'), qr/^[\da-z]{32}$/
    } 'get_random_value() standalone usage on string';
    lives_and {
        ok $_ >= -5 && $_ <= 3 for $row->get_random_value('number4');
    } 'get_random_value() standalone usage on integer';

    ok !defined($row->string4), 'random_columns yet not populated';

    lives_ok { $row->insert } 'inserting the row';

    lives_and {
        like $row->id, qr/^[\da-z]{20}$/
    } 'random string with full field length';
    lives_and { is $row->number1, 4711 } 'stay away from defined numbers';
    lives_and { is $row->string1, 'foo' } 'stay away from defined strings';
    lives_and { like $row->number2, qr/^-?\d+$/ } 'random integer';
    lives_and { like $row->number3, qr/^\d+$/ } 'positive random integer';
    lives_and {
        ok $row->number4 >= -5 && $row->number4 <= 3
    } 'random integer between -5 and +3';
    lives_and {
        like $row->string3, qr/^\d{3}$/
    } 'random string with custom character set and length';
    lives_and {
        like $row->string4, qr/^[\da-z]{32}$/
    } 'random string with full field length';

    lives_ok {
        $row = $rs->create({string5 => $table})
    } 'creating another row';

    lives_and {
        like $row->string1, qr/^[\da-z]{32}$/
    } 'another random string with full field length';
}
