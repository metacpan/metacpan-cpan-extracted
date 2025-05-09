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
);
