#!/usr/bin/perl

BEGIN {
	use Apache();
	use lib Apache->server_root_relative ( 'lib/perl' );
}

use Apache::Registry();
use Apache::Constants();
use CGI qw(-compile :all);
use CGI::Carp();

require Apache::Toe;
Apache->push_handlers ( PerlChildInitHandler => \&Apache::Toe::childinit );

1;
