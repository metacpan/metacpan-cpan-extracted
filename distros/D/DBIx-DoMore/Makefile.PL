sub author_tests    { }
sub author_requires { }
sub readme_from     { }

use inc::Module::Install;

my $main_module = 'lib/DBIx/DoMore.pm';

name          'DBIx-DoMore';
abstract_from $main_module;
version_from  $main_module;
readme_from   $main_module;
author        q{Emanuele Zeppieri <emazep@cpan.org>};
license       'perl';

requires 'Moose';
requires 'SQL::Tokenizer';

test_requires 'DBD::SQLite';
test_requires 'DBI';
test_requires 'Test::More';

author_requires 'Test::Pod' => '1.14';
author_requires 'Test::Pod::Coverage' => '1.08';
author_requires 'Module::Install::ReadmeFromPod';
author_requires 'Test::CheckManifest';

tests 't/*.t';

author_tests 'xt';

WriteAll;
