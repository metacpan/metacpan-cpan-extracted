requires 'At';
requires 'HTTP::Tiny';
requires 'Mozilla::CA';
requires 'Path::Tiny';
requires 'URI';
requires 'URI::QueryParam';
requires 'perl', 'v5.42.0';
recommends 'Mojo::UserAgent';
on configure => sub {
    requires 'Module::Build::Tiny';
};
on test => sub {
    requires 'Test2::V0';
};
on develop => sub {
    requires 'CPAN::Uploader';
    requires 'Minilla';
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
