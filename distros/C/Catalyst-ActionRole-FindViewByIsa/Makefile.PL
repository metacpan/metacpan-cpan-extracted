use inc::Module::Install 0.91;

name 'Catalyst-ActionRole-FindViewByIsa';
all_from 'lib/Catalyst/ActionRole/FindViewByIsa.pm';
license 'perl';

requires 'Moose::Role';
requires 'namespace::autoclean';

test_requires 'Catalyst::Runtime' => '5.80';
test_requires 'Catalyst::Controller::ActionRole';
test_requires 'Catalyst::Action::RenderView';
test_requires 'Test::More';

resources repository => 'http://github.com/bobtfish/catalyst-actionrole-findviewbyisa';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Catalyst/ActionRole/FindViewByIsa.pm > README") and die;
}

WriteAll;

