
use strict;
use warnings;
use ExtUtils::MakeMaker;

require 5.008; # just due to sprintf '%$N' usage in tests

WriteMakefile(
    NAME                => 'DashProfiler',
    AUTHOR              => 'Tim Bunce <Tim.Bunce@pobox.com>',
    VERSION_FROM        => 'lib/DashProfiler.pm',
    ABSTRACT            => '',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        DBI             => 1.57,
    },
    dist  => {
        DIST_DEFAULT=> 'clean distcheck disttest tardist',
        PREOP => '$(MAKE) -f Makefile.old distdir',
        COMPRESS => 'gzip -v9', SUFFIX => 'gz',
    },
    clean               => { FILES => 'DashProfiler-[0-9]*' },
);


sub MY::post_constants {
    q{
checkkeywords:
	$(RM_RF) blib
	find . -type f \( -name .svn -prune -o -name \*.pm -o -name \*.PL -o -name \*.pl \) \
	    -exec bash -c '[ -z "$$(svn pg svn:keywords {})" ] && echo svn propset svn:keywords \"Id Revision\" {}' \;

checkpod:
	$(RM_RF) blib
	find . -type f \( -name .svn -prune -o -name \*.pm -o -name \*.PL -o -name \*.pl \) \
	    -exec podchecker {} \; 2>&1 | grep -v "pod syntax OK"
}
}

