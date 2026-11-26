use v5.44;
use Test::More;
use BoardStreams::Diff qw(diff patch);

my @cases = (
    ['no change',      { a => 1, b => [1, 2] }, { a => 1, b => [1, 2] }, undef],
    ['changed key',    { a => 1, b => 2 },      { a => 1, b => 3 },      { o => { b => { v => 3 } } }],
    ['added key',      { a => 1 },              { a => 1, b => undef },  { o => { b => { v => undef } } }],
    ['deleted key',    { a => 1, b => 2 },      { a => 1 },              { d => ['b'] }],
    ['nested change',  { a => { b => { c => 1 } } }, { a => { b => { c => 2 } } },
        { o => { a => { o => { b => { o => { c => { v => 2 } } } } } } }],
    ['array append',   { l => [1, 2] },         { l => [1, 2, 3, 4] },   { o => { l => { a => [3, 4] } } }],
    ['array rewrite',  { l => [1, 2] },         { l => [2, 1] },         { o => { l => { v => [2, 1] } } }],
    ['append to empty', { l => [] },            { l => [1] },            { o => { l => { v => [1] } } }],
    ['type change',    { a => { b => 1 } },     { a => [1] },            { o => { a => { v => [1] } } }],
    ['whole value',    [1],                     { a => 1 },              { v => { a => 1 } }],
);

for my $case (@cases) {
    my ($name, $old, $new, $expected) = @$case;
    my $diff = diff($old, $new);
    is_deeply $diff, $expected, "$name: diff";
    is_deeply patch($old, $diff), $new, "$name: patch gives the new value";
}

my $old = { a => { b => 1 }, c => [1] };
patch($old, diff($old, { a => { b => 2 }, c => [1, 2] }));
is_deeply $old, { a => { b => 1 }, c => [1] }, 'patch leaves its input untouched';

done_testing;
