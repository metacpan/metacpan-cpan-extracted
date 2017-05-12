use inc::Module::Install::DSL 1.00;

all_from       lib/CPAN/WWW/Top100/Generator.pm
requires_from  lib/CPAN/WWW/Top100/Generator.pm
test_requires  Test::More   0.42
test_requires  Test::Script 1.03
test_requires  File::Remove 1.42
install_script cpantop100
