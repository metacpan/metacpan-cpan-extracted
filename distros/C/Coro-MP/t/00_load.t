BEGIN { $| = 1; print "1..1\n"; }

my $idx;

for my $module (qw(
   Coro::MP
)) {
   eval "use $module";
   print $@ ? "not " : "", "ok ", ++$idx, " # $module ($@)\n";
}

