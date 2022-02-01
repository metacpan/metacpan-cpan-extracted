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
use utf8; # tests contain UTF-8 characters and it matters

our $host;
our $port;
our $base;
our $dir;
our @pages = qw(Alex Berta Chris);

require './t/test.pl';

# robots
my $page = query_gemini("$base/robots.txt");
for (qw(/raw /html /diff /history /do/changes /do/all/changes /do/all/latest/changes /do/rss /do/atom /do/new /do/more /do/match /do/search)) {
  my $url = quotemeta;
  like($page, qr/^Disallow: $url/m, "Robots are disallowed from $url");
}

# redirect of reserved word
$page = query_gemini("$base/do");
is($page, "31 $base/\r\n", "Redirect reserved word");

# main menu
$page = query_gemini("$base/");

unlike($page, qr/^=> .*\/$/m, "No empty links in the menu");

# --wiki_page
for my $item(qw(Alex Berta Chris)) {
  like($page, qr/^=> $base\/page\/$item $item/m, "main menu contains $item");
}

# upload text

my $titan = "titan://$host:$port";

my $haiku = <<EOT;
Quiet disk ratling
Keyboard clicking, then it stops.
Rain falls and I think
EOT

$page = query_gemini("$titan/raw/Haiku;size=76;mime=text/plain;token=hello", $haiku);
like($page, qr/^30 $base\/page\/Haiku\r$/, "Titan Haiku");

