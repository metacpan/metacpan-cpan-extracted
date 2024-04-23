use 5.38.0;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Arithmetic::PaperAndPencil',
    AUTHOR           => q{jforget <J2N-FORGET@orange.fr>},
    VERSION_FROM     => 'lib/Arithmetic/PaperAndPencil.pm',
    ABSTRACT_FROM    => 'lib/Arithmetic/PaperAndPencil.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.38.0',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.57_02',
    },
    TEST_REQUIRES => {
        'Test::More'      => '0'
      , 'Carp'            => '0'
      , 'POSIX'           => '0'
    },
    PREREQ_PM => {
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Arithmetic-PaperAndPencil-*' }
   , META_MERGE       => {
       'meta-spec'      => { version => 2 }
     , 'dynamic_config' => 0
     , 'prereqs' => {
          'build' => {
             'requires' => {
                'ExtUtils::MakeMaker' => '6.57_02'
             }
          },
          'configure' => {
             'requires' => {
                'ExtUtils::MakeMaker' => '6.57_02'
             }
          },
          'runtime' => {
             'requires' => {
                 'POSIX'           => '0'
               , 'strict'          => '0'
               , 'warnings'        => '0'
               , 'Carp'            => '0'
               , 'Exporter'        => '0'
               , 'List::Util'      => '0'
               , 'perl'            => '5.038000'
             }
          },
          'test' => {
             'recommends' => {
                  'Pod::Coverage'       => '0'
                , 'Test::Pod::Coverage' => '1.08'
                , 'Test::Pod'           => '1.22'
                , 'Test::Exception'     => '0.18'
                , 'Test::CheckManifest' => '0.9'
             }
          },
       },
       provides       => {
           'Arithmetic::PaperAndPencil' => {
                file => 'lib/Arithmetic/PaperAndPencil.pm',
                version => '0.01',
           }
         , 'Arithmetic::PaperAndPencil::Action' => {
                file => 'lib/Arithmetic/PaperAndPencil/Action.pm',
                version => '0.01',
           }
         , 'Arithmetic::PaperAndPencil::Char' => {
                file => 'lib/Arithmetic/PaperAndPencil/Char.pm',
                version => '0.01',
           }
         , 'Arithmetic::PaperAndPencil::Label' => {
                file => 'lib/Arithmetic/PaperAndPencil/Label.pm',
                version => '0.01',
           }
         , 'Arithmetic::PaperAndPencil::Number' => {
                file => 'lib/Arithmetic/PaperAndPencil/Number.pm',
                version => '0.01',
           }
       },
       resources => {
           repository => {
               type => 'git',
             , url  => 'https://github.com/jforget/perl-Arithmetic-PaperAndPencil.git'
             , web  => 'https://github.com/jforget/perl-Arithmetic-PaperAndPencil'
           },
       },
    },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
