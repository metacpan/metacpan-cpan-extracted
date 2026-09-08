requires 'Alien::Build', '2.84';
requires 'Alien::Xmake', 'v1.0.0';
requires 'Alien::Xrepo', 'v1.0.0';
requires 'Path::Tiny';
requires 'perl', 'v5.40.0';
on configure => sub {
    requires 'Alien::Xrepo', 'v1.0.0';
    requires 'perl',         'v5.40.0';
};
on build => sub {
    requires 'Alien::Build', '2.84';
    requires 'Alien::Xrepo', 'v1.0.0';
    requires 'perl',         'v5.40.0';
};
on test => sub {
    requires 'Capture::Tiny';
    requires 'File::Temp';
    requires 'Test2::V0';
    requires 'Test::Alien';
    requires 'Test::Alien::Build';
    recommends 'Affix';
    recommends 'FFI::Platypus';
};
on develop => sub {
    requires 'CPAN::Uploader';
    requires 'Code::TidyAll';
    requires 'Code::TidyAll::Plugin::PodTidy';
    requires 'IO::Socket::SSL';
    requires 'Minilla';
    requires 'Perl::Tidy';
    requires 'Pod::Markdown::Github';
    requires 'Pod::Tidy';
    requires 'Software::License::Artistic_2_0';
    requires 'Test::CPAN::Meta';
    requires 'Test::MinimumVersion::Fast', '0.04';
    requires 'Test::PAUSE::Permissions',   '0.07';
    requires 'Test::Pod',                  '1.41';
    requires 'Test::Spellunker',           'v0.2.7';
    requires 'Version::Next';
};
