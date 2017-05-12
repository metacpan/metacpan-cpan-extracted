use inc::Module::Install;
all_from 'lib/CPAN/Test/Dummy/MultiPkgVer.pm';
readme_from('lib/CPAN/Test/Dummy/MultiPkgVer.pm');
build_requires 'Test::More', 0.88;
test_requires 'Test::Requires';
auto_set_repository();
resources
  homepage      => "https://github.com/miyagawa/CPAN-Test-Dummy-MultiPkgVer",
  bugtracker    => "https://github.com/miyagawa/CPAN-Test-Dummy-MultiPkgVer/issues";
auto_provides;
WriteAll;
