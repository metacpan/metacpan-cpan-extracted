#!perl

use 5.010;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Data::TableData::Object qw(table);

my $td = table({a=>1, b=>2, c=>3});
ok($td->isa("Data::TableData::Object::hash"), "isa");

is_deeply($td->cols_by_name, {key=>0, value=>1}, "cols_by_name");
is_deeply($td->cols_by_idx, ['key', 'value'], "cols_by_idx");
is($td->row_count, 3, "row_count");
is($td->col_count, 2, "col_count");

subtest col_exists => sub {
    ok( $td->col_exists("key"));
    ok( $td->col_exists("value"));
    ok(!$td->col_exists("foo"));
};

subtest col_name => sub {
    is_deeply($td->col_name(0), "key");
    is_deeply($td->col_name("key"), "key");
    is_deeply($td->col_name(1), "value");
    is_deeply($td->col_name("foo"), undef);
};

subtest col_idx => sub {
    is_deeply($td->col_idx(0), 0);
    is_deeply($td->col_idx("key"), 0);
    is_deeply($td->col_idx("value"), 1);
    is_deeply($td->col_idx("foo"), undef);
};

subtest rows_as_aoaos => sub {
    is_deeply($td->rows_as_aoaos, [["a",1],["b",2],["c",3]]);
};

subtest rows_as_aohos => sub {
    is_deeply($td->rows_as_aohos, [{key=>"a",value=>1},{key=>"b",value=>2},{key=>"c",value=>3}]);
};

subtest select => sub {
    my $td2;

    dies_ok { $td->select_as_aoaos(["foo"]) } "unknown column -> dies";

    $td2 = $td->select_as_aoaos();
    is_deeply($td2->rows_as_aoaos, [["a",1],["b",2],["c",3]]);

    $td2 = $td->select_as_aoaos(['*']);
    is_deeply($td2->rows_as_aoaos, [["a",1],["b",2],["c",3]]);

    $td2 = $td->select_as_aoaos(["value", "value"]);
    is_deeply($td2->rows_as_aoaos, [[1,1],[2,2],[3,3]]);

    $td2 = $td->select_as_aohos(["value", "value"]);
    is_deeply($td2->rows_as_aohos, [{value=>1,value_2=>1},{value=>2,value_2=>2},{value=>3,value_2=>3}]);

    # filter, exclude & sort
    dies_ok { $td->select_as_aoaos([], undef, ["foo"]) } "unknown sort column -> dies";
    $td2 = $td->select_as_aoaos(["value", "key"],
                                ["key"],
                                sub { my ($td, $row) = @_; $row->{value} % 2 },
                                ["-key"]);
    is_deeply($td2->rows_as_aoaos, [[3],[1]]);
};

subtest uniq_col_names => sub {
    is_deeply([table({})->uniq_col_names], ['key','value']);
    is_deeply([table({a=>1})->uniq_col_names], ['key','value']);
    is_deeply([table({a=>undef})->uniq_col_names], ['key'], 'undef');

    is_deeply([table({a=>1, b=>2})->uniq_col_names], ['key','value']);
    is_deeply([table({a=>1, b=>undef})->uniq_col_names], ['key'], 'value has undef');
    is_deeply([table({a=>1, b=>1})->uniq_col_names], ['key'], 'value has duplicates');
};

subtest const_col_names => sub {
    is_deeply([table({})->const_col_names], ['value']);
    is_deeply([table({a=>1})->const_col_names], ['value']);
    is_deeply([table({a=>undef})->const_col_names], ['value'], 'undef');

    is_deeply([table({a=>1, b=>1})->const_col_names], ['value']);
    is_deeply([table({a=>1, b=>undef})->const_col_names], [], 'value has undef');
    is_deeply([table({a=>1, b=>2})->const_col_names], [], 'different values');
};

subtest del_col => sub {
    my $td = table({a=>1});
    dies_ok { $td->del_col('key') };
    dies_ok { $td->del_col('value') };
    dies_ok { $td->del_col(0) };
    dies_ok { $td->del_col(1) };
};

subtest rename_col => sub {
    my $td = table({a=>1});
    dies_ok { $td->rename_col('key','foo') };
    dies_ok { $td->rename_col('value','foo') };
};

subtest switch_cols => sub {
    my $td = table({a=>1});
    dies_ok { $td->switch_cols('key', 'value') };
    dies_ok { $td->switch_cols('key', 'key') };
    dies_ok { $td->switch_cols('value', 'value') };
    dies_ok { $td->switch_cols('value', 'key') };
};

subtest set_col_val => sub {
    my $td = table({a=>1, b=>2, c=>3});
    dies_ok { $td->set_col_val('foo', sub { 1 }) } "unknown column -> dies";

    $td->set_col_val('value', sub { 40 });
    is_deeply($td->{data}, {a=>40, b=>40, c=>40});

    $td->set_col_val('key', sub { my %args = @_; "$args{row_name}2" });
    is_deeply($td->{data}, {a2=>40, b2=>40, c2=>40});
};

DONE_TESTING:
done_testing;
