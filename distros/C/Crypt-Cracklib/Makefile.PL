use inc::Module::Install;

name('Crypt-Cracklib');
license('perl');
perl_version('5.005');
all_from('Cracklib.pm');

homepage 'https://github.com/dsully/perl-crypt-cracklib';
bugtracker 'https://github.com/dsully/perl-crypt-cracklib/issues';

test_requires 'Test::Pod::Coverage' => '1.08';
test_requires 'Pod::Coverage' => '0.19';
test_requires 'Test::More' => '0.47';

requires_external_cc();

cc_lib_links('crack');
cc_optimize_flags('-g -Wall -Werror');

auto_install();
WriteAll();
