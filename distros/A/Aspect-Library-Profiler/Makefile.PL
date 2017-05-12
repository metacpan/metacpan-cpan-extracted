use inc::Module::Install::DSL 1.01;

all_from      lib/Aspect/Library/Profiler.pm
requires_from lib/Aspect/Library/Profiler.pm
test_requires Test::More       0.42
test_requires Test::NoWarnings 0.084
test_requires File::Spec       0.80
test_requires IPC::Run3        0.042
