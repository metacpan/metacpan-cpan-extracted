# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 30;

BEGIN {
    use_ok('DBomb');
    use_ok('DBomb::Query');
    use_ok('DBomb::Base');
    use_ok('DBomb::Meta::ColumnInfo');
    use_ok('DBomb::Meta::Key');
    use_ok('DBomb::Meta::TableInfo');
    use_ok('DBomb::Meta::OneToMany');
    use_ok('DBomb::Meta::HasA');
    use_ok('DBomb::Meta::HasMany');
    use_ok('DBomb::Query::LeftJoin');
    use_ok('DBomb::Query::Expr');
    use_ok('DBomb::Query::Join');
    use_ok('DBomb::Query::Limit');
    use_ok('DBomb::Query::OrderBy');
    use_ok('DBomb::Query::RightJoin');
    use_ok('DBomb::Query::Text');
    use_ok('DBomb::Query::GroupBy');
    use_ok('DBomb::Query::Insert');
    use_ok('DBomb::Base::Private');
    use_ok('DBomb::Base::Defs');
    use_ok('DBomb::Value::Key');
    use_ok('DBomb::Value::Column');
    use_ok('DBomb::Test::Util');
    use_ok('DBomb::Test::Objects');
    use_ok('DBomb::Generator');
    use_ok('DBomb::GluedQuery');
    use_ok('DBomb::Util');
    use_ok('DBomb::DBH::Owner');
    use_ok('DBomb::GluedUpdate');
    use_ok('DBomb::Value');
};

# vim:set ft=perl ai si et ts=4 sts=4 sw=4 tw=0
