# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2015-09-21 10:19:13 +0100 (Mon, 21 Sep 2015) $ $Author: zerojinx $
# Id:            $Id: 00-distribution.t 470 2015-09-21 09:19:13Z zerojinx $
# Source:        $Source: /cvsroot/clearpress/clearpress/t/00-distribution.t,v $
# $HeadURL: svn+ssh://zerojinx@svn.code.sf.net/p/clearpress/code/trunk/t/00-distribution.t $
#
package distribution;
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);
use lib qw(t); use Net::LDAP;

our $VERSION = q[475.3.3];

eval {
  require Test::Distribution;
};

if($EVAL_ERROR) {
  plan skip_all => 'Test::Distribution not installed';
} else {
  Test::Distribution->import(); # Having issues with Test::Dist seeing my PREREQ_PM :(
}

1;
