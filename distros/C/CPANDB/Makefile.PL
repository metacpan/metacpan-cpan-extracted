use inc::Module::Install::DSL 1.06;

all_from       lib/CPANDB.pm
requires_from  lib/CPANDB.pm
requires_from  lib/CPANDB/Distribution.pm
requires_from  script/cpangraph
test_requires  Test::More  0.42
test_requires  LWP::Online 1.07
install_script cpangraph
