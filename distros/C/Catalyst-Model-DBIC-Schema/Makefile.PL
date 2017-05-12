use inc::Module::Install 0.91;

name 'Catalyst-Model-DBIC-Schema';
perl_version 5.008001;
all_from 'lib/Catalyst/Model/DBIC/Schema.pm';

requires 'DBIx::Class'           => '0.08114';
requires 'Catalyst::Runtime'     => '5.80005';
requires 'CatalystX::Component::Traits' => '0.14';

requires 'Moose' => '1.12';
requires 'MooseX::MarkAsMethods' => '0.13';
requires 'MooseX::Types';
requires 'MooseX::Types::LoadableClass' => 0.009;
requires 'Module::Runtime' => '0.012';
requires 'namespace::autoclean' => 0.09;
requires 'Carp::Clan';
requires 'List::MoreUtils';
requires 'Tie::IxHash';
requires 'Try::Tiny';
requires 'Catalyst::Component::InstancePerContext';


test_requires 'Test::More' => '0.94';
test_requires 'Test::Exception';
test_requires 'Storable';
test_requires 'Test::Requires';
test_requires 'DBD::SQLite';

feature 'Catalyst::Helper support',
    -default                      => 0,
    'Catalyst::Devel'             => '1.0',
    'DBIx::Class::Schema::Loader' => '0.04005',
    'MooseX::NonMoose'            => '0.16',
;

feature 'Caching support',
    -default                      => 0,
    'DBIx::Class::Cursor::Cached' => 0;

feature 'Replication support',
    -default                   => 0,
    'namespace::clean'         => 0,
    'Hash::Merge'              => 0;

if(-e 'MANIFEST.SKIP') {
    system("pod2text lib/Catalyst/Model/DBIC/Schema.pm > README");
}

realclean_files 'README';

auto_provides;
auto_install;

resources repository =>
    'git://git.shadowcat.co.uk/catagits/Catalyst-Model-DBIC-Schema.git';

WriteAll;
