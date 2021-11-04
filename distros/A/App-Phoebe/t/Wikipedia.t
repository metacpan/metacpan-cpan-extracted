# Copyright (C) 2021  Alex Schroeder <alex@gnu.org>
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
use utf8; # tests contain UTF-8 characters and it matters

our $base;
our $host;
our $port;
our @use = qw(Web Wikipedia);

plan skip_all => 'This is an author test. Set $ENV{TEST_AUTHOR} to a true value to run.' unless $ENV{TEST_AUTHOR};

# make sure starting phoebe starts knows localhost is the proxy
our @config = (<<'EOT');
package App::Phoebe::Wikipedia;
our $host = "localhost";
EOT

require './t/test.pl';

like(query_gemini("$base/"),
     qr/^10.*language/, "Top level is a prompt");
like(query_gemini("$base/?en"),
     qr/^30.*\/en\r\n/, "Redirect for the language");
like(query_gemini("$base/en"),
     qr/^10.*term/, "Search term prompt");
like(query_gemini("$base/en?Project%20Gemini"),
     qr/^30.*\/search\/en\/Project%20Gemini\r\n/, "Redirect for the term");

 SKIP: {
   skip "Making requests to Wikipedia requires \$ENV{TEST_AUTHOR} > 2", 2
       unless $ENV{TEST_AUTHOR} and $ENV{TEST_AUTHOR} > 2;

   like(query_gemini("$base/search/en/Project%20Gemini"),
	qr/^20/, "List of terms");
   like(query_gemini("$base/text/en/Project%20Gemini"),
	qr/^20/, "Term");

   # test cases from the logs
   like(query_gemini("$base/search/ja/%E3%83%AB%E3%82%B9%E3%83%84%E3%83%AA%E3%82%BE%E3%83%BC%E3%83%88"),
	qr/^20/, "Search Japanese term");
   like(query_gemini("$base/text/ja/%E3%83%AB%E3%82%B9%E3%83%84%E3%83%AA%E3%82%BE%E3%83%BC%E3%83%88"),
	qr/^20/, "Show Japanese term");
}

like(query_web("GET /text/en/Test HTTP/1.0\r\nHost: localhost"),
     qr/^HTTP\/1.1 301.*\r\nLocation: https:\/\/en.wikipedia.org\/wiki\/Test\r\n/, "Redirection to Wikipedia");

like(query_web("GET /text/en/Test HTTP/1.0\r\nX-host: none"),
     qr/^HTTP\/1.1 400/, "Error for borked request");

like(query_gemini("$base/page/Test"),
     qr/^20/, "Regular pages still get served");

done_testing;
