################################################################################
#
#   File name: Makefile.PL
#   Project: DBD::Illustra
#   Description: Makefile creator
#
#   Author: Peter Haworth
#   Date created: 17/07/1998
#
#   sccs version: 1.4    last changed: 08/12/98
#
#   Copyright (c) 1998 Institute of Physics Publishing
#   You may distribute under the terms of the Artistic License,
#   as distributed with Perl, with the exception that it cannot be placed
#   on a CD-ROM or similar media for commercial distribution without the
#   prior approval of the author.
#
################################################################################

use 5.004;
use ExtUtils::MakeMaker;
use Config;
use strict;
use DBI 0.93;
use DBI::DBD;

my $MI_HOME;
foreach($ENV{MI_HOME},'/usr/local/illustra','/opt/illustra'){
  next if $_ eq '';

  -d $_ && -d "$_/lib" && -d "$_/h"
    or next;
  
  $MI_HOME=$_;
  last;
}
die "\$MI_HOME environment variable must be set.\n"
  unless defined $MI_HOME;

my %opts=(
  NAME => 'DBD::Illustra',
  VERSION_FROM => 'Illustra.pm',
  clean => { FILES => 'Illustra.xsi' },
  dist => {
    DIST_DEFAULT => 'clean distcheck disttest ci tardist',
    PREOP => '$(MAKE) -f Makefile.old distdir',
    COMPRESS => 'gzip -9f',
    SUFFIX => 'gz',
  },
  INC => "-I\$(INSTALLSITEARCH)/auto/DBI -I$MI_HOME/h",
  LIBS => "-L$MI_HOME/lib -lmi",
  OBJECT => '$(O_FILES)',
);

WriteMakefile(%opts);

exit 0;

sub MY::postamble{
  return dbd_postamble(@_);
}


