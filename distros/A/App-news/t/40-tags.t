# Copyright (C) 2021–2023  Alex Schroeder <alex@gnu.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use Modern::Perl;
use Test::More;
use Test::Mojo;
use List::Util qw(first);

our $port;
require './t/test.pl';

diag "Starting News Client on $port";
$ENV{NNTPSERVER} = "localhost:$port";

my $t = Test::Mojo->new(Mojo::File->new('script/news'));

$t->get_ok('/news/tag/local.introductions/hello?include=4')
    ->status_is(200)
    ->text_is('tr:nth-child(3) td.subject', "I don't know what I'm doing")
    ->text_is('tr:nth-child(5) td.subject', "What's up?")
    ->text_is('tr:nth-child(7) td.subject', "I'm new");

# warn $t->tx->res->body;
done_testing;
