#!perl -T

use strict;
use warnings;

use Test::More tests => 12 + 1;
use Test::NoWarnings;

BEGIN {
    require_ok('DBI');
}

my $dbh = DBI->connect(
    "dbi:PO:",
    undef,
    undef,
    {
        RaiseError => 1,
        PrintError => 0,
        AutoCommit => 1,
    },
);
isa_ok($dbh, 'DBI::db', 'connect');

my @test_data = (
    '[_1] [_11]'                            => '%1 %11',
    '[ _2 ] [ _22 ]'                        => '%2 %22',
    '[*,_1,one,more,nothing]'               => '%*(%1,one,more,nothing)',
    '[ * , _2 , one , more , nothing ]'     => '%*(%2 , one , more , nothing )',
    '[quant,_1,one,more,nothing]'           => '%quant(%1,one,more,nothing)',
    '[ quant , _2 , one , more , nothing ]' => '%quant(%2 , one , more , nothing )',
    '[#,_1]'                                => '%#(%1)',
    '[ # , _2 ]'                            => '%#(%2 )',
    '[numf,_1]'                             => '%numf(%1)',
    '[ numf , _2 ]'                         => '%numf(%2 )',
);

while (my ($key, $value) = splice @test_data, 0, 2) {
    is(
        $dbh->func(
            $key,
            'maketext_to_gettext',
        ),
        $value,
        'maketext_to_gettext',
    );
}