$page = query_gemini("$base/page/Haiku");
like($page, qr/^20 text\/gemini; charset=UTF-8\r\n# Haiku\n$haiku/, "Haiku saved");

# no MIME type

$haiku = <<EOT;
The warm oven hums
The fresh bread too hot to touch
The smell is heaven
EOT

# plain text

$page = query_gemini("$titan/raw/Bread;size=72;token=hello", $haiku);
like($page, qr/^30 $base\/page\/Bread\r$/, "Bread haiku without MIME type");

$page = query_gemini("$base/page/Bread");
like($page, qr/^20 text\/gemini; charset=UTF-8\r\n# Bread\n$haiku/, "Bread haiku saved");

# upload image

my $data = read_binary("t/alex.jpg");
my $size = length($data);
$page = query_gemini("$titan/raw/Alex;size=$size;token=hello", $data);
like($page, qr/^59 The text is invalid UTF-8/, "Upload image without MIME type");
$page = query_gemini("$titan/raw/Alex;size=$size;mime=image/png;token=hello", $data);
like($page, qr/^59 This wiki does not allow image\/png/, "Upload image with wrong MIME type");
$page = query_gemini("$base/page/Alex");
like($page, qr/This page does not yet exist/, "Save of unsupported MIME type failed");

$page = query_gemini("$titan/raw/Alex;size=$size;mime=image/jpeg;token=hello", $data);
like($page, qr/^30 $base\/file\/Alex\r/, "Upload image");

# fake creation of some files for the blog

for (qw(2017-12-25 2017-12-26 2017-12-27)) {
  write_text("$dir/page/$_.gmi", "yo");
  unlink("$dir/index");
}

# blog on the main page
$page = query_gemini("$base/");
for my $item(qw(2017-12-25 2017-12-26 2017-12-27)) {
  like($page, qr/^=> $base\/page\/$item $item/m, "main menu contains $item");
}

# history

$haiku = <<EOT;
Muffled honking cars
Keyboard clicking, then it stops.
Rain falls and I think
EOT

$page = query_gemini("$titan/raw/Haiku;size=78;mime=text/plain;token=hello", $haiku);
like($page, qr/^30 $base\/page\/Haiku\r$/, "Titan Haiku 2");

$page = query_gemini("$base/history/Haiku");
like($page, qr/^=> $base\/page\/Haiku\/1 Haiku \(1\)/m, "Revision 1 is listed");
like($page, qr/^=> $base\/diff\/Haiku\/1 Diff/m, "Diff 1 link");
like($page, qr/^=> $base\/page\/Haiku Haiku \(current\)/m, "Current revision is listed");
$page = query_gemini("$base/page/Haiku/1");
like($page, qr/Quiet disk ratling/m, "Revision 1 content");

# diffs
$page = query_gemini("$base/diff/Haiku/1");
like($page, qr/^> ｢Quiet disk ratling｣$/m, "Removed content, per line");
like($page, qr/^> ｢Muffled honking cars｣$/sm, "Added content, per line");

# colour diffs
$page = query_gemini("$base/diff/Haiku/1/colour");
like($page, qr/^> \e\[31m\e\[1mQuiet disk ratling\e\[22m\e\[0m/m, "Removed content, per line");
like($page, qr/^> \e\[32m\e\[1mMuffled honking cars\e\[22m\e\[0m\n$/sm, "Added content");

# colour changes leads to colour history and colour diffs
$page = query_gemini("$base/do/changes/10/fancy");
like($page, qr/\e\[38;/, "Fancy changes");
like($page, qr/^=> $base\/history\/Haiku\/10\/fancy History/m, "Fancy history link");
$page = query_gemini("$base/history/Haiku/10/fancy");
like($page, qr/\e\[38;/, "Fancy history");
like($page, qr/^=> $base\/diff\/Haiku\/1\/colour Differences/m, "Fancy diff link");
$page = query_gemini("$base/diff/Haiku/1/colour"); # there is no fancy diff, just colour diff
like($page, qr/\e\[32m/, "Fancy diff");

$haiku = <<EOT;
Muffled spinning disk
random clicking, then it stops.
Rain falls and I think
EOT

$page = query_gemini("$titan/raw/Haiku;size=77;mime=text/plain;token=hello", $haiku);
like($page, qr/^30 $base\/page\/Haiku\r$/, "Titan Haiku 3");

# diffs accross lines
$page = query_gemini("$base/diff/Haiku/2");
like($page, qr/^> Muffled ｢honking cars｣$/m, "Removed content, partial line");
like($page, qr/^> ｢Keyboard ｣clicking, then it stops\.$/m, "Removed content, partial line");
like($page, qr/^> Muffled ｢spinning disk｣$/sm, "Added content, partial line");
like($page, qr/^> ｢random ｣clicking, then it stops\.$/sm, "Added content, partial line");

$haiku = <<EOT;
Muffled spinning disk
electronic humming just
for us...

I think
EOT

$page = query_gemini("$titan/raw/Haiku;size=65;mime=text/plain;token=hello", $haiku);
like($page, qr/^30 $base\/page\/Haiku\r$/, "Titan Haiku 4"); # not really a haiku anymore…

# diffs accross paragraphs
$page = query_gemini("$base/diff/Haiku/3");
like($page, qr/^> ｢random clicking, then it stops\.｣$/m, "Added content, paragraph");
like($page, qr/^> ｢Rain falls and ｣I think$/m, "Added content, paragraph");
like($page, qr/^> ｢electronic humming just｣$/m, "Added content, paragraph");
like($page, qr/^> ｢for us\.\.\.｣$/m, "Added content, paragraph");
like($page, qr/^> ⏎$/m, "Added content, paragraph");
like($page, qr/^> I think$/m, "Added content, paragraph");

# index
$page = query_gemini("$base/do/index");
for my $item(qw(2017-12-25 2017-12-26 2017-12-27 Haiku)) {
  like($page, qr/^=> $base\/page\/$item $item$/m, "index contains $item");
}

# files
$page = query_gemini("$base/do/files");
for my $item(qw(Alex)) {
  like($page, qr/^=> $base\/file\/$item $item$/m, "files contains $item");
}

# match
$page = query_gemini("$base/do/match?2017");
for my $item(qw(2017-12-25 2017-12-26 2017-12-27)) {
  like($page, qr/^=> $base\/page\/$item $item$/m, "match menu contains $item");
}
like($page, qr/2017-12-27.*2017-12-26.*2017-12-25/s,
     "match menu sorted newest first");

# search
$page = query_gemini("$base/do/search?yo");
for my $item(qw(2017-12-25 2017-12-26 2017-12-27)) {
  like($page, qr/^=> $base\/page\/$item $item/m, "search menu contains $item");
}
like($page, qr/2017-12-27.*2017-12-26.*2017-12-25/s,
     "search menu sorted newest first");

# handle + in queries
like(query_gemini("$base/do/match?with+space"), qr/^# Search page titles for with space/m, "Space");

# changes
$page = query_gemini("$base/do/changes");
like($page, qr/^=> $base\/page\/Haiku Haiku \(current\)/m, "Current revision of Haiku in recent changes");
like($page, qr/^=> $base\/page\/Haiku\/1 Haiku \(1\)/m, "Older revision of Haiku in recent changes");

# delete page
$page = query_gemini("$titan/raw/Haiku;size=0;mime=text/plain;token=hello", "");
like($page, qr/^30 $base\/page\/Haiku\r$/, "Titan Haiku delete");
$page = query_gemini("$base/page/Haiku");
like($page, qr/This page does not yet exist/, "Page no longer exists");
$page = query_gemini("$base/do/changes");
like($page, qr/^=> $base\/page\/Haiku Haiku \(deleted\)/m, "Current revision of Haiku was deleted");
$page = query_gemini("$base/do/index");
unlike($page, qr/Haiku/, "Haiku is no longer in the index");
like($page, qr/2017-12-27\n.*2017-12-26\n.*2017-12-25\n/,
     "index still has pages separated by newlines");

# delete file
$page = query_gemini("$titan/raw/Alex;size=0;mime=image/jpeg;token=hello", "");
like($page, qr/^The file was deleted\./m, "Image Alex delete");
$page = query_gemini("$base/file/Alex");
like($page, qr/^40 /, "File no longer exists");
$page = query_gemini("$base/do/changes");
like($page, qr/^Alex \(deleted file\)/m, "Alex was deleted");

done_testing();
