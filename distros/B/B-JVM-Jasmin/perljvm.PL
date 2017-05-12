#!/usr/bin/perl -w
#  perljvm.PL                                                      -*- Perl -*-
#     A program stub that will generate perljvm,  a front end to B::JVM:Jasmin
#
#   Copyright (C) 1999, Bradley M. Kuhn, All Rights Reserved.
#
# You may distribute under the terms of either the GNU General Public License
# or the Artistic License, as specified in the LICENSE file that was shipped
# with this distribution.

use Config;
use File::Basename qw(&basename &dirname);
use Cwd;

# List explicitly here the variables you want Configure to
# generate.  Metaconfig only looks for shell variables, so you
# have to mention them as if they were shell variables, not
# %Config entries.  Thus you write
#  $startperl
# to ensure Configure will look for $Config{startperl}.

# This forces PL files to create target in same directory as PL file.
# This is so that make depend always knows where to find PL derivatives.

$origdir = cwd;
chdir dirname($0);
$file = basename($0, '.PL');
$file .= '.com' if $^O eq 'VMS';

open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
$Config{startperl}
    eval 'exec $Config{perlpath} -S \$0 \${1+"\$@"}'
        if \$running_under_some_shell;

\$JAVA_PATH = "$ENV{B_JVM_JASMIN_JAVA_PATH}";
\$JASMIN_PATH = "$ENV{B_JVM_JASMIN_JASMIN_PATH}";
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';

require 5.00562;

use strict;

use warnings;
no warnings qw(once);

# Need this 'use vars' because the above 'no warnings' is still experimental
use vars qw($running_under_some_shell);

use vars qw($RUN_ONCE_COMPILED $KEEP_INTERMEDIATE $JAVA_PATH $JASMIN_PATH);

$KEEP_INTERMEDIATE = $RUN_ONCE_COMPILED = 0;

# FIXME: Use Getopts for the love of dog.  ;p)
{
  no warnings qw(uninitialized);
  
  if ($ARGV[0] eq "--run") {
    shift @ARGV;
    $RUN_ONCE_COMPILED = 1;
    die "cannot use --run since not configured with working jasmin"
      if ($JASMIN_PATH eq "");
    die "cannot use --run since not configured with working JVM"
      if ($JAVA_PATH eq "");
    
  }
  if ($ARGV[0] eq "--keep") {
    shift @ARGV;
    $KEEP_INTERMEDIATE = 1;
  }
}

if (@ARGV < 1) {
  print STDERR "usage: $0 [--run] [--keep] <perlsource> [<classname>]\n";
  exit 1;
}
  
  my $INC = ' -I' . join(' -I', @INC);

# FIXME: I was in a hurry...this really shouldn't recall Perl but call the 
#        module directly

  my $systemString;

  $ARGV[1] = "Main" unless (defined $ARGV[1]);
  $systemString = "$^X $INC -MO=JVM::Jasmin,$KEEP_INTERMEDIATE,$ARGV[1]" .
      " $ARGV[0]";

#print STDERR "EXECUTING: $systemString\n";
system($systemString);

die "unable to compile $ARGV[0]" unless ($? == 0);

system("$JASMIN_PATH $ARGV[1].jasmin");

die "unable to $ARGV[1] to $ARGV[0].class" unless ($? == 0);

unlink("$ARGV[1].jasmin") unless $KEEP_INTERMEDIATE;

if ($RUN_ONCE_COMPILED) {
    system("java $ARGV[1]");
    unlink("$ARGV[1].class") unless $KEEP_INTERMEDIATE;
}
!NO!SUBS!

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;
