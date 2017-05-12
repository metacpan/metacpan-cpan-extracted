#!/usr/local/bin/perl -w
#
# $Id: Makefile.PL 571 2006-12-02 03:45:24Z wagnerch $
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.
#
BEGIN { require 5.004 }	# 5.004 is required for Win32
use Config;
use ExtUtils::MakeMaker 5.16, qw(&WriteMakefile $Verbose);
use File::Basename;
use Getopt::Long;
use File::Spec;

use DBI 1.21;		# must be installed first ...
use DBI::DBD;
use strict;

my %opts = (
   NAME	=> 'DBD::TimesTen',
   VERSION_FROM => 'TimesTen.pm',
   PREREQ_PM => { "Test::Simple" => 0.40 }, # actually Test::More pkg in T::S dist
   clean => { FILES=> 'TimesTen.xsi' },
   dist => {
      DIST_DEFAULT=> 'clean svnlog distcheck tardist',
      PREOP    => '$(MAKE) -f Makefile.old distdir',
      COMPRESS => 'gzip -v9', SUFFIX => 'gz'
   },
   OBJECT => '$(O_FILES)',
   DEFINE => '',
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
   $opts{AUTHOR} = 'Tim Bunce and Jeff Urlwin mailto:dbi-users@perl.org';
   $opts{ABSTRACT} = 'TimesTen driver for the DBI module.';
   $opts{PREREQ_PM} = { DBI => 1.21 };
   $opts{CAPI} = 'TRUE' if $Config{archname} =~ /-object\b/i;
}

our $opt_g = 0;
our $opt_o = '';
Getopt::Long::GetOptions (
    "g!" => \$opt_g
   ,"o=s" => \$opt_o
) or die "Invalid arguments";

print "Overriding TimesTen Directory with command line option: $opt_o\n"
   if $opt_o;

if (-d ".svn")
{
   $opts{DEFINE} .= ' -Wall';
   $opt_g = 1;
}

if ($opt_g)
{
   print "Setting debug options!\n";
   $opts{OPTIMIZE} = '-g -O0';
}

print "\nConfiguring DBD::TimesTen ...\n
>>>\tRemember to actually *READ* the README file!
   \tAnd re-read it if you have any problems.\n
";

my $dbi_dir      = dbd_dbi_dir();
my $dbi_arch_dir = dbd_dbi_arch_dir();
my $timesten_home= $opt_o || $ENV{TT_HOME};

unless ($timesten_home)
{
   print qq{
The DBD::TimesTen module needs to link with the TimesTen client library.

You need to indicate where your TimesTen client is installed.
You can do this ether by setting the TT_HOME environment variable
or by runing 'perl Makefile.PL -o <ttdir>'.

};

   die "Makefile.PL aborted.\n";
}

die "TT_HOME environment variable ($timesten_home) does not refer to a directory.\n"
   unless -d $timesten_home;

warn "Using TimesTen in $timesten_home\n";

$opts{INC} = "-I. -I$dbi_arch_dir -I$timesten_home/include";
$opts{LIBS} = "-L$timesten_home/lib -lttclient";
$opts{LDDLFLAGS} = $Config{lddlflags} . " -Wl,-rpath,$timesten_home/lib";

print "\n";
my $rv = WriteMakefile(%opts);

local($^W)=0;
print qq{
The DBD::TimesTen tests will use these values for the database connection:

    DBI_DSN=$ENV{DBI_DSN}		e.g. dbi:TimesTen:demo
    DBI_USER=$ENV{DBI_USER}
    DBI_PASS=$ENV{DBI_PASS}
};
print "Warning: not all required environment variables are set.\n"
   unless ($ENV{DBI_DSN} && $ENV{DBI_USER} && $ENV{DBI_PASS});

print "Warning: DBI_DSN ($ENV{DBI_DSN}) doesn't start with 'dbi:TimesTen:'\n"
   if ($ENV{DBI_DSN} && $ENV{DBI_DSN} !~ m/^dbi:TimesTen:/i);

print "\n";

$rv;

# ====================================================================

{
   package MY; # SUPER needs package context, $self is not sufficient

   use strict;
   use Config;

   sub postamble
   {
      return main::dbd_postamble(@_);
   }

   sub dist_basics
   {
      return shift->SUPER::dist_basics(@_) . '
svnlog :
	svn log -v --xml svn://localhost/repos/dbd-timesten/ |$(SVN2LOG)/svn2log.py -D 0 -s -O -L -H -F -u "$(SVN2LOG)/svn2log.users" -x "dbd-timesten/branches/"

RPMBUILD = rpmbuild --define "_sourcedir $(shell pwd)" --define "_builddir $(shell pwd)/build" --define "_srcrpmdir $(shell pwd)" --define "_rpmdir $(shell pwd)" 
SPECFILE = DBD-TimesTen.spec

srpm : $(DIST_DEFAULT) $(FIRST_MAKEFILE)
	$(RPMBUILD) -bs $(SPECFILE)

rpm : $(DIST_DEFAULT) $(FIRST_MAKEFILE)
	mkdir $(shell pwd)/build && $(RPMBUILD) -bb $(SPECFILE) && rm -fR $(shell pwd)/build
';
   }
}
__END__


