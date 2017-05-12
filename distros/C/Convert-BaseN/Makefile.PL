#
# $Id: Makefile.PL,v 0.1 2008/06/16 17:34:27 dankogai Exp dankogai $
#
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Convert::BaseN',
    AUTHOR              => 'Dan Kogai <dankogai@dan.co.jp>',
    VERSION_FROM        => 'lib/Convert/BaseN.pm',
    ABSTRACT_FROM       => 'lib/Convert/BaseN.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'MIME::Base64' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Convert-BaseN-*' },
);
