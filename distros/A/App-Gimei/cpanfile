requires 'perl', 'v5.40.0';

requires 'Class::Tiny',  '== 1.008';
requires 'Data::Gimei',  '== v0.4.5';
requires 'Getopt::Long', '== 2.58';
requires 'Pod::Find',    '== 1.67';
requires 'Pod::Usage',   '== 2.05';
requires 'Pod::Text',    '== v6.0.2';

on configure => sub {
    requires 'Module::Build::Tiny', '== 0.052';
};

on develop => sub {
    requires 'Spellunker',                 '== v0.4.0';
    requires 'CPAN::Uploader',             '== 0.103018';
    requires 'Minilla',                    '== v3.1.29';
    requires 'Perl::Tidy',                 '== 20260109';
    requires 'Software::License',          '== 0.104007';
    requires 'Test::CPAN::Meta',           '== 0.25';
    requires 'Test::MinimumVersion::Fast', '== 0.04';
    requires 'Test::PAUSE::Permissions',   '== 0.07';
    requires 'Test::Pod',                  '== 1.52';
    requires 'Test::Spellunker',           '== v0.4.0';
    requires 'Version::Next',              '== 1.000';
};

on 'test' => sub {
    requires 'Capture::Tiny',       '== 0.50';
    requires 'Test2::Bundle::More', '== 1.302219';
    requires 'Capture::Tiny',       '== 0.50';
};
