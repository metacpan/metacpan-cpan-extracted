use strict;
use inc::Module::Install;

name     'Apache2-TrapSubRequest';
abstract 'Trap the result of a subrequest into a scalar.';
all_from 'lib/Apache2/TrapSubRequest.pm';
author   q{Dorian Taylor <dorian@cpan.org>};
license  'apache';

requires mod_perl2 => 1.999023;

build_requires 'Test::More';
build_requires 'Apache::Test';


clean_files 't/TEST t/SMOKE';

require Apache::TestMM;
Apache::TestMM->import(qw(test clean));

Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');

auto_install;

WriteAll;
