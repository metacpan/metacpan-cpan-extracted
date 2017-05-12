#!/usr/bin/perl
################################################################################
#
# File:     99_pod.t
# Date:     2012-08-05
# Author:   H. Klausing (h.klausing (at) gmx.de)
#
# Description:
#   Tests for POD.
#
################################################################################
#
# Updates:
# 2012-09-01 H. Klausing
#       Version number removed.
# 2012-08-12 v 1.0.2   H. Klausing
#       version number incremented
# 2012-08-05 v 1.0.1   H. Klausing
#       Initial script version
#
################################################################################
#
#-------------------------------------------------------------------------------
# TODO -
#-------------------------------------------------------------------------------
#
#
#
#--- process requirements ---------------
use warnings;
use strict;

#
#
#
#--- global variables -------------------
#
#
#
#--- used modules -----------------------
use Test::More;

#
#
#
#--- function forward declarations ------
#
#
#
#--- start script -----------------------
main();
exit 0;    # script execution was successful

#
#
#
################################################################################
#   script functions
################################################################################
#
#
#
#-------------------------------------------------------------------------------
# Main entry function for this script.
#-------------------------------------------------------------------------------
sub main {
    eval "use Test::Pod 1.45";
    plan skip_all => "Test::Pod 1.45 required for testing POD" if $@;
    all_pod_files_ok();
    #
    #
    #
    return;
}
__END__

