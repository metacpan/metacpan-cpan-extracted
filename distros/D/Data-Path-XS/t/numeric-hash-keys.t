use strict;
use warnings;
use Test::More;
use Test::LeakTrace;
use Data::Path::XS qw(
    path_get path_set path_delete path_exists
    patha_get patha_set patha_delete patha_exists
    path_compile pathc_get pathc_set pathc_delete pathc_exists
);
use Data::Path::XS ':keywords';

# All four APIs must dispatch by parent container type, not by key shape.
# A hash keyed by a numeric-looking string is still a hash.

my @keys = qw(0 5 -1 007 12345);

for my $key (@keys) {
    subtest "key '$key' on hash, all APIs read consistently" => sub {
        my $h = { $key => "val_$key", normal => "norm" };
        is(path_get($h, "/$key"),  "val_$key", "path_get '$key'");
        is(patha_get($h, [$key]),  "val_$key", "patha_get '$key'");
        is(pathc_get($h, path_compile("/$key")), "val_$key", "pathc_get '$key'");

        my $r = $h;
        my $p = "/$key";
        is((pathget $r, $p), "val_$key", "kw pathget dyn '$key'");

        ok(path_exists($h, "/$key"),  "path_exists '$key'");
        ok((pathexists $r, $p),       "kw pathexists dyn '$key'");
    };
}

subtest 'pathset (dynamic) on hash with numeric key' => sub {
    my $h = { '0' => 'old' };
    my $r = $h;
    my $p = "/0";
    pathset $r, $p, "new";
    is($h->{'0'}, "new", 'pathset dynamic stored by hash key');

    my $h2 = {};
    pathset $h2, "/users/0/name", "alice";
    is($h2->{users}[0]{name}, "alice",
       'pathset autoviv: array under numeric component is fine when it is intermediate');
};

subtest 'pathset (constant path) on hash with numeric key' => sub {
    my $h = { '0' => 'old' };
    pathset $h, "/0", "new";
    is($h->{'0'}, "new", 'const-path pathset stored by hash key when parent is hash');

    # All-string const path still uses fast-path (no numeric in any component)
    my $h2 = {};
    pathset $h2, "/a/b/c", "deep";
    is($h2->{a}{b}{c}, "deep", 'const-path all-string still works');
};

subtest 'pathdelete (dynamic) on hash with numeric key' => sub {
    my $h = { '0' => 'doomed', keep => 1 };
    my $p = "/0";
    is((pathdelete $h, $p), 'doomed', 'pathdelete returned value');
    ok(!exists $h->{'0'}, 'key actually removed');
    is($h->{keep}, 1, 'unrelated key untouched');
};

subtest 'arrays still work for valid numeric indices' => sub {
    my $arr = ['a','b','c'];
    is(path_get($arr, "/1"),   'b', 'path_get array');
    is((pathget $arr, "/1"),   'b', 'kw pathget const array');
    my $p = "/2";
    is((pathget $arr, $p),     'c', 'kw pathget dyn array');
    ok(path_exists($arr, "/2"),     'path_exists array');
    ok((pathexists $arr, $p),       'kw pathexists dyn array');
};

subtest 'mixed structures' => sub {
    my $d = { users => [ { id => '0', name => 'a' }, { id => '1', name => 'b' } ] };
    is((pathget $d, "/users/0/name"), 'a', 'kw const mixed');
    is((pathget $d, "/users/1/id"),   '1', 'kw const mixed numeric value');
    my $p1 = "/users/0/id";
    is((pathget $d, $p1), '0', 'kw dyn mixed numeric-string value');
};

subtest 'leaks' => sub {
    no_leaks_ok {
        my $h = { '0' => 'z' };
        my $r = $h; my $p = "/0";
        pathget $r, $p;
        pathexists $r, $p;
    } 'kw pathget/exists numeric-key no leaks';

    no_leaks_ok {
        my $h = { '0' => 'z' };
        my $r = $h; my $p = "/0";
        pathset $r, $p, 'new';
    } 'kw pathset numeric-key no leaks';

    no_leaks_ok {
        my $h = { '0' => 'z' };
        my $r = $h; my $p = "/0";
        pathdelete $r, $p;
    } 'kw pathdelete numeric-key no leaks';
};

done_testing;
