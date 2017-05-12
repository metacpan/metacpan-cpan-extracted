#!/usr/bin/perl5
#
# format_event - Read and format all the event monitor files in a
#                directory.  Unlike the IBM-supplied db2evfmt tool,
#                this works if the ctl file is missing and doesn't
#                require all the files to be present.
#
# $Id: format_events.pl,v 145.1 2007/10/17 14:45:08 biersma Exp $
#

use strict;
use Carp;
use DB2::Admin::EventParser;

my $parser = DB2::Admin::EventParser::->new('Directory' => '.');
while (my $event = $parser->GetEvent()) {
    print $event->Format(), "\n\n";
}
