use strict;
use warnings;
use Test::More tests => 2;
use lib qw(t/lib);
use dbixcsl_relpat_common qw/make_schema/;

my %options = (
    loader_class => 1,
    check_statinfo => 1,
    rel_constraint => [
        # composite
        qr/(.*?)s?(?:int|real)$/ => [qr/(.*)s$/, qr/(.*?)s?(int|real)$/],
        # not self-referential
        'quuxid' => 'quuxs.id',
        # self-referential
        'quuxs.id' => 'quuxs.quuxid',
        # to avoid "unknown data type" issue with older Loader
        {} => {type=>'similar'},
        # foos.barid is not indexed but both tab and col are specified
        'quuxs.barID' => 'foos.barid',
        # adjust the defaults
        {index=>'optional'} => {type=>'exact'},
        # Bars.barid is primary key
        'barid' => 'Bars.',
    ],
    test_rels => [
        'Bars.quuxref' => 'quuxs.quuxid', # foreign key, cannot be excluded
        'quuxs.barID' => 'foos.barid',    # one left
    ],
);

subtest "exclude string test" => sub {
    make_schema(%options,
        rel_exclude => [
            'Bars.quuxref' => 'quuxs.quuxid',
            'foos.' => 'quuxs.id',
            '' => 'fooint',
            '.quuxs.' => 'quuxs.',
            'barid' => 'Bars.',
        ],
    );

    done_testing();
};

subtest "exclude regexp test" => sub {
    make_schema(%options,
        rel_exclude => [
            {tab=>qr/^Bars$/i} => {},
            {tab=>qr/^foos$/} => {tab=>qr/^quuxs$/, col=>qr/^id$/},
            {tab=>qr/^(quux)s$/} => {tab=>qr/^quuxs$/},
            qr/^(bar)id$/ => qr/^(Bar)s$/i,
            qr/^(bar)id$/i => {col=>qr/^(barid)$/i}, # captured contents do not match
        ],
    );

    done_testing();
}
