use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share 'src';

WriteMakefile(
    NAME         => 'App::LinkSite',
    VERSION_FROM => 'lib/App/LinkSite.pm',
    ABSTRACT_FROM => 'lib/App/LinkSite.pm',
    AUTHOR       => 'Dave Cross <dave@perlhacks.com>',
    LICENSE      => 'perl',
    MIN_PERL_VERSION  => '5.26.0',
    CONFIGURE_REQUIRES => {
        File::ShareDir::Install => 0,
    },
    PREREQ_PM    => {
        'JSON' => 0,
        'Template' => 0,
        'JSON' => 0,
        'Path::Tiny' => 0,
        'File::Find' => 0,
        'File::ShareDir' => 0,
        'FindBin' => 0,
        'Feature::Compat::Class' => 0.06,
        ($^V < v5.38 ? ('Object::Pad' => 0) : ()),
    },
    EXE_FILES    => [ 'bin/linksite' ],
    META_MERGE        => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/davorg-cpan/app-linksite.git',
                web => 'https://github.com/davorg-cpan/app-linksite',
            },
            bugtracker => {
                "web" => "https://github.com/davorg-cpan/app-linksite/issues"
            }
        },
    },
);
