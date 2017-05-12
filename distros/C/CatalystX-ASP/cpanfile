requires 'Carp';
requires 'Catalyst', '5.90090';
requires 'Digest::MD5';
requires 'File::Slurp';
requires 'HTML::Entities';
requires 'HTTP::Date';
requires 'List::Util';
requires 'Module::Runtime';
requires 'Moose';
requires 'MooseX::Types::Path::Tiny';
requires 'Path::Tiny';
requires 'Scalar::Util';
requires 'Text::SimpleTable';
requires 'Tie::Handle';
requires 'Tie::Hash';
requires 'Try::Tiny';
requires 'URI';
requires 'URI::Escape';
requires 'namespace::autoclean';
requires 'namespace::clean';
requires 'parent';
requires 'perl', '5.010';

on build => sub {
    requires 'Catalyst::Plugin::Session';
    requires 'Catalyst::Plugin::Session::State::Cookie';
    requires 'Catalyst::Plugin::Session::Store::File';
    requires 'DateTime';
    requires 'ExtUtils::MakeMaker', '6.59';
    requires 'File::Temp';
    requires 'HTTP::Headers';
    requires 'Test::Exception';
    requires 'Test::More';
    requires 'Text::Lorem';
};

on develop => sub {
    requires 'Pod::Coverage::TrustPod';
    requires 'Test::CPAN::Meta';
    requires 'Test::Kwalitee::Extra';
    requires 'Test::MinimumVersion::Fast', '0.04';
    requires 'Test::PAUSE::Permissions', '0.04';
    requires 'Test::Pod', '1.41';
    requires 'Test::Spellunker', 'v0.2.7';
};
