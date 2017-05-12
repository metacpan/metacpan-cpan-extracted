use inc::Module::Install::DSL 1.04;

all_from      lib/Business/AU/ABN.pm
requires_from lib/Business/AU/ABN.pm
test_requires File::Spec   0.80
test_requires Test::More   0.47
