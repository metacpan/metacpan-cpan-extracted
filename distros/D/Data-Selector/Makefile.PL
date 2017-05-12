use inc::Module::Install;

all_from 'lib/Data/Selector.pm';

recursive_author_tests( 'xt' );

WriteAll;
