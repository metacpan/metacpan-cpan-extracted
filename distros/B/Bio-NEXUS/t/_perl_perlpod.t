#!/usr/bin/perl -w

######################################################
# Author: Chengzhi Liang, Weigang Qiu, Peter Yang, Thomas Hladish, Brendan
# $Id: _perl_perlpod.t,v 1.5 2007/09/21 07:30:27 rvos Exp $
# $Revision: 1.5 $


# Written by Gopalan Vivek (gopalan@umbi.umd.edu)
# Refernce : http://www.perl.com/pub/a/2004/05/07/testing.html?page=2
# Date : 28th July 2006

use strict;
use warnings;
use Test::More;
eval "use Test::Pod";

plan skip_all => "Test::Pod required for testing POD" if $@;
all_pod_files_ok();
