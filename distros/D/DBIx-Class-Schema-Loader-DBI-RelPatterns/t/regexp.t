use strict;
use warnings;
use Test::More tests => 2;
use lib qw(t/lib);
use dbixcsl_relpat_common qw/make_schema/;

subtest "regexp more simple test" => sub {
    make_schema(
        loader_class => 1,
        check_statinfo => 1,
        quiet => 0,
        warnings_exist => [
            '/Multiple tables .* for foos\.quuxid/',
            '/Multiple columns in .* quuxs .* for foos\.quuxid/',
        ],
        rel_constraint => [
            # adjust the default sch
            {} => {sch=>qr/^db1$/},
            # there is nothing in schema db1
            qr/(.+)id$/ => qr/(.+)s$/,
            # composite
            qr/(.*?)s?(int|real)$/i => ['', qr/(.*)s$/, qr/(.*?)s?(int|real)$/i],
            # restore the default sch
            {sch=>''} => {sch=>''},
            # nonsense, but should reference quuxs.id
            'foos.quuxid' => {tab=>qr/^(.*)s$/},
            # not self-referential and also a duplicate; quuxs.id and quuxs.quuxid have equal priority
            qr/^quuxid$/ => qr/^quuxs$/,
            # very self-referential
            [qr/^quuxs$/, qr/^id$/] => [qr/^quuxs$/, qr/^id$/],
            # self-referential
            [qr/^(quux)s$/, qr/^id$/] => [qr/^(quux)s$/, qr/^(quux)id$/],
            # col not specified
            {tab=>qr/^quuxs$/} => [qr/^Bars$/i],
            # tab not specified
            qr/^barid$/ => {col=>qr/^barid$/},
            # foos.barid is not indexed
            [qr/^quuxs$/, qr/^barID$/i] => [qr/^foos$/, col=>qr/^barid$/],
            # adjust the defaults
            {index=>'optional'} => {},
            # Bars.barid is primary key
            {tab=>qr/^foos$/, col=>qr/^barid$/} => qr/^Bars$/,
        ],
        rel_exclude => [
            # foreign key, cannot be excluded
            qr/^quuxref$/ => {tab=>qr/^quux$/, col=>qr/^quuxid$/},
            # there is nothing in schema db1
            {sch=>qr/^db1$/, col=>qr/^fooreal$/} => {},
        ],
        test_rels => [
            'foos.barid' => 'Bars.barid',
            #'foos.quuxid' => 'quuxs.id', # quuxs.id and quuxs.quuxid have equal priority
            'Bars.quuxref' => 'quuxs.quuxid',
            '?Bars.foosint,foosreal' => 'foos.fooint,fooreal',
            'quuxs.id' => 'quuxs.quuxid',
        ],
    );

    done_testing();
};

subtest "regexp less simple test" => sub {
    make_schema(
        loader_class => 1,
        check_statinfo => 1,
        quiet => 0,
        warnings_exist => '/Multiple columns in .* quuxs .* for foos\.quuxid/',
        rel_constraint => [
            # very self-referential
            [qr/(.+)/, qr/^id$/] => [qr/(.+)/, qr/^id$/],
            # adjust the default sch
            {sch=>qr/(.*)/} => {sch=>qr/(.*)/},
            # to avoid "unknown data type" issue with older Loader
            {} => {type=>'similar'},
            # everything at once
            qr/(.*?)s?_?(?:id|int|real|num|ref)$/i => qr/(.*?)s?$/i,
        ],
        test_rels => [
            #'?foos.quuxid' => 'quuxs.quuxid', # quuxs.id and quuxs.quuxid have equal priority
            'Bars.quuxref' => 'quuxs.quuxid',
            '?Bars.foosint,foosreal,foosnum' => 'foos.fooint,fooreal,foonum',
            '?quuxs.barID' => 'Bars.barid',
        ],
    );

    done_testing();
};
