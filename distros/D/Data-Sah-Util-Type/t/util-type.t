#!perl

use 5.010;
use strict;
use warnings;

use Data::Sah::Util::Type qw(is_type is_simple is_collection is_numeric is_ref);
use Test::More 0.98;

subtest is_type => sub {
    ok( is_type("int"));
    ok( is_type("int*"));
    ok(!is_type("foo"));
};

subtest is_simple => sub {
    ok(!is_simple("all"), "all without of");
    ok(!is_simple([all => of => []]), "all with of 1");
    ok(!is_simple([all => of => ["int", "array"]]), "all with of 2");
    ok( is_simple([all => of => ["int", ["float"]]]), "all with of 3");
    ok(!is_simple([all => "!of" => ["int", ["float"]]]), "all with !of");
    ok(!is_simple([all => of => ["int", ["float"]], "of.op"=>"not"]), "all with of.op");

    ok(!is_simple("any"), "any without of");
    ok(!is_simple([any => of => []]), "any with of 1");
    ok(!is_simple([any => of => ["int", "array"]]), "any with of 2");
    ok( is_simple([any => of => ["int", ["float"]]]), "any with of 3");
    ok(!is_simple([any => "!of" => ["int", ["float"]]]), "any with !of");
    ok(!is_simple([any => of => ["int", ["float"]], "of.op"=>"not"]), "any with of.op");

    ok(!is_simple("array"), "array");

    ok(is_simple("bool"), "bool");

    ok(is_simple("buf"), "int");

    ok(is_simple("cistr"), "cistr");

    ok(!is_simple("code"), "code");

    ok(is_simple("float"), "float");

    ok(!is_simple("hash"), "hash");

    ok(is_simple("int"), "int");

    ok(is_simple("num"), "num");

    ok(!is_simple("obj"), "obj");

    ok(is_simple("re"), "re");

    ok(is_simple("str"), "str");

    ok(is_simple("undef"), "undef");
};

subtest is_collection => sub {
    ok(!is_collection("all"), "all without of");
    ok(!is_collection([all => of => []]), "all with of 1");
    ok(!is_collection([all => of => ["int", "array"]]), "all with of 2");
    ok( is_collection([all => of => ["array", ["hash"]]]), "all with of 3");
    ok(!is_collection([all => "!of" => ["array", ["hash"]]]), "all with !of");
    ok(!is_collection([all => of => ["array", ["hash"]], "of.op"=>"not"]), "all with of.op");

    ok(!is_collection("any"), "any without of");
    ok(!is_collection([any => of => []]), "any with of 1");
    ok(!is_collection([any => of => ["int", "array"]]), "any with of 2");
    ok( is_collection([any => of => ["array", ["hash"]]]), "any with of 3");
    ok(!is_collection([any => "!of" => ["array", ["hash"]]]), "any with !of");
    ok(!is_collection([any => of => ["array", ["hash"]], "of.op"=>"not"]), "any with of.op");

    ok(is_collection("array"), "array");

    ok(!is_collection("bool"), "bool");

    ok(!is_collection("buf"), "int");

    ok(!is_collection("cistr"), "cistr");

    ok(!is_collection("code"), "code");

    ok(!is_collection("float"), "float");

    ok(is_collection("hash"), "hash");

    ok(!is_collection("int"), "int");

    ok(!is_collection("num"), "num");

    ok(!is_collection("obj"), "obj");

    ok(!is_collection("re"), "re");

    ok(!is_collection("str"), "str");

    ok(!is_collection("undef"), "undef");
};

# XXX partial
subtest is_numeric => sub {
    ok(!is_numeric("undef"), "undef");
    ok( is_numeric("num"), "num");
    ok( is_numeric("int"), "int");
    ok( is_numeric("float"), "float");
    ok(!is_numeric("str"), "str");
    ok(!is_numeric("array"), "array");
    ok(!is_numeric("hash"), "hash");
    ok(!is_numeric("code"), "code");
    ok(!is_numeric("obj"), "obj");
};

# XXX partial
subtest is_ref => sub {
    ok(!is_ref("undef"), "undef");
    ok(!is_ref("int"), "int");
    ok( is_ref("array"), "array");
    ok( is_ref("hash"), "hash");
    ok( is_ref("code"), "code");
    ok( is_ref("obj"), "obj");
};

DONE_TESTING:
done_testing;
