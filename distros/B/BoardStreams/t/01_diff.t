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
    ['array rewrite',  { l => [1, 2] },         { l => [3, 4] },         { o => { l => { v => [3, 4] } } }],
    ['push',           [1, 2],                  [1, 2, 3],               { a => [3] }],
    ['pop',            [1, 2, 3],               [1, 2],                  { s => [0, 2] }],
    ['shift',          [1, 2, 3],               [2, 3],                  { s => [1, 3] }],
    ['unshift',        [1, 2],                  [0, 1, 2],               { p => [0] }],
    ['several pops',   [1, 2, 3, 4],            [1],                     { s => [0, 1] }],
    ['several shifts', [1, 2, 3, 4],            [3, 4],                  { s => [2, 4] }],
    ['shift and push (a capped log)', [1, 2, 3], [2, 3, 4],              { s => [1, 3], a => [4] }],
    ['pop and unshift', [1, 2, 3],              [0, 1, 2],               { s => [0, 2], p => [0] }],
    ['unshift and push', [1, 2],                [0, 1, 2, 3],            { p => [0], a => [3] }],
    ['pop and push (last item replaced)', [1, 2, 3], [1, 2, 9],          { s => [0, 2], a => [9] }],
    ['shift and unshift (first item replaced)', [1, 2, 3], [9, 2, 3],    { v => [9, 2, 3] }],
    ['an item in the middle changed', [1, 2, 3, 4], [1, 9, 3, 4],        { s => [0, 1], a => [9, 3, 4] }],
    ['pop among equal items', [7, 7, 7],        [7, 7],                  { s => [0, 2] }],
    ['unshift of an equal item', [7, 8],        [7, 7, 8],               { p => [7] }],
    ['shift of structures', [{ id => 1 }, { id => 2 }, { id => 3 }], [{ id => 2 }, { id => 3 }], { s => [1, 3] }],
    ['array inside an object', { l => [1, 2, 3] }, { l => [2, 3] },      { o => { l => { s => [1, 3] } } }],
    ['emptied array',  { l => [1, 2] },         { l => [] },             { o => { l => { v => [] } } }],
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
