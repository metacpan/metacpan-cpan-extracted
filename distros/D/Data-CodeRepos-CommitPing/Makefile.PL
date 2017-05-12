use inc::Module::Install;
name 'Data-CodeRepos-CommitPing';
all_from 'lib/Data/CodeRepos/CommitPing.pm';

requires $_ for (qw/
    DateTime
    DateTime::Format::HTTP
    YAML
/);

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
