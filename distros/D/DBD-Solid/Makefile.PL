#
# $Id: Makefile.PL,v 1.1 2001/10/13 21:08:47 joe Exp $
#
# portions Copyright (c) Geospiza Inc
# portions Copyright (c) Tim Bunce
# portions Copyright (c) Thomas K. Wenrich
#

BEGIN { $^W = 1 }
BEGIN { require 5.003 }	          # 5.003 fixes very important bugs

use Config;
use ExtUtils::MakeMaker 5.16, qw(&WriteMakefile $Verbose);
use DBI 1.08;
use File::Find;
use strict;


# --- Introduction

print(<<TXT);
Configuring DBD::Solid ...
   Remember to actually *READ* the README file!
   Especially if you have any problems.

TXT


# --- Where is Solid installed...

my $SOLIDDIR = $ENV{'SOLIDDIR'};

die(<<TXT) unless $SOLIDDIR;
The \$SOLIDDIR environment variable must be set.
It must be set to hold the path to an Solid Embedded Engine installation
directory on this machine (or a machine with a compatible architecture).

Example:
   Assuming the Solid EE files are in /foo/bar/include and /foo/bar/lib,
   you may configure the DBD::Solid module by entering:

   SOLIDDIR=/foo/bar perl Makefile.PL

ABORTED!
TXT

print "Using Solid in $SOLIDDIR\n";

my $l_dir = findLibraries();
die(<<TXT) unless $l_dir;
I can't seem to find the library files I need in your Solid installation.
Please check that you have Solid installation has at least one of the
following link(s):

   $SOLIDDIR/<...>/libsolodbc.a
   $SOLIDDIR/<...>/libsolodbc.so

ABORTING!
TXT

my $h_dir = findHeaders();
(warn(<<TXT) && sleep 5 ) unless ( $h_dir );
I can't find the header files I need in your Solid installation.
I'll keep going, but the compile will probably fail.
TXT


# --- How should we link with Solid?

my $linkAs = "@ARGV" =~ m/\bLINKTYPE=static\b/ ? "static" : "dynamic";
checkLib( $linkAs );

print(<<TXT) if ( $linkAs eq 'static' );
Linking statically.
*** Note: DBD::Solid will be built *into* a NEW perl binary. You MUST use
    that new perl.
    See README and Makefile.PL for more information.

TXT
print(<<TXT) if ( $linkAs eq 'dynamic' );
Linking dynamically.
TXT


# --- Generation of the Makefile...

my %opts = 
   (
   NAME         => 'DBD::Solid',
   VERSION_FROM => 'Solid.pm',      # finds $VERSION
   LIBS 	=> [''],            # e.g., '-lm' 
   DEFINE	=> '',              # e.g., '-DHAVE_SOMETHING' 
   INC	        => '',              # e.g., '-I/usr/include/other' 
   OBJECT       => qw( $(O_FILES) ),
   dist  => { DIST_DEFAULT => 'clean distcheck disttest ci tardist',
              PREOP        => '$(MAKE) -f Makefile.old distdir',
	      COMPRESS	   => 'gzip -v9', SUFFIX => 'gz',
            },
   );

$opts{macro} = 
   {
   SOLID_LIBRARY => $l_dir,
   SOLID_INCLUDE => $h_dir,
   COMPRESS => 'gzip',
   SUFFIX   => '.gz',
   };


$opts{INC} = "-I\$(INSTALLSITEARCH)/auto/DBI"
	   . " -I\$(INSTALLSITEARCH)"
           . " -I$h_dir";

if ( $linkAs eq "dynamic" )
   {
   $opts{LINKTYPE} = "dynamic";
   push( @{$opts{LIBS}}, "-L$l_dir -lsolodbc -lpthread" );
   }
else
   {
   $opts{LINKTYPE} = "static";
   $opts{macro}->{EXTRALIB} = '$(SOLID_LIBRARY)';
   push( @{$opts{LIBS}}, "-lpthread" );
   }

sub MY::pasthru 
   {
   my ($inherited) = shift->ExtUtils::MM_Unix::pasthru(@_);
   $inherited=~ s/$/\\\n\tSOLID_INCLUDE="\$(INC)"/;
   $inherited=~ s/$/\\\n\tSOLID_LIBRARY="\$(SOLID_LIBRARY)"/;
   $inherited;
   }

WriteMakefile(%opts);

exit( 0 );


#-- SUBROUTINES --------------------------------------------------------------#

sub findHeaders
   {
   my $h_dir;
   find( sub {
             return unless /^sql.*\.h$/i;
             $h_dir = $File::Find::dir unless $h_dir;
             },
         $SOLIDDIR );

   print "Found header files in $h_dir\n" if $h_dir;
   return $h_dir;
   }

sub findLibraries
   {
   my $l_dir;
   find( sub {
             return unless /^libsolodbc\.(a|so)$/i;
             $l_dir = $File::Find::dir unless $l_dir;
             },
         $SOLIDDIR );

   print "Found library files in $l_dir\n" if $l_dir;
   return $l_dir;
   }
 
sub checkLib
   {
   my $linkAs = shift;

   die(<<TXT) if ( $linkAs eq 'dynamic' && !-e "$l_dir/libsolodbc.so" );
Couldn't find link libsolodbc.so in solid installation.  Therefore I can't
link dynamically, read the README for more information.
ABORTING!
TXT

   die(<<TXT) if ( $linkAs eq 'static' && !-e "$l_dir/libsolodbc.a" );
Couldn't find link libsolodbc.a in solid installation.  Therefore I can't
link statically, read the README for more information.
ABORTING!
TXT
   }

__END__
