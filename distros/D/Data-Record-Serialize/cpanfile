#! perl

requires 'Moo' => 1.004002;
requires 'Hash::Util';
requires 'List::Util' => 1.38;
requires 'Package::Variant';
requires 'Class::Load';
requires 'Types::Standard', 0.042;
recommends 'JSON::Tiny';
recommends 'YAML::Tiny';
recommends 'DBD::SQLite';
requires 'perl',               '5.010001';

on test => sub {

    requires 'Test::More';
    requires 'Test::Fatal';
    requires 'File::Temp';
    requires 'Class::Load';
};

on develop => sub {
    requires 'Module::Install';
    requires 'Module::Install::CPANfile';
};
