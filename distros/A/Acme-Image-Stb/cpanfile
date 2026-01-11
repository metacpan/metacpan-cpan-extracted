requires 'Affix', 'v1.0.3';
requires 'perl', 'v5.40.0';

on configure => sub {
    requires 'Affix::Build', 'v1.0.3';
    requires 'HTTP::Tiny';
    requires 'Module::Build', '0.4005';
    requires 'Path::Tiny';
};

on test => sub {
    requires 'Test2::V0';
};

on develop => sub {
    requires 'Test::CPAN::Meta';
    requires 'Test::MinimumVersion::Fast', '0.04';
    requires 'Test::PAUSE::Permissions', '0.07';
    requires 'Test::Pod', '1.41';
    requires 'Test::Spellunker', 'v0.2.7';
};
