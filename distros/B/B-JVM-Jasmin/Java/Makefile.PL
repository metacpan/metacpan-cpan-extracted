#!/usr/bin/perl
# Makefile.PL                                                      -*- Perl -*-
#   Makefile generator for Java source
#
#   Copyright (C) 1999, Bradley M. Kuhn, All Rights Reserved.
#
# You may distribute under the terms of either the GNU General Public License
# or the Artistic License, as specified in the LICENSE file that was shipped
# with this distribution.

use strict;
use warnings;

use Carp;

use Config;

use ExtUtils::Manifest;

open(MAKEFILE, ">Makefile") || die "unable to create Makefile: $!";

my $files = ExtUtils::Manifest::maniread("../MANIFEST");
my @javaFiles = ();

foreach my $key (keys %{$files}) {
  if ($key =~ s%^Java/(\S+)\.java$%$1.class%) {
    push(@javaFiles, $key);
  }
}
print MAKEFILE <<"SUBS";
JAVAC = $ENV{PERL_JVM_JAVAC}
INSTALLDIR = $ENV{PERL_JVM_CLASS_FILE_HOME}/org/perl/inernals

CLASS_FILES = @javaFiles

.SUFFIXES: .java .class

.java.class:
	\$(JAVAC) \$*.java

all: \$(CLASS_FILES)
	-mkdir -p ../blib/lib/javalib/org/perl/internals
	cp \$(CLASS_FILES) ../blib/lib/javalib/org/perl/internals

clean:
	@-rm -f \$(CLASS_FILES)

realclean:	clean

install:	all
	cp \$(CLASS_FILES) \$(INSTALLDIR)
	-cd \$(INSTALLDIR); chown root.root *; chmod 644 *

test:

SUBS

print MAKEFILE <<'NOSUBS';
NOSUBS

close MAKEFILE;
