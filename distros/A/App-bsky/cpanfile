requires 'perl', '5.038000';    # class syntax
requires 'At',   '0.17';
requires 'Getopt::Long';
requires 'Pod::Text::Color';
requires 'Path::Tiny';
requires 'File::HomeDir';
requires 'JSON::Tiny';
requires 'Term::ANSIColor';
on 'test' => sub {
    requires 'Test2::V0';        # core as of 5.39.x
    requires 'Capture::Tiny';    # check wrap in say/err
};
on 'develop' => sub {
    requires 'Software::License::Artistic_2_0';
    recommends 'Perl::Tidy';
    recommends 'Pod::Tidy';
    recommends 'Code::TidyAll::Plugin::PodTidy';
    recommends 'Code::TidyAll';
    requires 'Pod::Markdown::Github';
    recommends 'Test::Pod';
    recommends 'Test::PAUSE::Permissions';
    recommends 'Test::MinimumVersion::Fast';
    recommends 'Test::CPAN::Meta';
    recommends 'Test::Spellunker';
    requires 'Minilla';
    recommends 'Data::Dump';
    requires 'Version::Next';
    requires 'CPAN::Uploader';
};
