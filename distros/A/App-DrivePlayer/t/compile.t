use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use File::Find;
use Test::More;

my $have_display = $ENV{DISPLAY} || $ENV{WAYLAND_DISPLAY};

my @modules;
my $lib = "$FindBin::RealBin/../lib";
find(
    sub {
        return unless /\.pm$/;
        my $module = $File::Find::name;
        $module =~ s{^\Q$lib\E/}{};
        $module =~ s{/}{::}g;
        $module =~ s{\.pm$}{};
        push @modules, $module;
    },
    $lib,
);

my @sorted = sort @modules;
plan tests => scalar @sorted;

for my $module (@sorted) {
    my $needs_display = $module =~ /::GUI/;
    if ($needs_display && !$have_display) {
        pass("$module (skipped — no display)");
    } else {
        use_ok($module);
    }
}
