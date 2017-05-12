use inc::Module::Install::DSL 0.88;

all_from       lib/CPANTS/Weight.pm
requires_from  lib/CPANTS/Weight.pm
test_requires  Test::More   0.42
test_requires  Test::Script 1.03
install_script cpants-weight
install_share
