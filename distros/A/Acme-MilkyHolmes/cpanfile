requires 'Data::Section::Simple';
requires 'Encode';
requires 'Localizer::Resource';
requires 'Localizer::Style::Gettext';
requires 'Mouse';
requires 'Mouse::Role';
requires 'Readonly';
requires 'YAML::Tiny';
requires 'parent';
requires 'perl', '5.008005';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on test => sub {
    requires 'Test::More', '0.98';
    requires 'Test::MockTime';
};
