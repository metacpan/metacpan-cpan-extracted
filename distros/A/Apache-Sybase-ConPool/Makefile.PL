# $Id: Makefile.PL,v 1.1.1.1 2001/10/31 22:03:22 mpeppler Exp $
#
#

eval {
    require Sybase::CTlib;
};
die "I can't find Sybase::CTlib.\nYou must install sybperl 2.xx before being able to use this module\n" if $@;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Apache::Sybase::ConPool',
    'VERSION_FROM' => 'ConPool.pm', # finds $VERSION
);
