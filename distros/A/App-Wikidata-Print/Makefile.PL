use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Command line tool for print Wikidata item.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/wd-print';
license 'bsd';
name 'App-Wikidata-Print';
readme_from 'bin/wd-print';
recursive_author_tests('xt');
requires 'Class::Utils' => 0;
requires 'English' => 0;
requires 'Getopt::Std' => 0;
requires 'Unicode::UTF8' => 0;
requires 'Wikibase::API' => 0.04;
requires 'Wikibase::Datatype::Print' => 0.17;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-Wikidata-Print/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-Wikidata-Print';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-Wikidata-Print';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'File::Object' => 0;
test_requires 'File::Spec::Functions' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 0;
tests_recursive;
version '0.05';

# Run.
WriteAll();
