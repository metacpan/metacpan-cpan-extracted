use inc::Module::Install;
name 'Catalyst-Model-MultiAdaptor';
all_from 'lib/Catalyst/Model/MultiAdaptor.pm';

requires $_
    for (
    qw/
    Sub::Install
    Class::MOP
    MRO::Compat
    Module::Pluggable::Object
    Moose
    Class::C3 
    /
    );

build_requires $_
    for (
    qw/
    Test::More
    Catalyst::Test
    Test::WWW::Mechanize::Catalyst
    Catalyst
    Catalyst::Controller
    /
    );
use_test_base;
auto_include;
WriteAll;
