use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::Prove::Plugin::TraceUse',
    AUTHOR              => 'Torbjørn Lindahl <torbjorn.lindahl@gmail.com>',
    VERSION_FROM        => 'lib/App/Prove/Plugin/TraceUse.pm',
    ABSTRACT_FROM       => 'lib/App/Prove/Plugin/TraceUse.pm',
    PL_FILES            => {},
    PREREQ_PM => {
                  'App::Prove' => '3.15',
                  'Test::Perl::Critic'  => '1.02',
                  'Test::Pod::Coverage' => '1.08',
                  'Test::Most'          => '0.25',
                  'Set::Object'         => '1.26',
                  'Test::Pod'           => '1.45',
                  'File::Slurp'         => '9999.19',
                  'Tree::Simple'        => '1.18',
                  'Devel::TraceUse'     => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-Prove-Plugin-TraceUse-*' },
);
