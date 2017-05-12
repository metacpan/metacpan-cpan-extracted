use inc::Module::Install;

name                 'Bot-BasicBot-Pluggable-Module-Gitbot';
all_from             'lib/Bot/BasicBot/Pluggable/Module/Gitbot.pm';
author               'Jacob Helwig <jhelwig@cpan.org>';

build_requires 'File::Find::Rule';
build_requires 'File::Find::Rule::Perl';

test_requires 'Directory::Scratch';
test_requires 'Git::Wrapper';
test_requires 'Test::More';
test_requires 'Test::TempDir';

requires 'Bot::BasicBot::Pluggable';
requires 'File::Basename';
requires 'File::Fu';
requires 'File::HomeDir';
requires 'Git';
requires 'MooseX::Declare';
requires 'PPI';
requires 'Text::Pluralize';

homepage   'http://github.com/jhelwig/Bot-BasicBot-Pluggable-Module-Gitbot';
repository 'git://github.com/jhelwig/Bot-BasicBot-Pluggable-Module-Gitbot.git';

readme_markdown_from 'lib/Bot/BasicBot/Pluggable/Module/Gitbot.pm';

auto_provides_class;

WriteAll;
