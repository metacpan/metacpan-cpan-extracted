use inc::Module::Install::DSL 1.06;

abstract      Prebuilt timing, profiling and benchmarking aspects
all_from      lib/Aspect/Library/Timer.pm
requires_from lib/Aspect/Library/ZoneTimer.pm
test_requires Test::More 0.47
