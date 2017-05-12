use inc::Module::Install;

name 'Data-OpenGraph';
all_from 'lib/Data/OpenGraph.pm';

requires 'HTML::Parser', 3;
tests "t/*.t";

WriteAll;