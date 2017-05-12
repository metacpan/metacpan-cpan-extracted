#!/usr/bin/perl -I..lib -Ilib
use strict;
use Test::More tests => 4;
use File::Copy::Recursive qw(dircopy);
use Path::Tiny;

BEGIN { use_ok("CSS::Watcher::Monitor"); }
my $home = "t/tmp/ac-html/";

subtest "new()" => sub {
    my $mon = CSS::Watcher::Monitor->new;
    is ($mon->scan(), 0, 'default scan value for null project');
    is ($mon->scan(sub {}), 0, 'default scan value for null project');
    my $mon2 = CSS::Watcher::Monitor->new({dir => "t/fixtures/prj1"});
    is ($mon2->scan(undef), 0, 'no callback no changes');
    my $mon3 = CSS::Watcher::Monitor->new({dir => "t/fixtures/prj1"});
    cmp_ok ($mon3->scan(sub {}), '>',  0, 'File count for first scan not zero');
    is ($mon3->scan(sub {}), 0, 'File count for second scan must be zero');
};

# subtest '_deep_compare' => sub {
#     my $mon = CSS::Watcher::Monitor->new({dir => 't/monitoring/prj1/'});
#     ok ($mon->_deep_compare(
#         {foo => 1, bar => 2},
#         {bar => 2, foo => 1}), 'Compare 2 hashes');
# };

subtest "Scan files" => sub {

    path ("t/monitoring/")->remove_tree({safe => 0});
    path ("t/monitoring/")->mkpath;

    dircopy "t/fixtures/prj1/", "t/monitoring/prj1";

    my $mon = CSS::Watcher::Monitor->new({dir => 't/monitoring/prj1/'});
    my @expect_files = qw(t/monitoring/prj1/.csswatcher
                          t/monitoring/prj1/css/index.html
                          t/monitoring/prj1/css/simple.css
                          t/monitoring/prj1/css/override.css
                          t/monitoring/prj1/css/ignored.css
                     );
    subtest "First check" => sub {
        my $file_clount = 0;
        $mon->scan(sub {
                       my $file = shift;
                       ok (grep (/${file}$/, @expect_files), "Check file present $file");
                       $file_clount++;
                   });
        is ($file_clount, scalar (@expect_files), 'Expected file count');
    };

    subtest "Second check" => sub {
        my $file_clount = 0;
        $mon->scan(sub {
                       my $file = shift;
                       BAIL_OUT("I don't expect that file $file being changed.");
                   });
        ok(1);
    };

    subtest "Force recheck" => sub {
        my $file_clount = 0;
        $mon->make_dirty;
        $mon->scan(sub {
                       my $file = shift;
                       ok (grep (/${file}$/, @expect_files), "Check file present $file");
                       $file_clount++;
                   });
        is ($file_clount, scalar (@expect_files), 'Expected file changed count');
    };

    # subtest "Force re-check" => sub {
    #     my $file_clount = 0;
    #     $mon->make_dirty;
    #     $mon->scan(sub {
    #                    my $file = shift;
    #                    ok (grep (/${file}$/, @expect_files), "Check file present $file");
    #                    $file_clount++;
    #                });
    #     is ($file_clount, scalar (@expect_files), 'Expected file changed count');
    # };

    subtest "Create new file, check for changes" => sub {
        my $cssfile = "t/monitoring/prj1/css/new.css";

        open(my $fh, '>', $cssfile);
        print $fh <<CSS
.container {
 color: #fff;
}
CSS
            ;
        close $fh;
        $mon->scan(sub {
                       is (shift, $cssfile, "It must be $cssfile only as new file");
                   }
               );

        subtest "is_changed method" => sub {

            ok (!$mon->is_changed($cssfile), "Not changed");

            # wait few seconds
            sleep 2;

            open(my $fh, '>', $cssfile);
            print $fh <<CSS
.container {
 color: #fff;
}
CSS
                ;
            close $fh;

            ok ($mon->is_changed($cssfile), "Changed");
        }
    };
};

subtest '"skip_dirs" command of .csswatcher. Ignore directory' => sub {
    path("t/monitoring/")->mkpath;

    dircopy "t/fixtures/prj2_skip/", "t/monitoring/prj2_skip";

    my $mon = CSS::Watcher::Monitor->new( { dir => 't/monitoring/prj2_skip' } );
    my @expect_files = qw(
      t/monitoring/prj2_skip/.csswatcher
      t/monitoring/prj2_skip/somedir/1.css
      t/monitoring/prj2_skip/somedir/main.css
    );

    subtest "First check" => sub {
        my $file_clount = 0;
        $mon->scan(
            sub {
                my $file = shift;
                ok(
                    grep ( /${file}$/, @expect_files ),
                    "Check file present $file"
                );
                $file_clount++;
            },
            ['thisdirmustbeignored']
        );
        is( $file_clount, scalar(@expect_files), 'Expected file count' );
    };

};

