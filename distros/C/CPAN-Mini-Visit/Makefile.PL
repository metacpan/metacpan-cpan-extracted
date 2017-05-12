use inc::Module::Install::DSL 1.06;

all_from      lib/CPAN/Mini/Visit.pm
requires_from lib/CPAN/Mini/Visit.pm
requires      Archive::Tar     1.52
requires      Locale::Maketext 1.19
test_requires Test::More       0.86
test_requires Test::NoWarnings 0.084
