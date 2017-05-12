use 5.008005;
use ExtUtils::MakeMaker;
use Config;

my %opts = ();

if ($Config{archname} && $Config{archname} =~ /64/) {
    $opts{LDDLFLAGS} = '-fPIC '.$Config{lddlflags};
}

WriteMakefile(
    NAME              => 'Algorithm::PageRank::XS',
    VERSION_FROM      => 'lib/Algorithm/PageRank/XS.pm',
    PREREQ_PM         => {},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Algorithm/PageRank/XS.pm',
       AUTHOR         => 'Michael Axiak <mike@axiak.net>') : ()),
    DEFINE            => '',
    INC               => '-I.',
    OBJECT            => 'XS.o pagerank.o table.o',
    'PREREQ_PM'       => {
        "Test::More"   => 0.11,        # For the tests only
    },

    %opts,

    dist         => {
        PREOP      => 'pod2text lib/Algorithm/PageRank/XS.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
        COMPRESS   => 'gzip -9v',
        SUFFIX     => '.gz',
    },


    # Remove annoying temp files...
    clean             => {FILES => "*~"},
);

