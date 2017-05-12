#!/bin/perl
#
# @(#)$Id: t98pod.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
# Check the POD files for DBD::Informix
#
# Copyright 2003-14 Jonathan Leffler

use Test::Pod tests => 10;
use strict;
use warnings;

my $prefix = "./blib/lib";

my @podlist = (
    "Bundle/DBD/Informix.pm",
    "DBD/Informix.pm",
    "DBD/Informix/Configure.pm",
    "DBD/Informix/Defaults.pm",
    "DBD/Informix/GetInfo.pm",
    "DBD/Informix/Metadata.pm",
    "DBD/Informix/Summary.pm",
    "DBD/Informix/TechSupport.pm",
    "DBD/Informix/TestHarness.pm",
    "DBD/Informix/TypeInfo.pm"
);

foreach my $name (@podlist)
{
    my $file = "$prefix/$name";
    my $test = $name;
    $test =~ s%/%::%go;
    $test =~ s%\.pm$%%o;
    pod_file_ok($file, "POD for $test");
}
