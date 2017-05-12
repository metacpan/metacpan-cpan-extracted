#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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
use Test::More tests => 1;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Gtk2::Job;

ok(1);
# {
#   my $self = {};
#   my $message = '';
#   $App::Chart::Gtk2::Job::message = sub { $message .= $_[0]; };
#   my $status;
# 
#   $status = App::Chart::Gtk2::Job::_parse_incoming ($self, $status,
#                                              "foo");
#   is ($message, 'foo');
#   ok (! defined $status);
# 
#   $status = App::Chart::Gtk2::Job::_parse_incoming ($self, $status,
#                                              "\x{01}bar\x{02}");
#   is ($message, 'foo');
#   is ($status, 'bar');
# 
#   $status = App::Chart::Gtk2::Job::_parse_incoming ($self, $status,
#                                              "one\x{01}two\x{02}three");
#   is ($message, 'fooonethree');
#   is ($status, 'two');
# 
#   $message = '';
#   $status = App::Chart::Gtk2::Job::_parse_incoming ($self, $status,
#                                              "a\x{01}b\x{02}c\x{01}d\x{02}e");
#   is ($message, 'ace');
#   is ($status, 'd');
# 
#   $message = '';
#   $status = undef;
#   $status = App::Chart::Gtk2::Job::_parse_incoming ($self, $status, "a\x{01}part");
#   is ($message, 'a');
#   ok (! defined $status);
#   $status = App::Chart::Gtk2::Job::_parse_incoming ($self, $status, "end\x{02}text");
#   is ($message, 'atext');
#   is ($status, 'partend');
# }

exit 0;

