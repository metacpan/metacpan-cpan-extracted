#!/usr/bin/perl -I..lib -Ilib
use strict;
use Test::More;
use File::Which;

if (which('lessc')) {
    plan tests => 4;
} else {
    plan skip_all => 'No less compilator found, install it via "npm install less"';
}

use_ok("CSS::Watcher::ParserLess");

my $parser = CSS::Watcher::ParserLess->new();

subtest "Parse var.less variables, no class, no ids, no requiries should be" => sub {
    my ($classes, $ids, $requiries) = $parser->parse_less ('t/fixtures/prjless/less/var.less');
    is_deeply ($classes, {}, "Empty classes");
    is_deeply ($ids, {}, "Empty ids");
    is_deeply ($requiries, [], "Empty requiries");
};

subtest "Parse t.less, no class, no ids, no requiries should be" => sub {
    my ($classes, $ids, $requiries) = $parser->parse_less ('t/fixtures/prjless/less/t.less');
    is_deeply ($classes, {}, "Empty classes");
    is_deeply ($ids, {}, "Empty ids");
    is_deeply ($requiries, [], "Empty requiries");
};

subtest "Parse main.less" => sub {
    my ($classes, $ids, $requiries) = $parser->parse_less ('t/fixtures/prjless/less/main.less');

    my ($expect_classes, $expect_ids, $expect_requiries) = (
        {"global" => {"btn-info" => 1,
                      "btn-danger" => 1}},
        {},
        ["var.less", "t.less"]
    );

    is_deeply ($classes, $expect_classes, "Classes");
    is_deeply ($ids, $expect_ids, "Ids");
    is_deeply ($requiries, $expect_requiries, "Requiries");
}


