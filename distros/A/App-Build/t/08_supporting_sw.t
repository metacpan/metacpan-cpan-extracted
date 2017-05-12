#!/usr/bin/perl -w

use strict;
use lib qw(t/lib);
use Test::More tests => 3;
use TestAppBuild;
use App::Build;

clean_install();

SKIP: {
    eval { require File::Fetch; };
    skip 'No File::Fetch, skipping _get_supporting_software() tests', 3 if $@;
    eval { require Archive::Extract; };
    skip 'No Archive::Extract, skipping _get_supporting_software() tests', 3 if $@;

    my $cwd = Cwd::cwd();
    $cwd = "/$cwd" if $^O =~ /^MSWin/;
    $App::options{"foo-boo.url"} = "file://$cwd/t/data/Foo.tar.gz";
    my $build1 = App::Build->new
      ( module_name  => 'Foo::Boo',
        dist_version => '0.01',
        quiet        => 1,
        );

    is( -s 't/data/Foo.tar.gz', -s 'archive/Foo.tar.gz' );
    is( -s 'unpack/Foo/Build.PL', 551 );
    is( -s 'unpack/Foo/cgi-bin/foo/foo.conf', 20 );
}
