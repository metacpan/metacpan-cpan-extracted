use 5.018;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'App::PTP',
    AUTHOR           => q{Mathias Kende <mathias@cpan.org>},
    VERSION_FROM     => 'lib/App/PTP.pm',
    ABSTRACT         => 'An expressive Pipelining Text Processor',
    LICENSE          => 'mit',
    EXE_FILES        => ['script/ptp'],
    MIN_PERL_VERSION => '5.022',
    MAN3PODS         => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
        'Benchmark'  => '0',
    },
    PREREQ_PM => {
        'Cwd'                   => 0,
        'Data::Dumper'          => 0,
        'Exporter'              => 0,
        'File::Find'            => 0,
        'File::Spec::Functions' => 0,
        'Getopt::Long'          => 0,
        'List::Util'            => 0,
        'Pod::Usage'            => 0,
        'Safe'                  => 0,
        'Scalar::Util'          => 0,
    },
    NO_MYMETA => 1,
    META_MERGE => {
      'meta-spec' => { version => 2 },
      # Goes with NO_MYMETA (which would provide the dynamic config).
      dynamic_config => 0,
      no_index => {
        # ignores child of App::PTP, but not App::PTP itself.
        namespace => [ 'App::PTP' ],
      },  
      prereqs => {
        runtime => {
          suggests => {
            're::engine::GNU'   => 0,
            're::engine::PCRE'  => 0,
            're::engine::PCRE2' => 0,
            're::engine::RE2'   => 0,
            're::engine::TRE'   => 0,
          },
        },
        test => {
          suggests => {
            'Test::Pod'   => 1.22,
            'Time::HiRes' => 0,
          },
        },
      },
      resources => {
        repository => {
          type => 'git',
          url => 'git@github.com:mkende/ptp.git',
          web => 'https://github.com/mkende/ptp',
        },
        bugtracker => {
          web => 'https://github.com/mkende/ptp/issues',
        },
      },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-PTP-*' },
);
