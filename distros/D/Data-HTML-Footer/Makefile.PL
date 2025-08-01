use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Data object for HTML footer.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Data-HTML-Footer';
perl_version 5.008;
readme_from 'Footer.pm';
recursive_author_tests('xt');
requires 'Mo' => 0;
requires 'Mo::utils::CSS' => 0.07;
requires 'Mo::utils::URI' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Data-HTML-Footer/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Data-HTML-Footer';
resources 'repository' => 'git://github.com/michal-josef-spacek/Data-HTML-Footer';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
