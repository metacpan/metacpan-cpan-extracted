BEGIN { $| = 1; print "1..17\n"; }

my $idx;

for my $module (qw(
   Coro::State
   Coro
   Coro::MakeMaker

   Coro::Signal
   Coro::Semaphore
   Coro::SemaphoreSet
   Coro::Channel
   Coro::Specific
   Coro::RWLock

   Coro::AnyEvent
   Coro::Timer
   Coro::Util
   Coro::Select
   Coro::Handle
   Coro::Socket

   Coro::Storable
   Coro::Debug
)) {
   eval "use $module";
   print $@ ? "not " : "", "ok ", ++$idx, " # $module ($@)\n";
}

