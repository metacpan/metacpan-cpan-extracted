use ExtUtils::MakeMaker 6.64;

WriteMakefile(
    NAME              => 'Amazon::Sites',
    VERSION_FROM      => 'lib/Amazon/Sites.pm',
    MIN_PERL_VERSION  => '5.26.0',
    PREREQ_PM         => {
        Feature::Compat::Class => 0.04,
    },
    TEST_REQUIRES => {
        Test::More => 0,
        Test::Exception => 0,
    },
    BUILD_REQUIRES    => {
        Test::More    => 0,
        Test::Exception => 0,
    },
    ABSTRACT_FROM     => 'lib/Amazon/Sites.pm',
    AUTHOR            => 'Dave Cross <dave@perlhacks.com>',
    LICENSE           => 'perl',
    META_MERGE        => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/davorg-cpan/amazon-sites.git',
                web => 'https://github.com/davorg-cpan/amazon-sites',
            },
            bugtracker => {
                "web" => "https://github.com/davorg-cpan/amazon-sites/issues"
            }
        },
    },
);
