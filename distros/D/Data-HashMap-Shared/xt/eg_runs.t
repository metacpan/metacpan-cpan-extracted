use strict;
use warnings;
use Test::More;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# Every eg/*.pl script should at least parse cleanly (`perl -c`); the fast,
# self-contained ones (unique /tmp paths, no sleep) are also actually run and
# checked for a clean exit -- catching runtime breakage that `perl -c` misses.
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

# Actually run the fast, self-contained examples (each uses a $$-unique /tmp
# path and terminates quickly) and assert a clean exit.
for my $name (qw(leaderboard memoize sharded_counter feature_flags)) {
    my $script = "$root/eg/$name.pl";
    unless (-f $script) { fail("eg/$name.pl exists"); next; }
    my $out = qx($^X -I$root/blib/lib -I$root/blib/arch $script 2>&1);
    is $?, 0, "eg/$name.pl runs cleanly (exit 0)"
        or diag "runtime error:\n$out";
}

done_testing;
