#!/usr/bin/perl -I..lib -Ilib
use strict;
use Test::More;
use File::Copy::Recursive qw(dircopy);
use Path::Tiny;
use File::Which;
use Digest::MD5 qw/md5_hex/;

if (which('lessc')) {
    plan tests => 3;
} else {
    plan skip_all => 'No less compilator found, install it via "npm install less"';
}

use_ok("CSS::Watcher");
use_ok("CSS::Watcher::ParserLess");

use constant TEST_HTML_STUFF_DIR => 't/monitoring/stuff_less/';

subtest "Project that have .less files" => sub {

    path ("t/monitoring/")->remove_tree({safe => 0});
    path ("t/monitoring/")->mkpath;
    dircopy "t/fixtures/prjless/", "t/monitoring/prjless";

    my $watcher = CSS::Watcher->new({'outputdir' => TEST_HTML_STUFF_DIR});

    my ($project_dir, $result_dir) = $watcher->get_html_stuff("t/monitoring/prjless");

    is (index ($result_dir, TEST_HTML_STUFF_DIR), 0, "Good stuff dir \"@{[TEST_HTML_STUFF_DIR]}\"");
    ok (-f path($result_dir)->child('html-attributes-complete/global-class'), 'file exists global-class');

    like (path($result_dir)->child('html-attributes-complete/global-class')->slurp_utf8,
          qr/btn-info Defined in less\/main\.less/, 'class "btn-info" in main.less');
    like (path($result_dir)->child('html-attributes-complete/global-class')->slurp_utf8,
          qr/btn-danger Defined in less\/main\.less/, 'class "btn-danger" in main.less');
};

