#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin;

use lib $FindBin::Bin;

use HelloWorld;

# CouchDB local.ini:
#
#   [external]
#   hello = /path/to/helloWorld.pl
#
#   [httpd_db_handlers]
#   _hello = {couch_httpd_external, handle_external_req, <<"hello">>}
#
# Then go to the url, where "database" is one of your databases:
# 
#   http://yourserver/database/_hello/hello_world
#
# And even:
#
#   http://yourserver/database/_hello/hello_world?greeting_target=Dude

HelloWorld->new->run;
