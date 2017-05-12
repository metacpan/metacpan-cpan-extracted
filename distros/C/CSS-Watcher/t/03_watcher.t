#!/usr/bin/perl -I..lib -Ilib
use strict;
use Test::More tests => 7;
use File::Copy::Recursive qw(dircopy);
use Path::Tiny;
use Digest::MD5 qw/md5_hex/;

BEGIN { use_ok("CSS::Watcher"); }

use constant TEST_HTML_STUFF_DIR => 't/monitoring/stuff/';

subtest "Projectile dir" => sub {
    is (CSS::Watcher->get_project_dir("t/fixtures/prj1/css/simple.css"),
        path("t/fixtures/prj1"),
        "Search for \".watcher\" file");
    is (CSS::Watcher->get_project_dir("t/fixtures/prj1/"),
        path("t/fixtures/prj1"),
        "Search for \".watcher\" file");
};

subtest "Default output directory" => sub {
    my $watcher = CSS::Watcher->new();
    is ($watcher->{outputdir}, CSS::Watcher::DEFAULT_HTML_STUFF_DIR, 'Default output directory');
};

subtest "Generate classes and ids" => sub {

    path ("t/monitoring/")->remove_tree({safe => 0});
    path ("t/monitoring/")->mkpath;
    dircopy "t/fixtures/prj1/", "t/monitoring/prj1";

    my $watcher = CSS::Watcher->new({'outputdir' => TEST_HTML_STUFF_DIR});

    is ($watcher->update("t/monitoring/NOPROJECT/css"), undef,
        "\$watcher->update return undef if bad project path");

    my ($changes, $project_dir) = $watcher->update("t/monitoring/prj1/css");

    is ($project_dir, path("t/monitoring/prj1"),
        "Search for \".watcher\" file");

    is ($changes, 3, 'Must be 2 css files and 1 .csswatcher file');
    my ($classes, $ids) = $watcher->project_stuff ($project_dir);

    ok ($classes->{global}{container} =~ m| css/override\.css|, ".container must be present in override.css");
    ok ($classes->{global}{container} =~ m| css/simple\.css|, ".container must be present in simple.css");
    is ($ids->{global}{myid}, 'Defined in css/simple.css\n', "#myid must be present in simple.css");

    subtest "Generate html-stuff data" => sub {
        my $result_dir = $watcher->build_ac_html_stuff ($project_dir);
        is (index ($result_dir, TEST_HTML_STUFF_DIR), 0, "Good stuff dir \"@{[TEST_HTML_STUFF_DIR]}\"");
        ok (-f path($result_dir)->child('html-attributes-complete/global-class'), 'file exists global-class');
        ok (-f path($result_dir)->child('html-attributes-complete/p-class'), 'file exists p-class');
        ok (-f path($result_dir)->child('html-attributes-complete/global-id'), 'file exists global-id');

    };
};

subtest "sub get_html_stuff" => sub {

    path ("t/monitoring/")->remove_tree({safe => 0});
    path ("t/monitoring/")->mkpath;
    dircopy "t/fixtures/prj1/", "t/monitoring/prj1";

    my $watcher = CSS::Watcher->new({'outputdir' => TEST_HTML_STUFF_DIR});

    is ($watcher->get_html_stuff("t/monitoring/NOPROJECT/css"), undef,
        "\$watcher->get_html_stuff return undef if bad project path");

    my ($project_dir, $result_dir) = $watcher->get_html_stuff("t/monitoring/prj1/css");

    is (index ($result_dir, TEST_HTML_STUFF_DIR), 0, "Good stuff dir \"@{[TEST_HTML_STUFF_DIR]}\"");
    ok (-f path($result_dir)->child('html-attributes-complete/global-class'), 'file exists global-class');
    ok (-f path($result_dir)->child('html-attributes-complete/p-class'), 'file exists p-class');
    ok (-f path($result_dir)->child('html-attributes-complete/global-id'), 'file exists global-id');

    like (path($result_dir)->child('html-attributes-complete/global-class')->slurp_utf8,
          qr(container Defined in), 'class "btn-info" in main.less');

};

subtest "Clean project, that have no css files and no .csswatcher" => sub {
    my $watcher = CSS::Watcher->new({'outputdir' => TEST_HTML_STUFF_DIR});
    path ("t/monitoring/proj3/css")->mkpath;
    path ("t/monitoring/proj3/.git")->touchpath;
    my ($project_dir, $result_dir) = $watcher->get_html_stuff("t/monitoring/proj3/css");
    is ($project_dir, path("t/monitoring/proj3"), 'Project directory must be defined');
    is ($result_dir, undef, 'ac_html_stuff_directory must be undef, there no css files for parse.');

    subtest "Create .csswatcher" => sub {
        path ("t/monitoring/proj3/.csswatcher")->touchpath;
        ($project_dir, $result_dir) = $watcher->get_html_stuff("t/monitoring/proj3/css");
        isnt ($result_dir, undef, '.csswatcher exist ac_html_stuff_directory must be defined');
    }
};


subtest '"skip" in .csswatcher' => sub {
    path ("t/monitoring/")->remove_tree({safe => 0});
    path ("t/monitoring/")->mkpath;
    dircopy "t/fixtures/prj2_skip/", "t/monitoring/prj2_skip";

    my $watcher = CSS::Watcher->new({'outputdir' => TEST_HTML_STUFF_DIR});
    my ($changes, $project_dir) = $watcher->update("t/monitoring/prj2_skip");
    is ($changes, 3, 'Must be 2 css files and 1 .csswatcher');
};
