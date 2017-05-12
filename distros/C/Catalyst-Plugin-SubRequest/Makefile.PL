use inc::Module::Install 0.91;

name 'Catalyst-Plugin-SubRequest';
all_from 'lib/Catalyst/Plugin/SubRequest.pm';

requires 'Catalyst::Runtime' => '5.9';
requires 'Test::More';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Catalyst/Plugin/SubRequest.pm > README");
}

resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/trunk/Catalyst-Plugin-SubRequest/';

WriteAll;
