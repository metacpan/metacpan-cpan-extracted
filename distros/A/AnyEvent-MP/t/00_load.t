BEGIN { $| = 1; print "1..7\n"; }

my $idx;

for my $module (qw(
   AnyEvent::MP::Config
   AnyEvent::MP::Transport
   AnyEvent::MP::Node
   AnyEvent::MP::Kernel
   AnyEvent::MP
   AnyEvent::MP::Global
   AnyEvent::MP::LogCatcher
)) {
   eval "use $module";
   warn "$idx $@" if $@;
   print $@ ? "not " : "", "ok ", ++$idx, " # $module ($@)\n";
}

