use strict;
use warnings;
use Test::More;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# Each eg/*.pl script should at least parse cleanly. We don't run them
# (they may start daemons, sleep, etc); just `perl -c`.
use Cwd qw(abs_path);
use File::Basename qw(dirname);
my $root = dirname(dirname(abs_path(__FILE__)));

my @scripts = glob("$root/eg/*.pl");
plan skip_all => 'no eg/*.pl examples' unless @scripts;

for my $s (@scripts) {
    my $rel = $s;
    $rel =~ s{^\Q$root\E/}{};
    my $out = qx($^X -I$root/blib/lib -I$root/blib/arch -c $s 2>&1);
    my $rc = $?;
    if ($out =~ /Can't locate (\S+\.pm)/) {
        # Missing optional dep (e.g. EV, AnyEvent, OpenGL) — skip, don't fail.
        SKIP: { skip "$rel: missing optional dep $1", 1 }
        next;
    }
    is $rc, 0, "$rel parses cleanly"
        or diag "parse error:\n$out";
}

done_testing;
