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

# These modules provide demo Ext.Direct remoting and polling APIs
use RPC::ExtDirect::Demo::TestAction;
use RPC::ExtDirect::Demo::Profile;
use RPC::ExtDirect::Demo::PollProvider;

use RPC::ExtDirect::Config;
use CGI::ExtDirect;

open STDIN, '<&=', 3 or die "Can't reopen STDIN";

my $config = RPC::ExtDirect::Config->new(
    router_path => '/cgi-bin/router.cgi',
    poll_path   => '/cgi-bin/poll.cgi',
);

my $direct = CGI::ExtDirect->new( config => $config );

print $direct->api();

exit 0;

END_OF_SCRIPT

