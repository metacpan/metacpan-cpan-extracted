use strict;
use warnings;
use Test::More;
use Test::Exception;
use lib qw(t/lib);
use dbixcsl_relpat_common qw/make_schema get_loader/;

my ($schema1, $schema2);

lives_and {
    $schema1 = make_schema(
        quiet => 0,
        test_rels => [
            'Bars.quuxref' => 'quuxs.quuxid', # foreign key
        ],
    );
} "the loader managed to stay alive";

lives_and {
    $schema2 = make_schema(
        loader_class => 1,
        no_increment => 1,
        quiet => 0,
        warnings_exist => '/RelPatterns .* without rel_constraint/',
        test_rels => [
            'Bars.quuxref' => 'quuxs.quuxid', # foreign key
        ],
    );
    
    isa_ok(get_loader($schema2), 'DBIx::Class::Schema::Loader::DBI::RelPatterns', 'loader');
} "loader class does not kill the loader";

SKIP: {
    skip "nothing to compare", 1 unless ref $schema1 && ref $schema2 && $schema1 != $schema2;
    skip "Test::Differences 0.60+ not installed", 1 unless
           eval "use Test::Differences 0.60 qw/eq_or_diff/; 1"
        && defined &eq_or_diff;
    $schema1->storage(undef);
    $schema2->storage(undef);
    eq_or_diff($schema1, $schema2, "schemas look equivalent");
}

done_testing();
