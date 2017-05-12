# $Id: Makefile.PL,v 1.9 2003/01/28 22:15:57 barbee Exp $
require 5.004;
use strict;
use Getopt::Long;

$| = 1;

my $no_graph = 0;
GetOptions('no_graph+' => \$no_graph);

my $required_modules = {
    'Rcs' => 1.03,
    'Apache' => 1.27,
    'Graph' => 0.201,
};

my $dist_modules = {
    'CVS.pm'           => '$(INST_LIBDIR)/CVS.pm',
    'CVS/HTML.pm'      => '$(INST_LIBDIR)/CVS/HTML.pm',
    'CVS/Diff.pm'      => '$(INST_LIBDIR)/CVS/Diff.pm',
    'CVS/File.pm'      => '$(INST_LIBDIR)/CVS/File.pm',
    'CVS/Directory.pm' => '$(INST_LIBDIR)/CVS/Directory.pm',
    'CVS/PlainFile.pm' => '$(INST_LIBDIR)/CVS/PlainFile.pm',
    'CVS/RcsConfig.pm' => '$(INST_LIBDIR)/CVS/RcsConfig.pm',
    'CVS/Revision.pm'  => '$(INST_LIBDIR)/CVS/Revision.pm',
    'CVS/Graph.pm'     => '$(INST_LIBDIR)/CVS/Graph.pm',
};

if ($no_graph) {
    print qq(Excluding graph functionality.\n);
    delete $required_modules->{'Graph'};
    delete $dist_modules->{'CVS/Graph.pm'};
} else {
    print qq(Including graph functionality.\n);
}

use ExtUtils::MakeMaker;
WriteMakefile(
    NAME            => 'Apache::CVS',
    AUTHOR          => 'John Barbee <barbee@veribox.net>',
    ABSTRACT        => 'Apache method handler that displays Cvs repositories.',
    VERSION_FROM    => 'CVS.pm',
    PREREQ_PM       => $required_modules,
    PM              => $dist_modules
);
