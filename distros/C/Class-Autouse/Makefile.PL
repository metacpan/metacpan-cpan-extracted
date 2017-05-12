use inc::Module::Install::DSL 1.04;

all_from      lib/Class/Autouse.pm
requires_from lib/Class/Autouse.pm
test_requires Test::More 0.47
test_requires File::Temp 0.17
