#!/usr/bin/perl
################################################################################
#
# File:     00_pod_coverage.t
# Date:     2012-08-05
# Author:   H. Klausing (h.klausing (at) gmx.de)
#
# Description:
#   Tests for POD coverage.
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
use Test::Pod::Coverage tests => 1;

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
    my $trustme = {trustme => [qr/^(decrementItems|incrementItems|prepareReturnList|setItems)$/]};
    pod_coverage_ok("Array::CompareAndFilter", $trustme);
    #
    #
    #
    return;
}
__END__

