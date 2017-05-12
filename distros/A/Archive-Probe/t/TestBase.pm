package TestBase;
# Base for all test cases. This package sets up the log4perl configure.
#
# Author:          JustinZhang <fgz@qad.com>
# Creation Date:   2012-07-06
#
# $Id: TestBase.pm 4308 2012-08-23 01:29:22Z fgz $
#

use strict;
use File::Spec::Functions qw(rel2abs updir catdir);
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(get_test_data_dir);

BEGIN {
    if (-d 'lib') {
        # running from the base directory
        unshift @INC, 'lib';
    }
    else {
        # running from t directory
        unshift @INC, '../lib';
    }
}

sub get_test_data_dir {
    my $dir = "testdata";
    if (-d $dir) {
        return rel2abs("testdata");
    }
    else {
        return rel2abs(catdir("t", "testdata"));
    }
}

1;
# vim: set ai nu nobk expandtab sw=4 ts=4:
