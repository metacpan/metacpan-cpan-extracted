requires 'perl', 'v5.42.0';

requires 'Data::Gimei', '== v0.5.0';
requires 'Pod::Find',   '== 1.67';

on configure => sub {
    requires 'Module::Build::Tiny', '== 0.053';
};

on develop => sub {
    requires 'Spellunker',                 '== v0.4.0';
    requires 'CPAN::Uploader',             '== 0.103019';
    requires 'Minilla',                    '== v3.3.0';
    requires 'Perl::Tidy',                 '== 20260826';
    requires 'Software::License',          '== 0.104007';
    requires 'Test::CPAN::Meta',           '== 0.25';
    requires 'Module::CPANfile',           '== 1.1004';
    requires 'Test::MinimumVersion::Fast', '== 0.04';
    requires 'Test::PAUSE::Permissions',   '== 0.07';
    requires 'Test::Pod',                  '== 1.52';
    requires 'Test::Spellunker',           '== v0.4.0';
    requires 'Version::Next',              '== 1.000';

    requires 'Reply',               '== 0.42';
    requires 'Term::ReadLine::Gnu', '== 1.47';
};

on 'test' => sub {
    requires 'Capture::Tiny', '== 0.50';
    requires 'Test2::V1',     '== 1.302225';
};
