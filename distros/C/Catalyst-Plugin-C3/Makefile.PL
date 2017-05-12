use inc::Module::Install 0.65;

name 'Catalyst-Plugin-C3';
all_from 'lib/Catalyst/Plugin/C3.pm';

requires      'Catalyst'      => '5.7006';
requires      'Class::C3'     => '0.19';
requires      'NEXT'          => '0.6';
test_requires 'Test::More'    => 0.47;

if(-e 'MANIFEST.SKIP') {
    system("pod2text lib/Catalyst/Plugin/C3.pm > README");
}

auto_provides;
auto_install;
WriteAll;
