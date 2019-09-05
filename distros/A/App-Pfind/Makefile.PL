use 5.018;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'App::Pfind',
    AUTHOR           => q{Mathias Kende <mathias@cpan.org>},
    VERSION_FROM     => 'lib/App/Pfind.pm',
    ABSTRACT         => 'A Perl based find replacement',
    LICENSE          => 'mit',
    EXE_FILES        => ['script/pfind'],
    MIN_PERL_VERSION => '5.022',
    MAN3PODS         => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
    },
    PREREQ_PM => {
        'Data::Dumper'          => 0,
        'Fcntl'                 => 0,
        'File::Copy'            => 0,
        'File::Find'            => 0,
        'File::Spec::Functions' => 0,
        'File::Path'            => 0,
        'Getopt::Long'          => 0,
        'Pod::Usage'            => 0,
        'Safe'                  => 0,
    },
    NO_MYMETA => 1,
    META_MERGE => {
      'meta-spec' => { version => 2 },
      # Goes with NO_MYMETA (which would provide the dynamic config).
      dynamic_config => 0,
      no_index => {
        # Ignores child of App::Pfind, but not App::Pfind itself. That package
        # must be indexable otherwise PAUSE will not process the distribution.
        namespace => [ 'App::Pfind' ],
      },  
      prereqs => {
        test => {
          suggests => {
            'Test::Pod'   => 1.22,
          },
        },
      },
      resources => {
        repository => {
          type => 'git',
          url => 'git@github.com:mkende/pfind.git',
          web => 'https://github.com/mkende/pfind',
        },
        bugtracker => {
          web => 'https://github.com/mkende/pfind/issues',
        },
      },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Pfind-*' },
);
