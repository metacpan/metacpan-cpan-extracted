requires 'Bluesky', '1.01';
requires 'File::HomeDir';
requires 'Getopt::Long';
requires 'JSON::Tiny';
requires 'Path::Tiny';
requires 'Pod::Text::Color';
requires 'Term::ANSIColor';
requires 'perl', 'v5.38.0';
recommends 'Win32::Console';
on configure => sub {
    requires 'Module::Build::Tiny';
};
on test => sub {
    requires 'Capture::Tiny';
    requires 'Test2::V0';
};
on develop => sub {
    requires 'CPAN::Uploader';
    requires 'Pod::Markdown::Github';
    requires 'Software::License::Artistic_2_0';
    requires 'Test::CPAN::Meta';
    requires 'Test::MinimumVersion::Fast', '0.04';
    requires 'Test::PAUSE::Permissions',   '0.07';
    requires 'Test::Pod',                  '1.41';
    requires 'Test::Spellunker',           'v0.2.7';
    requires 'Version::Next';
    recommends 'Code::TidyAll';
    recommends 'Code::TidyAll::Plugin::PodTidy';
    recommends 'Data::Dump';
    recommends 'Perl::Tidy';
    recommends 'Pod::Tidy';
    recommends 'Test::CPAN::Meta';
    recommends 'Test::MinimumVersion::Fast';
    recommends 'Test::PAUSE::Permissions';
    recommends 'Test::Pod';
    recommends 'Test::Spellunker';
};
