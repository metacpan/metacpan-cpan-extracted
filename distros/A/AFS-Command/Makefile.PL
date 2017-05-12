#
# $Id: Makefile.PL,v 7.1 2004/01/13 19:01:10 wpm Exp $
#
# (c) 2003-2004 Morgan Stanley and Co.
# See ..../src/LICENSE for terms of distribution.
#

require 5.6.0;

use ExtUtils::MakeMaker;

WriteMakefile
  (
   NAME			=> 'AFS::Command',
   VERSION_FROM		=> 'lib/AFS/Command/Base.pm', # finds $VERSION
   PREREQ_PM         	=> {},	# e.g., Module::Name => 1.1
   AUTHOR     		=> 'W. Phillip Moore <Phil.Moore@MorganStanley.com>',
  );

