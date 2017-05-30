#!/usr/bin/perl

use strict;

BEGIN {
    use File::Spec::Functions qw(rel2abs catfile);
    use File::Basename;
    unshift(@INC, catfile(dirname(rel2abs($0)), '../lib'));
}

$| = 1; # disable output buffering;

use Test::More 0.94;

use_ok('Config::Neat');

use Config::Neat::Util qw(is_any_array);

my $c = Config::Neat->new();
ok($c, '$c is defined');

my $data;

subtest '01.nconf' => sub {
    _load_conf('01');

    ok($data->{test1}->as_string eq 'foo1');
    ok($data->{test2}->as_string eq 'foo bar');
    ok($data->{test3}->as_string eq 'foo  bar');
    ok($data->{test4}->as_string eq '/* foo */');
    ok($data->{test5}->as_string eq '\/');
    ok($data->{test6}->as_string eq '`');
    ok($data->{test7}->as_string eq '`');
    ok($data->{test8}->as_string eq '\/x');
    ok($data->{test9}->as_string eq 'http:\/\/foo\.bar\.com\/baz\/');
    ok($data->{test10}->as_string eq 'foobar');
    ok($data->{test11}->as_string eq 'foo/* test */bar');
    ok($data->{test12}->as_string eq '\\\\/\\\\/\\\\/');
    ok(ref($data->{test_multi}) eq 'Config::Neat::Array');
    ok($data->{test_multi}[0]->as_string eq 'foo bar');
    ok($data->{test_multi}[1]->as_string eq 'baz etc');
};

subtest '02.nconf' => sub {
    _load_conf('02');

    ok(is_any_array($data->{repeating_node}));
    ok(scalar(@{$data->{repeating_node}}) == 4);
    ok($data->{repeating_node}->[0]->as_string eq 'foo');
    ok($data->{repeating_node}->[1]->as_string eq 'bar');
    ok($data->{repeating_node}->[2]->as_string eq 'baz');
    ok($data->{repeating_node}->[3]->as_string eq 'etc');
};

subtest '03.nconf' => sub {
    _load_conf('03');
    ok(!exists $data->{foo});
};

subtest '04.nconf' => sub {
    eval { _load_conf('04') };
    like($@, qr|^Missing closing bracket at config line 4 position 25 |, '04.nconf validation should fail because of missing closing bracket');
};

subtest '05.nconf' => sub {
    eval { _load_conf('05') };
    like($@, qr|^Unmatched closing bracket at config line 5 position 1 |, '05.nconf validation should fail because of unmatched closing bracket');
};

done_testing();

sub _load_conf {
    my $number = shift;
    ok($data = $c->parse_file(catfile(dirname(rel2abs($0)), "data/parse/$number.nconf")), "$number.nconf loaded successfully");
}
