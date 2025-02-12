use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Data objects for info box.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Data-InfoBox';
perl_version 5.008;
readme_from 'lib/Data/InfoBox.pm';
recursive_author_tests('xt');
requires 'Data::Icon' => 0;
requires 'Data::InfoBox' => 0;
requires 'Data::InfoBox::Item' => 0.03;
requires 'Data::Text::Simple' => 0;
requires 'Mo' => 0;
requires 'Mo::utils' => 0.21;
requires 'Mo::utils::URI' => 0.02;
requires 'Unicode::UTF8' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Data-InfoBox/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Data-InfoBox';
resources 'repository' => 'git://github.com/michal-josef-spacek/Data-InfoBox';
test_requires 'Data::Icon' => 0;
test_requires 'Data::Text::Simple' => 0;
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Unicode::UTF8' => 0;
tests_recursive;
version '0.04';

# Run.
WriteAll();
