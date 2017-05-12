#                              -*- Mode: Perl -*- 
# $Basename: Makefile.PL $
# $Revision: 1.4 $
# Author          : Ulrich Pfeifer
# Created On      : Fri Jan 31 15:36:26 1997
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Thu Mar 23 18:10:33 2000
# Language        : CPerl
# Update Count    : 34
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1997, Ulrich Pfeifer, all rights reserved.
# 
# 

use ExtUtils::MakeMaker;

unless (-f '.notest') {
  print <<'EOF'

If you live behind a firewall or your favourite WAIT server is down,
the test for this module may block for minutes.

EOF
    ;
  my $run_tests = prompt('Should I run the tests anyway?', 'n');
  if ($run_tests eq "n") {
    open(CONF, ">.notest") or die "Could not create '.notest': $!";
    close CONF;
    print <<'EOF'

I created a file '.notest' in the current directory. Remove it if you
changed your mind.

EOF
  ;
  }
}

WriteMakefile
  (
   'NAME'	   => 'CPAN::WAIT',
#  $Format: "   'VERSION' => '$ModuleVersion$',"$
   'VERSION' => '0.27',
   'PREREQ_PM'     =>
   {
    CPAN      => 0,
    Net::NNTP => 0,
   },                         
   'dist'          =>
   {
    PREOP        => 'pod2text lib/CPAN/WAIT.pm > README;',
    DIST_DEFAULT => 'tardist',
    COMPRESS     => 'gzip -9f'
   },
);
