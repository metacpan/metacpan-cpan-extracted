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
use File::Slurper qw(write_text write_binary read_binary);
use utf8; # tests contain UTF-8 characters and it matters
use List::Util qw(first);
use URI::Escape;

plan skip_all => 'This is an author test. Set $ENV{TEST_AUTHOR} to a true value to run.' unless $ENV{TEST_AUTHOR};
plan skip_all => 'This test requires HTTP::DAV.' unless eval { require HTTP::DAV };

our @use = qw(WebDAV);
our @spaces = qw(test);
our $host;
our $port;
our $dir;

require './t/test.pl';

# Make sure the user agent doesn't check hostname and cert validity
my $dav = HTTP::DAV->new();
my $ua = $dav->get_user_agent();
$ua->ssl_opts(SSL_verify_mode => 0x00);
$ua->ssl_opts(verify_hostname => 0);

# Open a fresh wiki
ok($dav->open(-url => "https://$host:$port/"), "Open URL: " . $dav->message);

# Check options
for my $d (qw(/ /page /page/ /raw /raw/ /file /file/)) {
  my $options = $dav->options(-url => "https://$host:$port$d");
  for my $op (qw(OPTIONS PROPFIND)) {
    like($options, qr/$op/, "$op supported for $d");
  }
  for my $op (qw(GET PUT DELETE)) {
    unlike($options, qr/$op/, "$op not supported for $d");
  }
}
for my $d (qw(/page/x)) {
  my $options = $dav->options(-url => "https://$host:$port$d");
  for my $op (qw(OPTIONS PROPFIND GET)) {
    like($options, qr/$op/, "$op supported for $d");
  }
  for my $op (qw(PUT DELETE)) {
    unlike($options, qr/$op/, "$op not supported for $d");
  }
}
for my $d (qw(/raw/x /file/x)) {
  my $options = $dav->options(-url => "https://$host:$port$d");
  for my $op (qw(OPTIONS PROPFIND PUT GET DELETE)) {
    like($options, qr/$op/, "$op supported for $d");
  }
}

# Read directories
my $resource = $dav->propfind(-url=>"/", -depth=>1);
ok($resource && $resource->is_collection, "Found /");
my @list = $resource->get_resourcelist->get_resources;
my $item = first { $_->get_uri->path eq "/page/" } @list;
ok($item && $item->is_collection, "Found /page");
$item = first { $_->get_uri->path eq "/raw/" } @list;
ok($item && $item->is_collection, "Found /raw");
$item = first { $_->get_uri->path eq "/file/" } @list;
ok($item && $item->is_collection, "Found /files");

# Attempt to write a file without credentials
my $str = "Ganymede\n";
ok(not($dav->put(-local=>\$str, -url=>"https://$host:$port/raw/M%C3%B6%C3%B6n")),
   "Failed to post without token");

# Retry with credentials
$dav->credentials(-user => "alex", -pass => "hello", -realm => "Phoebe");
ok($dav->put(-local=>\$str, -url=>"https://$host:$port/raw/M%C3%B6%C3%B6n"),
   "Post gemtext with token");

# /raw
$resource = $dav->propfind(-url=>"/raw", -depth=>1);
ok($resource && $resource->is_collection, "Found /raw");
@list = $resource->get_resourcelist->get_resources;
$item = first { decode_utf8(uri_unescape($_->get_uri->path)) eq "/raw/Möön" } @list;

ok($item && !$item->is_collection, "Found /raw/Moon");
$str = undef;
$dav->get(-url=>"/raw/M%C3%B6%C3%B6n", -to=>\$str);
like($str, qr/^Ganymede/, "Moon retrieved");

# /page
$resource = $dav->propfind(-url=>"/page", -depth=>1);
ok($resource && $resource->is_collection, "Found /page");
@list = $resource->get_resourcelist->get_resources;
$item = first { decode_utf8(uri_unescape($_->get_uri->path)) eq "/page/Möön" } @list;
ok($item && !$item->is_collection, "Found /page/Moon.html");
$str = undef;
$dav->get(-url=>"/page/M%C3%B6%C3%B6n", -to=>\$str);
like($str, qr/<p>Ganymede/, "Moon retrieved");

# delete page
$resource = $dav->delete(-url=>"/raw/M%C3%B6%C3%B6n");
$resource = $dav->propfind(-url=>"/raw", -depth=>1);
@list = $resource->get_resourcelist;
is(1, scalar(@list), "No more pages"); # just /raw itself

# Upload a file
ok($dav->put(-local=>"t/alex.jpg", -url=>"https://$host:$port/file/Alex"),
   "Post file with token");
my $data;
$dav->get(-url=>"/file/Alex", -to=>\$data);
is($data, read_binary("t/alex.jpg"), "Alex retrieved");

