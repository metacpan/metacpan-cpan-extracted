#!/usr/bin/perl -w

use strict;
use lib qw(t/lib);
use Test::More tests => 2;
use TestAppBuild;
use App::Build;

clean_install();

SKIP: {
    eval { require File::Fetch };
    skip 'No File::Fetch, skipping mirror() tests', 2 if $@;

    touch_file( 't/test_install/foo.2' );

    my $build1 = App::Build->new
      ( module_name  => 'Foo::Boo',
        dist_version => '0.01',
        quiet        => 1,
        );
    my $cwd = Cwd::cwd();
    $cwd = "/$cwd" if $^O =~ /^MSWin/;
    $build1->mirror( "file://$cwd/t/06_mirror.t", 't/test_install/foo.1' );
    $build1->mirror( "file://$cwd/t/06_mirror.t", 't/test_install/foo.2' );

    is( -s 't/test_install/foo.1', -s 't/06_mirror.t' );
    is( -s 't/test_install/foo.2', 0 );
}
