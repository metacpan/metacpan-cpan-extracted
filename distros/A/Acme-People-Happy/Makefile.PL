# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Does people happy?';
author 'Michal Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.07;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Acme-People-Happy';
readme_from 'Happy.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.05;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Acme-People-Happy';
resources 'homepage' => 'https://github.com/tupinek/Acme-People-Happy';
resources 'repository' => 'git://github.com/tupinek/Acme-People-Happy';
test_requires 'English' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.03';

# Run.
WriteAll();
