#!/usr/bin/env perl

# Copyright (C) 2015-2016  Alex Schroeder <alex@gnu.org>

# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <http://www.gnu.org/licenses/>.

use Mojolicious::Lite;

# This needs to be in a different section, sometimes?
plugin CGI => {
  support_semicolon_in_query_string => 1,
};

plugin CGI => {
  route => '/wiki',
  run => \&OddMuse::DoWikiRequest,
};

get '/' => sub {
  my $self = shift;
  $self->redirect_to('/wiki');
};

app->start;
