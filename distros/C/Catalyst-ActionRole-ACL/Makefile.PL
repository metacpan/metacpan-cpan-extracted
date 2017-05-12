use inc::Module::Install 0.91;

name 'Catalyst-ActionRole-ACL';
all_from 'lib/Catalyst/ActionRole/ACL.pm';

requires 'Catalyst::Runtime' => '5.90013';
requires 'Moose';
requires 'Catalyst::Controller::ActionRole';
requires 'namespace::autoclean';

test_requires 'Test::More';

resources repository => 'git://github.com/bobtfish/catalyst-actionrole-acl.git';

WriteAll();

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Catalyst/ActionRole/ACL.pm > README");
}

