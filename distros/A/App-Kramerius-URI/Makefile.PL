use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Base class and script for creating of Kramerius URI.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/kramerius-uri';
license 'bsd';
name 'App-Kramerius-URI';
perl_version 5.006;
readme_from 'bin/kramerius-uri';
recursive_author_tests('xt');
requires 'Data::Kramerius' => 0;
requires 'Getopt::Std' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-Kramerius-URI/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-Kramerius-URI';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-Kramerius-URI';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 0;
tests_recursive;
version '0.03';

# Run.
WriteAll();
