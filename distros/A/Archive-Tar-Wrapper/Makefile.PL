use warnings;
use strict;
use ExtUtils::MakeMaker;

my $meta_merge = {
    META_MERGE => {
        resources => {
            type => 'git',
            url  => 'https://github.com/glasswalk3r/archive-tar-wrapper-perl',
            repository =>
              'https://github.com/glasswalk3r/archive-tar-wrapper-perl.git',
            bugtracker =>
              'https://github.com/glasswalk3r/archive-tar-wrapper-perl/issues'
        },
    }
};

WriteMakefile(
    'NAME'             => 'Archive::Tar::Wrapper',
    'VERSION_FROM'     => 'lib/Archive/Tar/Wrapper.pm',
    'MIN_PERL_VERSION' => 5.008001,
    'PREREQ_PM'        => {
        'File::Temp'    => 0,
        'Cwd'           => 0,
        'Log::Log4perl' => 0,
        'IPC::Run'      => 0,
        'File::Which'   => 0,
        'Test::Simple'  => 1.302073 # default for perl 5.8.9,
                                    # we require Test::More::is_deeply
    },
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM => 'lib/Archive/Tar/Wrapper.pm',
            AUTHOR        => [
                'Mike Schilli <cpan@perlmeister.com>',
                'Alceu Rodrigues de Freitas Junior <arfreitas@cpan.org>'
            ]
          )
        : ()
    ),
    $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ( 'LICENSE' => 'gpl' ) : ()
);
