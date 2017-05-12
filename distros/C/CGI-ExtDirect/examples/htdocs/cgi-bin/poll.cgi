#!/bin/sh

# The perl binary called below will need STDIN to read the script code;
# that mangles the actual CGI input for the script. To avoid that,
# we save STDIN here and reopen it later in the script.
exec 3<&0

# This construct is needed for the demo script to be executed by the
# same perl binary as p5httpd. You do not have to use this technique
# in your CGI scripts.
$PERL -x <<'END_OF_SCRIPT'

# The actual CGI script starts here
#!perl

use lib '../../../lib';

# This module provides demo Ext.Direct polling API
use RPC::ExtDirect::Demo::PollProvider;

use CGI::ExtDirect;

open STDIN, '<&=', 3 or die "Can't reopen STDIN";

my $direct = CGI::ExtDirect->new();

print $direct->poll();

exit 0;

END_OF_SCRIPT

