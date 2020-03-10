use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'We are Slovak CPAN authors.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Acme-CPANAuthors-Slovak';
perl_version 5.0100;
readme_from 'Slovak.pm';
recursive_author_tests('xt');
requires 'Acme::CPANAuthors' => 0;
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Acme-CPANAuthors-Slovak';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Acme-CPANAuthors-Slovak';
resources 'repository' => 'git://github.com/michal-josef-spacek/Acme-CPANAuthors-Slovak';
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::More' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
