requires 'Const::Fast';
requires 'Encode';
requires 'HTML::AutoTag';
requires 'HTML::Entities';
requires 'Ref::Util';
requires 'YAML::Syck';
requires 'perl', '5.010';
requires 'version', '0.77';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'FindBin::libs';
    requires 'Test::More', '0.98';
    requires 'Test::More::UTF8';
};
