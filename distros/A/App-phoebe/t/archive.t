# Copyright (C) 2017–2020  Alex Schroeder <alex@gnu.org>
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

our $host;
our $port;
our $base;
our $dir;

require './t/test.pl';

mkdir("$dir/page");
write_text("$dir/page/Alex.gmi", "Alex Schroeder");
write_text("$dir/page/Haiku.gmi", "What a poet!");
mkdir("$dir/file");
write_binary("$dir/file/alex.jpg", read_binary("t/alex.jpg"));
mkdir("$dir/meta");
write_text("$dir/meta/alex.jpg", "content-type: image/jpeg");
write_text("$dir/index", join("\n", "Haiku", "Alex", ""));
write_text("$dir/changes.log",
	   join("\n",
		join("\x1f", 1593600755, "Alex", 1, 1441),
		join("\x1f", 1593610755, "alex.jpg", 0, 1441),
		join("\x1f", 1593620755, "Haiku", 1, 1441),
		""));

my $page = query_gemini("$base/");
like($page, qr/^=> $base\/do\/data Download data/m, "main menu contains download link");

$page = query_gemini("$base/do/data");
like($page, qr/^20 application\/tar\r\n/m, "download tar file");

$page =~ s/^20 application\/tar\r\n//;
my $tar = read_binary("$dir/data.tar.gz");
ok($tar eq $page, "tar bytes are correct");

open(my $fh, "tar --list --gzip --file $dir/data.tar.gz |");
my @files = <$fh>;
close($fh);
for my $file (qw(changes.log index config
	      meta/alex.jpg file/alex.jpg
	      page/Alex.gmi page/Haiku.gmi)) {
  ok(grep(/$file/, @files), "found $file in the archive");
}

# create a space

my $sdir = "$dir/berta";
mkdir($sdir);
mkdir("$sdir/page");
write_text("$sdir/page/Berta.gmi", "Berta Basler");
write_text("$sdir/page/Tanka.gmi", "What a poet!");
mkdir("$sdir/file");
write_binary("$sdir/file/berta.jpg", read_binary("t/alex.jpg"));
mkdir("$sdir/meta");
write_text("$sdir/meta/berta.jpg", "content-type: image/jpeg");
write_text("$sdir/index", join("\n", "Tanka", "Berta", ""));
write_text("$sdir/changes.log",
	   join("\n",
		join("\x1f", 1593600755, "Berta", 1, 1441),
		join("\x1f", 1593610755, "berta.jpg", 0, 1441),
		join("\x1f", 1593620755, "Tanka", 1, 1441),
		""));

done_testing();
