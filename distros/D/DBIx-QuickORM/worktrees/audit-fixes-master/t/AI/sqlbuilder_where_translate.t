use Test2::V0;

# Regression: the SQLBuilder must emit database column names, not ORM names.
#  B4: the flat array-pairs where form ([field => v, field2 => v2]) was walked
#      element-by-element, so the field names fell through untranslated.
#  B5: an -ident value under a field key names another column and must also be
#      translated.

require DBIx::QuickORM::SQLBuilder::SQLAbstract;

{
    package t::AliasedSource;
    sub new          { bless {}, shift }
    sub field_db_name { my ($s, $n) = @_; "${n}_db" }   # ORM name -> db name
}

my $b   = DBIx::QuickORM::SQLBuilder::SQLAbstract->new;
my $src = t::AliasedSource->new;

subtest flat_array_pairs => sub {
    my $out = $b->_translate_where($src, [name => 'a', other => 'b']);
    is($out, ['name_db', 'a', 'other_db', 'b'], "flat field => value pairs translate the field names, not the values");
};

subtest hash_form_unchanged => sub {
    is($b->_translate_where($src, {name => 'a'}), {name_db => 'a'}, "hash form still translates keys");
    is($b->_translate_where($src, {name => {'>' => 5}}), {name_db => {'>' => 5}}, "operator expressions are untouched");
};

subtest ident_value_translated => sub {
    is(
        $b->_translate_where($src, {name => {'-ident' => 'other'}}),
        {name_db => {'-ident' => 'other_db'}},
        "an -ident value (a column reference) is translated to the database name",
    );
};

subtest nested_conditions_still_translate => sub {
    my $out = $b->_translate_where($src, ['-or', {name => 1}, {other => 2}]);
    is($out, ['-or', {name_db => 1}, {other_db => 2}], "a list of OR-ed conditions still translates each");
};

done_testing;
