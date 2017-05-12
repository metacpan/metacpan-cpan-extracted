#!perl
use Config;
use File::Basename qw(&basename &dirname);
use Cwd;

$origdir = cwd;
chdir dirname($0);
$file = basename($0, '.PL','.PLS');
#$file .= $^O eq 'VMS' ? '.com' : '.pl';

open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

print OUT "$Config{startperl}\n";

print OUT <<'!NO!SUBS!';
# filename: wormbase.pm.defaults
# Author: T. Harris
# This simple CGI collects default values for
# those using WormBase.pm

# In particular, it includes paths for building and installing
# WormBase packages.

use lib '../lib';
use CGI 'param','header','path_info';
use Ace;
use Ace::Browser::AceSubs;
use ElegansSubs;
use strict;

use vars qw($DB);
$DB = OpenDatabase() || AceError("Couldn't open database.");

print header('text/plain');
print <<END;
# WormBase Site Defaults
# This page provides default values for a typical WormBase
# installation. It is intended for use with Bio::GMOD.pm
#
NAME=WormBase
#
#######################################;
# SERVERS
#######################################
# The WormBase live server
LIVE_NAME=WormBase live server
LIVE_URL=http://www.wormbase.org
LIVE_DESCRIPTION=The primary WormBase public server
VERSION_CGI_LIVE=http://www.wormbase.org/db/gmod/version
DEVELOPMENT_NAME=WormBase development server
DEVELOPMENT_URL=http://dev.wormbase.org
DEVELOPMENT_DESCRIPTION=The WormBase semi-public development server
VERSION_CGI_DEV=http://dev.wormbase.org/db/gmod/version
STANDARD_URLS_XML=http://www.wormbase.org/standard_urls/standard_urls.xml
#
#######################################
# LOCAL PATHS
#######################################
#
# Full path to the local acedb installation.
# This should actually be a symlink pointing to the current elegans_WSXXX release
ACEDB_PATH=/usr/local/acedb
MYSQL_PATH=/usr/local/mysql/data
TMP_PATH=/usr/local/gmod/wormbase/releases
INSTALL_ROOT=/usr/local/wormbase
#
#######################################
# REMOTE PATHS
#######################################
#
FTP_SITE=dev.wormbase.org
# Full local path
FTP_ROOT=/usr/local/ftp
FTP_BASE=/pub/wormbase
FTP_PATH=/pub/wormbase/mirror/database_tarballs
# Where to find prepackaged databases
DATABASE_REPOSITORY=/pub/wormbase/mirror/database_tarballs
#
#######################################
# TARBALL FILENAMES (printf templates)
#######################################
#
ACEDB_TARBALL=elegans_%s.ace.tgz
ELEGANS_GFF_TARBALL=elegans_%s.gff.tgz
BRIGGSAE_GFF_TARBALL=briggsae_%s.gff.tgz
BLAST_TARBALL=blast_%s.tgz
#
#######################################
# DISK SPACE REQUIREMENTS (GB)
#######################################
#
ACEDB_DISK_SPACE=10
ELEGANS_GFF_DISK_SPACE=3.5
BRIGGSAE_GFF_DISK_SPACE=5
BLAST_DISK_SPACE=0.5
#
#######################################
# SOFTWARE (RSYNC,CVS) PATHS
#######################################
#
RSYNC_URL=rsync://dev.wormbase.org
RSYNC_MODULE=wormbase-live
CVS_ROOT=:pserver:anonymous\@brebiou.cshl.org:/usr/local/cvs
#
#######################################
# DATA MINING CONSTANTS
#######################################
#
# FOR HTTP-BASED REQUESTS
DATA_MINING_URL=http://aceserver.cshl.org
# FOR DIRECT DATABASE REQUESTS
DATA_MINING_SERVER=aceserver.cshl.org
DATA_MINING_PORT=2005


#
#######################################
# GENERIC QUERIES
#######################################
#
GENE_FETCH_QUERY=select a,a->Public_name,a->Concise_description from a in class Gene where a->Public_name="%s"


# BELOW IS NOT YET SYNC'ed with adaptor
# FOR BUILDING PACKAGES
#
#######################################
# PACKAGE PATHS
#######################################
#
#CURRENT_PACKAGE_SYMLINK=/usr/local/ftp/pub/wormbase/mirror/database_tarballs/current_release
#
#######################################
# ARCHIVING CONSTANTS
#######################################
#
CURRENT_RELEASE=/pub/wormbase/elegans-current_release
ARCHIVE_PATH=/usr/local/ftp/pub/wormbase/database_tarballs
ARCHIVE_REPOSITORY=/pub/wormbase/archive
END



exit 0;
!NO!SUBS!
close OUT or die "Can't close $file: $!\n";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;
