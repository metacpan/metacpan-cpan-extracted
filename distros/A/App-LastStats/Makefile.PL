use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'App::LastStats',
    VERSION_FROM => 'lib/App/LastStats.pm',
    ABSTRACT_FROM => 'lib/App/LastStats.pm',
    AUTHOR       => 'Dave Cross <dave@perlhacks.com>',
    LICENSE      => 'perl',
    MIN_PERL_VERSION  => '5.26.0',
    PREREQ_PM    => {
        'Net::LastFM' => 0,
        'Getopt::Long' => 0,
        'JSON' => 0,
        'Feature::Compat::Class' => 0,
    },
    META_MERGE        => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/davorg-cpan/app-laststats.git',
                web => 'https://github.com/davorg-cpan/app-laststats',
            },
            bugtracker => {
                "web" => "https://github.com/davorg-cpan/app-laststats/issues"
            }
        },
    },
);
