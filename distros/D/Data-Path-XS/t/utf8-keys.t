use strict;
use warnings;
use utf8;
use Test::More;
use Test::LeakTrace;
use Data::Path::XS qw(
    path_get path_set path_delete path_exists
    patha_get patha_set patha_delete patha_exists
    path_compile pathc_get pathc_set pathc_delete pathc_exists
);
use Data::Path::XS ':keywords';

# Round-trip Perl-stored UTF-8 keys to every API.

subtest 'string API: read UTF-8 keys' => sub {
    my %h = (café => 'cafe', "日本語" => 'jp', 'plain' => 'p');
    my $r = \%h;
    is(path_get($r, "/café"),   'cafe', 'path_get café');
    is(path_get($r, "/日本語"), 'jp',   'path_get jp');
    is(path_get($r, "/plain"),  'p',    'path_get plain');
    ok(path_exists($r, "/café"),    'path_exists café');
    ok(path_exists($r, "/日本語"),  'path_exists jp');
    ok(!path_exists($r, "/missing"),'path_exists missing');
};

subtest 'string API: write/delete UTF-8 keys' => sub {
    my %h;
    is(path_set(\%h, "/résumé", "v1"), "v1", 'path_set returns value');
    is($h{"résumé"}, "v1", 'value stored under UTF-8 key');
    is(path_delete(\%h, "/résumé"), "v1", 'path_delete returns deleted');
    ok(!exists $h{"résumé"}, 'key actually deleted');
};

subtest 'array API: UTF-8 keys' => sub {
    my %h = (naïve => 'n');
    is(patha_get(\%h, ["naïve"]), 'n', 'patha_get naïve');
    ok(patha_exists(\%h, ["naïve"]), 'patha_exists naïve');

    my %h2;
    patha_set(\%h2, ["café", "naïve"], "deep");
    is($h2{"café"}{"naïve"}, "deep", 'patha_set nested UTF-8');
    is(patha_delete(\%h2, ["café", "naïve"]), "deep", 'patha_delete UTF-8');
};

subtest 'compiled API: UTF-8 keys' => sub {
    my %h = (Москва => 'mow');
    my $cp = path_compile("/Москва");
    is(pathc_get(\%h, $cp), 'mow', 'pathc_get UTF-8');
    ok(pathc_exists(\%h, $cp), 'pathc_exists UTF-8');

    my %h2;
    my $cp2 = path_compile("/€/¥/£");
    pathc_set(\%h2, $cp2, "money");
    is($h2{"€"}{"¥"}{"£"}, "money", 'pathc_set deep UTF-8');
    is(pathc_delete(\%h2, $cp2), "money", 'pathc_delete UTF-8');
};

subtest 'keyword API: UTF-8 keys (dynamic)' => sub {
    my %h = (Привет => 'hi');
    my $r = \%h;
    my $p = "/Привет";

    is((pathget $r, $p), 'hi', 'pathget dynamic UTF-8');
    ok((pathexists $r, $p), 'pathexists dynamic UTF-8');

    my %h2;
    my $p2 = "/Tokyo/東京";
    pathset \%h2, $p2, "city";
    is($h2{Tokyo}{東京}, "city", 'pathset dynamic UTF-8');
    is((pathdelete \%h2, $p2), "city", 'pathdelete dynamic UTF-8');
};

subtest 'keyword API: UTF-8 keys (constant)' => sub {
    my %h = (Beijing => 'bj');
    is((pathget \%h, "/Beijing"), 'bj', 'pathget const UTF-8');
    ok((pathexists \%h, "/Beijing"), 'pathexists const UTF-8');

    my %h2;
    pathset \%h2, "/München/Köln", "DE";
    is($h2{München}{Köln}, "DE", 'pathset const UTF-8 (deep)');
    is((pathdelete \%h2, "/München/Köln"), "DE", 'pathdelete const UTF-8');
};

subtest 'UTF-8 const path uses dynamic op semantics' => sub {
    # Const path with UTF-8 flag is routed through pp_pathset_dynamic, which
    # replaces non-ref intermediate scalars (HELEM-chain optimization would
    # croak instead). This test pins the dynamic-op fallthrough.
    my %h = (Köln => "scalar_in_way");
    my $sub = sub { my $d = shift; pathset $d, "/Köln/x", "v" };
    $sub->(\%h);
    is(ref $h{Köln}, 'HASH', 'utf8 const pathset replaced scalar via dynamic op');
    is($h{Köln}{x}, 'v', 'utf8 const pathset stored deeper');
};

subtest 'leaks: UTF-8 operations' => sub {
    my %h = (café => 'c');
    my $cp = path_compile("/café");
    no_leaks_ok { path_get(\%h, "/café") } 'path_get UTF-8 leaks';
    no_leaks_ok { my %x; path_set(\%x, "/résumé/naïve", "v") } 'path_set UTF-8 leaks';
    no_leaks_ok { patha_get(\%h, ["café"]) } 'patha_get UTF-8 leaks';
    no_leaks_ok { pathc_get(\%h, $cp) } 'pathc_get UTF-8 leaks';
    no_leaks_ok { my $sub = sub { my ($d,$p) = @_; pathget $d, $p }; $sub->(\%h, "/café") }
        'kw pathget dyn UTF-8 leaks';
};

done_testing;
