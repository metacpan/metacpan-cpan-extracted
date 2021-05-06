use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share 'share';

WriteMakefile(
    NAME              => 'App::CPANModuleSite',
    VERSION_FROM      => 'lib/App/CPANModuleSite.pm',
    MIN_PERL_VERSION  => '5.14.0',
    EXE_FILES         => [ 'bin/mksite' ],
    PREREQ_PM         => {
        Moose                        => 0,
	MetaCPAN::Client             => 2.0,
	Template	             => 0,
	Path::Iterator::Rule         => 0,
	Moose::Util::TypeConstraints => 0,
	File::ShareDir               => 0,
    },
    BUILD_REQUIRES    => {
        Test::More              => 0,
    },
    CONFIGURE_REQUIRES => {
        File::ShareDir::Install => 0,
    },
    ABSTRACT_FROM     => 'lib/App/CPANModuleSite.pm',
    AUTHOR            => 'Dave Cross <dave@perlhacks.com>',
    LICENSE           => 'perl',
    META_MERGE        => {
        'meta-spec' => { version => 2 },
        resources => {
                      repository => {
                           type => 'git',
                           url => 'git://github.com/davorg/app-cpanmodulesite.git',
                           web => 'https://github.com/davorg/app-cpanmodulesite',
                          },
                      bugtracker => {
                                     "web" => "https://github.com/davorg/app-cpanmodulesite/issues"
                                    }
        },
    },
);

package MY;
use File::ShareDir::Install qw(postamble);
