################################################################################
#
#   File name: Makefile.PL
#   Project: Cache::Mmap
#   Description: Makefile creator
#
#   Author: Peter Haworth
#   Date created: 28/06/2000
#
#   $Id: Makefile.PL,v 1.4 2003/06/13 16:21:49 pmh Exp $
#
#   Copyright Institute of Physics Publishing 2002
#   You may distribute under the terms of the GPL or the Artistic License,
#   as distributed with Perl
#
################################################################################

use ExtUtils::MakeMaker;
use Config;
use strict;

warn "WARNING! I can't test for the existence of mmap() yet.\n";
warn "         If your system does not provide mmap(), you will be unable\n";
warn "         to compile this module.\n";

if($Config{d_fcntl} eq 'define'){
  if($Config{d_fcntl_can_lock} eq 'define'){
    # OK
  }else{
    warn "WARNING! fcntl() on this system may be unable to lock files.\n";
    warn "         If so, you will be unable to compile this module.\n";
  }
}else{
  warn "FATAL! This system does not provide fcntl().\n";
  die  "       You will be unable to compile this module.\n";
}

WriteMakefile(
  NAME => 'Cache::Mmap',
  VERSION_FROM => 'Mmap.pm',
  PREREQ_PM => {
    Fcntl => 0,
    Carp => 0,
    Storable => 0,
    'Test::More' => 0,
  },
  dist => {
    COMPRESS => 'gzip -9f',
    SUFFIX => 'gz',
    DIST_DEFAULT => 'all tardist',
  },
  $ExtUtils::MakeMaker::VERSION >= 5.4301 ? (
    ABSTRACT => "Shared cache using mmap'd file",
    AUTHOR => 'Peter Haworth (pmh@edison.ioppublishing.com)',
  ) : (),
);

