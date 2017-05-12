use strict;
use warnings;
use Test::More;
use lib qw(t/lib);
use dbixcsl_relpat_common qw/make_schema/;

make_schema(
    loader_class => 1,
    check_statinfo => 1,
    rel_constraint => [
        # duplicates the foreign key
        'Bars.quuxref' => 'quuxs.quuxid',
        # different types
        'Bars.fooreal' => 'foos.fooint',
        # bars_fooint_fooreal_idx is not unique
        {col=>qr/(.*?)s?(?:int|real)$/, index=>'unique'} => [qr/(.*)s$/, qr/(.*?)s?(?:int|real)$/],
        # fooreal is not the leftmost prefix of the composite index
        'fooreal' => 'foos.',
        # not self-referential
        {col=>qr/^quuxid$/, index=>'unique'} => qr/^quuxs$/,
        # very self-referential
        [qr/^quuxs$/, qr/^(id)$/] => [qr/^quuxs$/, qr/(.+)/],
        # captured contents do not match
        [qr/^(quux)s$/, qr/^id$/] => [qr/^(quux)s$/, qr/^(quuxid)$/],
        # quuxid is not primary
        [qr/^foos$/, qr/quuxid$/] => {tab=>qr/^quuxs$/, col=>qr/^quuxid$/, index=>'primary'},
        # barid is not indexed
        [qr/^foos$/, qr/^barid$/] => qr/^Bars$/i,
        # adjust the defaults
        {index=>'unique'} => {},
        # barid is not unique
        'barid' => 'Bars.',
        # adjust the defaults
        {sch=>'db1', index=>'any'} => {},
        # barid is not in schema db1
        'barid' => 'Bars.',
    ],
    test_rels => [
        'Bars.quuxref' => 'quuxs.quuxid', # foreign key, cannot be excluded
    ],
);

done_testing();
