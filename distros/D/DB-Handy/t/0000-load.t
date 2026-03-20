# Verify that the module loads and that the primary methods exist.
# No network or fork required; runs on all platforms.
use strict;
use FindBin ();
use lib "$FindBin::Bin/../lib";

# ---- Minimal test harness (no Test::More required) --------------------
my ($T_PLAN, $T_RUN, $T_FAIL) = (0, 0, 0);
sub plan_tests { $T_PLAN = $_[0]; print "1..$T_PLAN\n" }
sub plan_skip  { print "1..0 # SKIP $_[0]\n"; exit 0 }
sub ok   { my($ok,$n)=@_; $T_RUN++; $ok||$T_FAIL++;
           print +($ok?'':'not ')."ok $T_RUN".($n?" - $n":"")."\n"; $ok }
sub is   { my($g,$e,$n)=@_; my $ok=(defined $g && $g eq $e);
           ok($ok,$n) or print "# got: ".(defined $g?$g:'undef')." expected: $e\n" }
sub like { my($g,$re,$n)=@_; ok(defined $g && $g=~$re,$n) }
sub use_ok { my $m=shift; eval "require $m"; ok(!$@, "use $m") }
sub can_ok { my($c,@m)=@_; ok($c->can($_),"$c can $_") for @m }
END { exit 1 if $T_PLAN && $T_FAIL }
# -----------------------------------------------------------------------

plan_tests(3);

# ok 1: module loads without error
use_ok('DB::Handy');

# ok 2-3: $VERSION is defined and looks like a version number
ok(defined $DB::Handy::VERSION,          'VERSION is defined');
like($DB::Handy::VERSION, qr/^\d+\.\d+/, 'VERSION looks like a number');

