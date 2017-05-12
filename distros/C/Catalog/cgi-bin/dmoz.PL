use Config;
use File::Basename qw(basename dirname);
chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//;
$file =~ s/\.pl$//
	if ($Config{'osname'} eq 'VMS' or
	    $Config{'osname'} eq 'OS2');  # "case-forgiving"
open OUT,">$file" or die "Can't create $file: $!";
chmod(0755, $file);
print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
$Config{'startperl'} -w

!GROK!THIS!

print OUT <<'!NO!SUBS!';

use strict;

use Catalog::dmoz;
#
# BUG WORKAROUND: DBI-1.06 + XML-Parser-2.22 + Perl-5.005_02
# Should be fixed in the next version of Perl.
#
use FileHandle;

Catalog::dmoz->selector();

!NO!SUBS!

# Local Variables: ***
# mode: perl ***
# End: ***
