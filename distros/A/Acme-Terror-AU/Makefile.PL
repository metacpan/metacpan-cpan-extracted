use inc::Module::Install;

name           'Acme-Terror-AU';
perl_version   '5.005';
all_from       'lib/Acme/Terror/AU.pm';
build_requires 'File::Spec' => '0.80';
build_requires 'Test::More' => '0.47';

WriteAll;
