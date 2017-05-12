#TODO Check and see if all of the files, packages, get into the library tar.gz file.
#TODO Update the dependency list.
#TODO Install those .pl files into site/bin.


use 5.006;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $version = '00';
my $buildno = sprintf("%02d%03d",$year % 100,$yday);

WriteMakefile(
    ($ExtUtils::MakeMaker::VERSION gt '6.3002'
      ? ('LICENSE'=> 'restrictive')
      : ())
    ,NAME		=> 'Comskil-JIRA'
    ,VERSION	=> "$version.$buildno"
    ,ABSTRACT	=> <<ABSTRACT_TEXT
Retrieve, Translate, Map, Integrate, and Import JIRA Issues:
A collection of tools to enable retrieval, storage, integration, and mapping of data
from JIRA live instances and backfiles.  This was created to assist in the migration
and integration of several 3rd party hosted issue tracking tools and JIRA instances
into a single JIRA Studio OnDemand site.  
Version '00.nnnnn' == 'Raw Development, Not Even Unstable'
ABSTRACT_TEXT
    ,AUTHOR		=> q{Peter Shiner <pshiner@comskil.com>}
    ,SIGN		=> 0
    ,PMLIBDIRS	=> [ './lib', './lib/Comskil', './lib/Comskil/JQueue' ]
    ,PL_FILES	=> { }
    ,dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', }
    ,clean		=> { FILES => 'Comskil-*' }
    ,PREREQ_PM	=> {
        'Test::More' => 0,
        'File::Path' => 0,
        'LWP::UserAgent' => 0,
        'HTTP::Headers' => 0,
        'HTTP::Response' => 0,
        'HTTP::Status' => 0,
        'JIRA::Client' => 0,
    }
);

my $fn = "VERSION.STRING";
print("Writing $fn\n");
open(OUT,">$fn");
print(OUT "$version.$buildno");
close(OUT);

__END__
### EOF ###
