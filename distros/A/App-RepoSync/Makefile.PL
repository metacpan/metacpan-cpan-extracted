use inc::Module::Install;
name 'App-RepoSync';
all_from 'lib/App/RepoSync.pm';

requires map { $_ => 0 } qw(CLI::Framework File::Basename File::Spec YAML JSON Cwd Try::Tiny);
tests 't/*.t';
install_script 'scripts/repo';
readme_markdown_from_pod 'lib/App/RepoSync.pm';
# author_tests 'xt';
# test_requires 'Test::More';
# auto_set_repository;
auto_include;
WriteAll;
