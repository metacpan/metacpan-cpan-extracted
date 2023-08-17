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

$t->get_ok('/news/article/local.test/1')
    ->status_is(200)
    ->text_like('pre', qr/Church bells are ringing/)
    ->element_exists('form[action="/news/reply"]')
    ->element_exists('input[name="id"][value="<1@example.com>"]')
    ->element_exists('input[name="group"][value="local.test"]')
    ->element_exists('input[name="references"][value="<1@example.com>"]')
    ->element_exists('input[name="subject"][value="Re: Haiku"]')
    ->element_exists('input[name="body"][value="Poet, 1998-10-06 04:38:' . "\n"
                     . "> Tin is my reader\n"
                     . "> A program from the nineties\n"
                     . "> Church bells are ringing\n\"]")
    ->element_exists('form input[type="submit"]');

$t->post_ok('/news/reply' => form => {
  id => '<1@example.com>',
  group => 'local.test',
  references => '<1@example.com>',
  subject => 'Re: Haiku',
  body => "Poet, 1998-10-06 04:38:\n"
      . "> Tin is my reader\n"
      . "> A program from the nineties\n"
      . "> Church bells are ringing\n"})
    ->status_is(200)
    ->element_exists('form[action="/news/post"]');

$t->post_ok('/news/post' => form => {
  id => '<1@example.com>',
  username => 'alex',
  password => 'test',
  name => 'Alex <alex@example.org>',
  group => 'local.test',
  references => '<1@example.com>',
  subject => 'Re: Haiku',
  body => "Nice."})
    ->status_is(200)
    ->text_like('h1', qr'Posted!');

# warn $t->tx->res->body;
done_testing;
