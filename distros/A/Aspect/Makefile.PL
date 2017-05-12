use inc::Module::Install::DSL 1.06;

all_from      lib/Aspect.pm
requires_from lib/Aspect.pm
requires      Task::Weaken     1.00
test_requires Test::More       0.70
test_requires Test::Exception  0.29
test_requires Test::NoWarnings 0.084
