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
use File::Slurper qw(read_text);

our $host;
our $port;
our $base;
our $dir;

require './t/test.pl';

my $titan = "titan://$host:$port";

my $haiku = <<EOT;
Smiling faces float
Tonight in the city park
Phone screens shining bright
EOT

my $page = query_gemini("$titan/raw/Haiku;size=74;mime=text/plain;token=hello", $haiku);
like($page, qr/^30 $base\/page\/Haiku\r$/, "Titan Haiku");

ok(read_text("$dir/page/Haiku.gmi") eq $haiku, "Haiku saved");

mkdir("$dir/locked");

local $SIG{'ALRM'} = sub {
  pass("Timeout 1s");
  ok(read_text("$dir/page/Haiku.gmi") eq $haiku, "Haiku unchanged");
  rmdir("$dir/locked");
};

alarm(1); # timeout

my $haiku2 = <<EOT;
Pink peaks and blue rocks
The sun is gone and I'm cold
The Blackbird still sings
EOT

# while it waits for the lock to expire, the 1s alarm is raised and the lock is
# removed
query_gemini("$titan/raw/Haiku;size=81;mime=text/plain;token=hello", $haiku2);

ok(read_text("$dir/page/Haiku.gmi") eq $haiku2, "Haiku changed");

done_testing(5);
