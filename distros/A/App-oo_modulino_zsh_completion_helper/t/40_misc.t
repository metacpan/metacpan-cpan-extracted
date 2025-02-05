#!/usr/bin/env perl
use strict;
use Test::More 0.98;

use FindBin;
use lib "$FindBin::Bin/../lib";

use File::Spec;

(my $testDir = File::Spec->rel2abs(__FILE__)) =~ s/\.t$/.d/;

use_ok $_ for qw(
    App::oo_modulino_zsh_completion_helper
);

unless (eval {symlink("",""); 1}) {
  plan skip_all => "symlink is not supported on this platform";
}

my $execFn = "$testDir/Baz.pm";

ok symlink("lib/Foo/Bar/Baz.pm", $execFn), "prepare symlink";

is_deeply(
  [App::oo_modulino_zsh_completion_helper->find_package_from_pm($execFn)],
  [
    qw(Foo::Bar::Baz),
    "$testDir/lib",
    1
 ], "find_package_from_pm should resolve symlink"
);

ok unlink($execFn), "remove the symlink";

done_testing;
