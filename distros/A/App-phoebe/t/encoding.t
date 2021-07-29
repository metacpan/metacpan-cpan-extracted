# Copyright (C) 2017–2021  Alex Schroeder <alex@gnu.org>
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
use File::Slurper qw(write_text read_binary);
use Net::IDN::Encode qw(domain_to_ascii);
use Encode qw(encode_utf8 decode_utf8);
use URI::Escape;
use utf8; # tests contain UTF-8 characters and it matters

my $idn = "東京.jp";
our @hosts = ("localhost", $idn);
our $port;
our $base;
our $dir;

require './t/test.pl';

# upload text

my $titan = "titan://$hosts[0]:$port";

my $name = "日本語";
my $encoded_name = uri_escape_utf8($name);
my $text = <<EOT;
Schröder answered: ｢郵便局｣
EOT
my $encoded_text = encode_utf8($text);
my $length = length($encoded_text);

my $page = query_gemini("$titan/raw/$encoded_name;size=$length;mime=text/plain;token=hello", $encoded_text);
like($page, qr/^30 $base\/page\/$encoded_name\r$/, "Titan Text");

$page = query_gemini("$base/page/$encoded_name");
like($page, qr/^20 text\/gemini; charset=UTF-8\r\n# $name\n$text/, "Text saved");

my $punycode = domain_to_ascii($idn);

$base = encode_utf8 "gemini://$punycode:$port";
$titan = encode_utf8 "titan://$punycode:$port";

 SKIP: {
   skip "Locale cannot handle test data", 3 unless decode(locale => encode(locale => $name)) eq $name;

   $page = query_gemini("$base/page/$encoded_name");
   like($page, qr/# 日本語\nThis page does not yet exist/, "International Domain Name");

   $page = query_gemini("$titan/raw/$encoded_name;size=$length;mime=text/plain;token=hello", $encoded_text);
   like($page, qr/^30 $base\/page\/$encoded_name\r$/, "Titan Text");

   $page = query_gemini("$base/page/$encoded_name");
   like($page, qr/^20 text\/gemini; charset=UTF-8\r\n# $name\n$text/, "Text saved");
}

done_testing();
