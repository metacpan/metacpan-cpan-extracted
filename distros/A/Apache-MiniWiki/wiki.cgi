#!/usr/bin/perl -wT
#
#  Copyright (C) 2002  Wim Kerkhoff <kerw@cpan.org>
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
use strict;

use Apache ();
use Apache::MiniWiki ();

# obtain a reference to the Apache request object
my $r = Apache->request;

# define some variables... normally these are defined
# by PerlSetVar <name> <value> in httpd.conf
$r->dir_config->add(datadir => '/home/foo/db/wiki/');
$r->dir_config->add(vroot => '/cgi-bin/wiki.cgi');

# call the mod_perl handler, passing the request object as an argument
Apache::MiniWiki::handler($r);
