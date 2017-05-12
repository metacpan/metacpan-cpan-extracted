use inc::Module::Install 0.87;

name     'Catalyst-Helper-AuthDBIC';
all_from 'lib/Catalyst/Helper/AuthDBIC.pm';
author   'Kieren Diment <zarquon@cpan.org>';

build_requires 'Test::More';

build_requires 'Catalyst::Runtime';
build_requires 'ok';
requires 'parent';
requires 'Catalyst::Devel';
requires 'DBIx::Class::EncodedColumn';
requires 'PPI';
requires 'Catalyst::Model::DBIC::Schema' => '0.40';
requires 'DBIx::Class::Schema::Loader'   => '0.05003';
build_requires 'Directory::Scratch';
build_requires 'Test::Command';

# not real deps but the generated bits of app need them.
requires 'Catalyst::Plugin::Authentication';
requires 'Catalyst::Plugin::Authorization::Roles';
requires 'Catalyst::Plugin::Session';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::Session::Store::FastMmap';
requires 'Catalyst::Authentication::Store::DBIx::Class';
requires 'Catalyst::Authentication::Credential::HTTP';

test_requires 'Test::More' => '0.88';

install_script glob('script/*.pl');


auto_install;

resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/Catalyst-Helper-AuthDBIC/trunk/';

WriteAll;

