use inc::Module::Install::DSL 0.85;

all_from       lib/CGI/Capture.pm
requires_from  lib/CGI/Capture.pm
test_requires  File::Spec   0.80
test_requires  Test::More   0.47
test_requires  Test::Script 1.02
install_script cgicapture
