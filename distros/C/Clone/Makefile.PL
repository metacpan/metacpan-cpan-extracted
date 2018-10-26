use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Clone',
    'AUTHOR'        => 'Ray Finch <rdf@cpan.org>',
    'VERSION_FROM'  => 'Clone.pm',
    'ABSTRACT_FROM' => 'Clone.pm',
    'LICENSE'       => 'perl',
    'PL_FILES'      => {},
    'BUILD_REQUIRES' => {
      'Test::More' => 0,
    },
    'LIBS'          => [''],     # e.g., '-lm'
    'DEFINE'        => '',       # e.g., '-DHAVE_SOMETHING'
    'INC'           => '',       # e.g., '-I/usr/include/other'
#   'OPTIMIZE'      => '-g',     # e.g., '-I/usr/include/other'
    'OPTIMIZE'      => '-O3',    # e.g., '-I/usr/include/other'
    clean           => { FILES => '_Inline' },
    META_MERGE      => {
      resources => {
        license    => 'http://dev.perl.org/licenses/',
        bugtracker => 'https://github.com/garu/Clone/issues',
        repository => 'http://github.com/garu/Clone',
      },
    },
);

