#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use App::Chart::UserAgent;
use Data::Dumper;

print "Agent '",App::Chart::UserAgent->_agent,"'\n";

my $ua = App::Chart::UserAgent->instance;

{
  # my $req = HTTP::Request->new (GET => 'http://localhost/bare2.html');
  my $req = HTTP::Request->new (GET => 'http://localhost/x');
  $ua->prepare_request ($req);
  print $req->as_string;
  my $resp = $ua->request ($req);
  print $resp->as_string;
  exit 0;
}

