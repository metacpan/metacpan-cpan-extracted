use inc::Module::Install::DSL 1.06;

all_from      lib/ADAMK/Release.pm
requires_from lib/ADAMK/Release.pm
requires      Getopt::Long         2.33
requires      Perl::MinimumVersion 1.27
requires      Test::MinimumVersion 0.101080
requires      Test::Pod            1.44
test_requires Test::More           0.42
test_requires Test::Script         1.07
install_script adamk-release
install_share
