use inc::Module::Install::DSL 1.00;

all_from      lib/Archive/Builder.pm
requires_from lib/Archive/Builder.pm
requires      File::Flat   1.00
requires      IO::Zlib     0
requires      Archive::Zip 1.18
requires      Archive::Tar 1.30
test_requires Test::More   0.47