# delete file
$resource = $dav->delete(-url=>"/file/Alex");
$resource = $dav->propfind(-url=>"/file", -depth=>1);
@list = $resource->get_resourcelist;
is(1, scalar(@list), "No more files"); # just /file itself

# Open a wiki space
ok($dav->open(-url => "https://$host:$port/test"), "Open URL: " . $dav->message);
$resource = $dav->propfind(-url=>".", -depth=>1);
ok($resource && $resource->is_collection, "Found /test");
@list = $resource->get_resourcelist->get_resources;
$item = first { $_->get_uri->path eq "/test/page/" } @list;
ok($item && $item->is_collection, "Found /test/page");
$item = first { $_->get_uri->path eq "/test/raw/" } @list;
ok($item && $item->is_collection, "Found /test/raw");
$item = first { $_->get_uri->path eq "/test/file/" } @list;
ok($item && $item->is_collection, "Found /test/files");

# Write a page
$str = "Callisto\n";
ok($dav->put(-local=>\$str, -url=>"https://$host:$port/test/raw/M%C3%B6%C3%B6n"),
   "Post gemtext with token");

# /raw
$resource = $dav->propfind(-url=>"/test/raw", -depth=>1);
ok($resource && $resource->is_collection, "Found /test/raw");
@list = $resource->get_resourcelist->get_resources;
$item = first { decode_utf8(uri_unescape($_->get_uri->path)) eq "/test/raw/Möön" } @list;
ok($item && !$item->is_collection, "Found /test/raw/Moon.gmi");
$str = undef;
$dav->get(-url=>"/test/raw/M%C3%B6%C3%B6n", -to=>\$str);
like($str, qr/^Callisto/, "Moon retrieved");

# /page
$resource = $dav->propfind(-url=>"/test/page", -depth=>1);
ok($resource && $resource->is_collection, "Found /test/page");
@list = $resource->get_resourcelist->get_resources;
$item = first { decode_utf8(uri_unescape($_->get_uri->path)) eq "/test/page/Möön" } @list;
ok($item && !$item->is_collection, "Found /test/page/Moon.html");
$str = undef;
$dav->get(-url=>"/test/page/M%C3%B6%C3%B6n", -to=>\$str);
like($str, qr/<p>Callisto/, "Moon retrieved");

# copy page
$resource = $dav->copy(-url=>"/test/raw/M%C3%B6%C3%B6n", -dest=>"/raw/M%C3%B6%C3%B6n");
$resource = $dav->propfind(-url=>"/raw", -depth=>1);
ok($resource && $resource->is_collection, "Found /raw");
@list = $resource->get_resourcelist->get_resources;
$item = first { decode_utf8(uri_unescape($_->get_uri->path)) eq "/raw/Möön" } @list;
ok($item && !$item->is_collection, "Found /raw/Moon.gmi");
$str = undef;
$dav->get(-url=>"/raw/M%C3%B6%C3%B6n", -to=>\$str);
like($str, qr/^Callisto/, "Moon retrieved");

# delete page
$resource = $dav->delete(-url=>"/test/raw/M%C3%B6%C3%B6n");
$resource = $dav->propfind(-url=>"/test/raw", -depth=>1);
@list = $resource->get_resourcelist;
is(1, scalar(@list), "No more pages"); # just /test/raw itself

# Upload a file
ok($dav->put(-local=>"t/alex.jpg", -url=>"https://$host:$port/test/file/Alex"),
   "Post file with token");
$dav->get(-url=>"/test/file/Alex", -to=>\$data);
is($data, read_binary("t/alex.jpg"), "Alex retrieved");

# delete file
$resource = $dav->delete(-url=>"/test/file/Alex");
$resource = $dav->propfind(-url=>"/test/file", -depth=>1);
@list = $resource->get_resourcelist;
is(1, scalar(@list), "No more files"); # just /test/file itself

# move page
$resource = $dav->move(-url=>"/raw/M%C3%B6%C3%B6n", -dest=>"/test/raw/M%C3%B6%C3%B6n");
$resource = $dav->propfind(-url=>"/raw", -depth=>1);
@list = $resource->get_resourcelist;
is(1, scalar(@list), "No more pages"); # just /raw itself
$resource = $dav->propfind(-url=>"/test/raw", -depth=>1);
ok($resource && $resource->is_collection, "Found /test/raw");
@list = $resource->get_resourcelist->get_resources;
$item = first { decode_utf8(uri_unescape($_->get_uri->path)) eq "/test/raw/Möön" } @list;
ok($item && !$item->is_collection, "Found /test/raw/Moon.gmi");
$str = undef;
$dav->get(-url=>"/test/raw/M%C3%B6%C3%B6n", -to=>\$str);
like($str, qr/^Callisto/, "Moon retrieved");

done_testing();
