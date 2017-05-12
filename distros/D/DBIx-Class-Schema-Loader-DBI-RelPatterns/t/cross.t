use strict;
use warnings;
use Test::More;
use lib qw(t/lib);
use dbixcsl_relpat_common qw/make_schema/;

if ($DBIx::Class::Schema::Loader::VERSION < 0.07011) {
    plan skip_all => "DBIx::Class::Schema::Loader at least 0.07011 is required";
} else {
    plan tests => 2;
}

subtest "cross-schema more simple test" => sub {
    my $relpat_test_schema_map = {
        'quuxs' => 'quuxsdb',
    };

    make_schema(
        loader_class => '::DBI::RelPatterns::Test',
        relpat_test_schema_map => $relpat_test_schema_map,
        check_statinfo => 1,
        quiet => 0,
        warnings_suppress => '/db_schema/',
        warnings_exist => '/Multiple columns in .* quuxs .* for foos\.quuxid/',
        db_schema => 'main',
        qualify_objects => 1,
        rel_name_map => sub { $_[0]->{name} },
        rel_constraint => [
            # everything at once
            qr/(.*?)s?_?(?:id|int|real|num|ref)$/i => qr/(.*?)s?$/i,
            # nonsense, but should reference foos.fooint
            # because quuxs is in a different schema and Bars is excluded
            'foos.quuxid' => {tab=>qr/^(.*)s$/},
        ],
        rel_exclude => [
            'foos.quuxid' => 'Bars.',
        ],
        test_rels => [
            #'?foos.quuxid' => 'quuxs.id', # quuxs.id and quuxs.quuxid have equal priority
            'foos.quuxid' => 'foos.fooint',
            'Bars.quuxref' => 'quuxs.quuxid',
            '?Bars.foosint,foosreal,foosnum' => 'foos.fooint,fooreal,foonum',
            '?quuxs.barID' => 'Bars.barid',
        ],
    );
    
    done_testing();
};

subtest "cross-schema less simple test" => sub {
    my $relpat_test_schema_map = {
        'foos'  => 'foosdb',
        'Bars'  => 'Barsdb',
    };

    make_schema(
        loader_class => '::DBI::RelPatterns::Test',
        relpat_test_schema_map => $relpat_test_schema_map,
        check_statinfo => 1,
        warnings_suppress => '/db_schema/',
        db_schema => 'main',
        qualify_objects => 1,
        rel_constraint => [
            # adjust the default sch
            {sch=>qr/^Bars(db)$/} => {sch=>qr/^foos(db)$/},
            # everything at once
            qr/(.*?)s?_?(?:id|int|real|num|ref)$/i => qr/(.*?)s?$/i,
            # captured contents do not match
            {sch=>qr/^foos(db)$/} => {sch=>qr/^quuxs(d)(b)$/},
            # everything at once
            qr/(.*?)s?_?(?:id|int|real|num|ref)$/i => qr/(.*?)s?$/i,
            # adjust the defaults to forbid cross-schema relationships
            {sch=>qr/(.*)/} => {sch=>qr/(.*)/},
            # everything at once
            qr/(.*?)s?_?(?:id|int|real|num|ref)$/i => qr/(.*?)s?$/i,
            # self-referential
            [qr/(.*?)s?$/i, qr/(.*?)s?_?(?:id|int|real|num|ref)$/i] => {tab=>qr/(.*?)s?$/i},
        ],
        rel_exclude => [
            # self-referential relationships
            {sch=>qr/(.*)/, tab=>qr/(.+)/} => {sch=>qr/(.*)/, tab=>qr/(.+)/},
        ],
        test_rels => [
            'Bars.quuxref' => 'quuxs.quuxid',
            '?Bars.foosint,foosreal,foosnum' => 'foos.fooint,fooreal,foonum',
        ],
    );
    
    done_testing();
};
