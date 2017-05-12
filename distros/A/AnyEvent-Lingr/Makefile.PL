use inc::Module::Install;

name 'AnyEvent-Lingr';
all_from 'lib/AnyEvent/Lingr.pm';

no_index directory => 'eg';

cpanfile;

author_tests 'xt';

WriteAll;
