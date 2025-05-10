use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'App::FeedDeduplicator',
    VERSION_FROM => 'lib/App/FeedDeduplicator.pm',
    LICENSE      => 'perl',
    EXE_FILES    => ['bin/feed-deduplicator'],
    PREREQ_PM    => {
        'XML::Feed'            => 0,
        'LWP::UserAgent'       => 0,
        'HTML::TreeBuilder::XPath' => 0,
        'JSON::MaybeXS'        => 0,
        'File::HomeDir'        => 0,
        'File::Spec'           => 0,
        'Getopt::Long'         => 0,
    },
    MIN_PERL_VERSION => 5.040,
    META_MERGE    => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/davorg-cpan/app-feeddeduplicator.git',
                web  => 'https://github.com/davorg-cpan/app-feeddeduplicator',
            },
            bugtracker => {
                web  => 'https://github.com/davorg-cpan/app-feeddeduplicator/issues',
            },
        },
    },
);
