#!/usr/bin/env perl

# Copyright (C) 2021 Alex Schroeder <alex@gnu.org>

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

use Modern::Perl;
use Test::More;
use Test::Mojo;

# Note to self, this is how to print the actual result:
# die $t->get_ok('/')->tx->res->body;
# die $t->get_ok('/')->tx->res->headers->to_string;

require './script/traveller';

my $t = Test::Mojo->new();

$t->get_ok('/')->status_is(302)->header_is(Location => '/edit');
$t->get_ok('/edit')->status_is(200)->text_is('h1' => 'Traveller Subsector Generator');

my $location = $t->get_ok('/random/sector')->status_is(302)->tx->res->headers->location;
$t->get_ok($location)->status_is(200)->text_like('h1' => qr/Traveller Sector UWP List Generator \(\d+\)/);

done_testing;
