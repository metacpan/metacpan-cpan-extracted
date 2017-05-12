#
# $Id: Makefile.PL,v 1.1 2010/08/23 09:11:03 dankogai Exp dankogai $
#
use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::Decycle',
    AUTHOR              => q{Dan Kogai <dankogai+cpan@gmail.com>},
    VERSION_FROM        => 'lib/Data/Decycle.pm',
    ABSTRACT_FROM       => 'lib/Data/Decycle.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	# 'PadWalker'  => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-Decycle-*' },
);
