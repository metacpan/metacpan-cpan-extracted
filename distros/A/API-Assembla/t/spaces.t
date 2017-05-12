use Test::More;
use strict;

if(!$ENV{'TEST_ASSEMBLA_PASS'}) {
    plan skip_all => 'This test is useless unless you are the author';
}

use API::Assembla;

my $api = API::Assembla->new(
    username => 'iirobot',
    password => $ENV{'TEST_ASSEMBLA_PASS'}
);

my $data = $api->get_spaces;
cmp_ok(scalar(keys($data)), '==', 2, '2 spaces');
ok(exists($data->{PRG}), 'PRG space');

{
    my $space = $data->{PRG};
    cmp_ok($space->name, 'eq', 'PRG', 'space name');
    cmp_ok($space->id, 'eq', 'dhHT8ENtKr4k_1eJe4gwI3', 'space id');
    cmp_ok($space->created_at->ymd, 'eq', '2011-06-22', 'space created_at');
}

{
    my $space = $api->get_space('dhHT8ENtKr4k_1eJe4gwI3');
    cmp_ok($space->name, 'eq', 'PRG', 'space name');
    cmp_ok($space->id, 'eq', 'dhHT8ENtKr4k_1eJe4gwI3', 'space id');
    cmp_ok($space->created_at->ymd, 'eq', '2011-06-22', 'space created_at');
}

done_testing;