# -*- perl -*-

use strict;
use Config;
use File::Basename qw(basename dirname);
use Cwd;

# This forces PL files to create target in same directory as PL file.
# This is so that make depend always knows where to find PL derivatives.
my $origdir = cwd;
chdir dirname($0);
my $script = basename($0, '.PL');
$script .= '.com' if $^O eq 'VMS';

unlink($script);
open OUT, ">$script" or die "open for writing $script: $!";

print OUT <<"!GROK!THIS!";
$Config{startperl}
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';
	
#
# $Id: datum_strip.PL,v 0.1 2001/03/31 10:04:37 ram Exp $
#
#  Copyright (c) 2000-2001, Christophe Dehaudt & Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: datum_strip.PL,v $
# Revision 0.1  2001/03/31 10:04:37  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

use Log::Agent;
logconfig(-prefix => $0);

use Carp::Datum::Strip qw(datum_strip);

if (@ARGV == 0) {
	datum_strip("-", "-");
} else {
	foreach my $file (@ARGV) {
		datum_strip($file, "$file.new", ".bak");
	}
}

!NO!SUBS!

close OUT or die "Can't close $script: $!";
chmod 0755, $script or die "Can't reset permissions for $script: $!\n";
exec("$Config{'eunicefix'} $script") if $Config{'eunicefix'} ne ':';
chdir $origdir;
