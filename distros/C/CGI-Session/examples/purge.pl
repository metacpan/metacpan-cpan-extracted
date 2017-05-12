#!/usr/bin/perl

# $Id$

#
# This script can be installed as a cron-job to run at specific intervals
# to remove all expired session data from disk
#
use constant DSN        => 'driver:file';
use constant DSN_ARGS   => {};

use CGI::Session;

CGI::Session->find( DSN, sub {}, DSN_ARGS ) or die CGI::Session->errstr;

