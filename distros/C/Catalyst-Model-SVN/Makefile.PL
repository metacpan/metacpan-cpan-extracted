# $Id: /mirror/projects/Catalyst-Model-SVN/branches/fix-svn-1_5/Makefile.PL 8053 2008-10-09T23:36:54.691290Z bobtfish  $
use ExtUtils::MakeMaker;
use 5.008;
use strict;
use warnings;

WriteMakefile(
    NAME         => 'Catalyst::Model::SVN',
    VERSION_FROM => 'lib/Catalyst/Model/SVN.pm',
    AUTHOR       => 'Christopher H. Laco <claco@chrislaco.com>, Tomas Doran <bobtfish@bobtfish.net>',
    ABSTRACT     => 'Catalyst Model to browse Subversion repositories',
    PREREQ_PM    => {
        'Catalyst::Runtime'     => 0,
        'Catalyst::Devel'       => 0, # Build dep
        'SVN::Core'             => 0,
        'IO::Scalar'            => 0,
        'Path::Class'           => 0,
        'DateTime'              => 0,
        'IO::Scalar'            => 0,
    },
    dist => {
        PREOP => 'pod2text lib/Catalyst/Model/SVN.pm > $(DISTVNAME)/README',
    },
    clean => { FILES => 't/TestApp'},
);
