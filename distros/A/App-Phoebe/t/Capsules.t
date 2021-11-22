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
use List::Util qw(first);
use File::Slurper qw(read_binary);
use utf8;

our @use = qw(Capsules);

require './t/test.pl';

# variables set by test.pl
our $base;
our $host;
our $port;
our $dir;

my $haiku = <<"EOT";
On the red sofa
We both read our books at night
Winter nights are long
EOT

my $titan = "titan://$host:$port/capsule";

my $page = query_gemini("$base/capsule");
like($page, qr/^# Capsules/m, "Capsules");

my ($name) = $page =~ qr/^=> \S+ (\S+)/m;
ok($name, "Link to capsule");

$page = query_gemini("$base/capsule/$name");
like($page, qr/# $name/mi, "Title");
like($page, qr/^=> $base\/capsule\/$name\/upload/m, "Upload link");

$page = query_gemini("$base/capsule/$name/upload");
like($page, qr/^10 /, "Filename");

$page = query_gemini("$base/capsule/$name/upload?haiku.gmi");
like($page, qr/^30 $base\/capsule\/$name\/haiku\.gmi/, "Redirect");

$page = query_gemini("$base/capsule/$name/haiku.gmi");
like($page, qr/This file does not exist. Upload it using Titan!/, "Invitation");

# no client cert
$page = query_gemini("$titan/$name/haiku.gmi;size=71;mime=text/plain", $haiku, 0);
like($page, qr/^60 Uploading files requires a client certificate/, "Client certificate required");

$page = query_gemini("$titan/xxx/haiku.gmi;size=71;mime=text/plain", $haiku);
like($page, qr/^61 This is not your space/, "Wrong client certificate");

$page = query_gemini("$base/capsule/login", undef, 0);
like($page, qr/^60 You need a client certificate to access your capsule/, "Login without certificate");

$page = query_gemini("$base/capsule/login");
$page =~ qr/^30 $base\/capsule\/([a-z]+)\r\n/;
is($name, $1, "Login");

$page = query_gemini("$titan/$name/haiku.gmi;size=71;mime=text/plain", $haiku);
like($page, qr/^30 $base\/capsule\/$name/, "Saved haiku");

$page = query_gemini("$base/capsule/$name/haiku.gmi");
is($page, "20 text\/gemini\r\n$haiku", "Read haiku");

$page = query_gemini("$base/capsule/$name");
like($page, qr/^=> $base\/capsule\/$name\/haiku\.gmi haiku\.gmi/m, "List haiku");

# sharing and getting the temporary password

like($page, qr/^=> $base\/capsule\/$name\/share Share access/m, "Share link");

$page = query_gemini("$base/capsule/$name/share", undef, 0);
like($page, qr/^60 You need a client certificate/, "Sharing without certificate");

$page = query_gemini("$base/capsule/$name/share");
like($page, qr/^This password .*: (\S+)$/m, "Temporary password");
$page =~ qr/^This password .*: (\S+)$/m;
my $pwd = $1;
ok($pwd, "Password");

$page = query_gemini("$base/capsule/$name/share", undef, 2);
like($page, qr/^60 You need a different client certificate/, "Sharing with the wrong certificate");

# access using the temporary password

$page = query_gemini("$base/capsule/$name", undef, 2);
like($page, qr/^=> $base\/capsule\/$name\/access Access this capsule/m, "Access offered");

$page = query_gemini("$base/capsule/$name/access");
like($page, qr/^10/m, "Access requires password");

$page = query_gemini("$base/capsule/$name/access?$pwd", undef, 0);
like($page, qr/^60 You need a client certificate/, "Access without certificate");

$page = query_gemini("$base/capsule/$name/access?$pwd");
like($page, qr/^30 $base\/capsule\/$name/m, "Redirect to my own capsule");
ok(! -f "$dir/fingerprint_equivalents", "Fingerprint equivalents unnecessary");

$page = query_gemini("$base/capsule/$name/access?$pwd", undef, 2); # a different certificate
like($page, qr/^30 $base\/capsule\/$name/m, "Redirect to the same capsule");
ok(-f "$dir/fingerprint_equivalents", "Fingerprint equivalents saved");
like(read_text("$dir/fingerprint_equivalents"), qr/^sha256\S+ sha256\S+$/, "Fingerprint equivalents");

# testing the fingerprint equivalency

$page = query_gemini("$base/capsule/$name", undef, 2);
like($page, qr/# $name/mi, "Title");
like($page, qr/^=> $base\/capsule\/$name\/upload/m, "Equivalent upload link");

# test backup
ok(! -d "$dir/capsule/$name/backup", "No backup dir has been created");
ok(! -f "$dir/capsule/$name/backup/haiku.gmi", "No backup has been made");
my $ts = time - 1000;
is(utime($ts, $ts, "$dir/capsule/$name/haiku.gmi"), 1, "File backdated");

$haiku = <<"EOT";
Nervous late at night
Typing furiously, in vain
There's always a bug
EOT

$page = query_gemini("$titan/$name/haiku.gmi;size=69;mime=text/plain", $haiku);
like($page, qr/^30 $base\/capsule\/$name/, "Saved haiku");
ok(-d "$dir/capsule/$name/backup", "Backup dir has been created");
ok(-f "$dir/capsule/$name/backup/haiku.gmi", "Backup has been made");
like(read_text("$dir/capsule/$name/haiku.gmi"), qr/Nervous late at night/, "File saved");
like(read_text("$dir/capsule/$name/backup/haiku.gmi"), qr/On the red sofa/, "Backup saved");
$page = query_gemini("$base/capsule/$name/haiku.gmi");
like($page, qr/Nervous late at night/, "Current page");
$page = query_gemini("$base/capsule/$name/backup/haiku.gmi");
like($page, qr/On the red sofa/, "Backup page");

 SKIP: {
   -x '/bin/tar' or skip "Missing /bin/tar on this system";
   qx'/bin/tar --version' =~ /GNU tar/ or skip "No GNU tar on this system";

   $page = query_gemini("$base/capsule/$name/archive");
   like($page, qr/^20 application\/tar\r\n/m, "Download tar file");

   $page =~ s/^20 application\/tar\r\n//;
   my $tar = read_binary("$dir/capsule/$name/backup/data.tar.gz");
   ok($tar eq $page, "tar bytes are correct");

   open(my $fh, "tar --list --gzip --file $dir/capsule/$name/backup/data.tar.gz |");
   my @files = <$fh>;
   close($fh);
   ok((first { "$name/haiku.gmi\n" } @files), "Found haiku in the archive");
   ok((grep !/backup/, @files), "No backups in the archive (@files)");
}

# upload to the wrong place

$page = query_gemini("$titan/$name;size=69;mime=text/plain", $haiku);
like($page, qr/^59 The titan URL is missing the file name/, "Missing file name");

# upload the wrong MIME type

$page = query_gemini("$titan/$name/no-extension;size=69;mime=text/plain", $haiku);
like($page, qr/^59 The MIME type provided/, "Wrong file extension");

# delete file

$page = query_gemini("$base/capsule/$name");
like($page, qr/delete/, "Deleting files");
like($page, qr/haiku\.gmi/, "File listed");
$page = query_gemini("$base/capsule/$name/delete");
like($page, qr/^# Delete a file in $name/mi, "Deleting page header");
like($page, qr/^=> $base\/capsule\/$name\/delete\/haiku\.gmi/m, "Deleting page menu");
$page = query_gemini("$base/capsule/$name/delete/haiku.gmi");
like($page, qr/^30 $base\/capsule\/$name\r\n/, "Redirect after delete");
$page = query_gemini("$base/capsule/$name");
unlike($page, qr/haiku\.gmi/, "File listed");
$page = query_gemini("$base/capsule/$name/delete");
like($page, qr/^There are no files to delete/m, "No more files to delete");
ok(! -f "$dir/capsule/$name/haiku.gmi", "File is gone");
like(read_text("$dir/capsule/$name/backup/haiku.gmi"), qr/Nervous late at night/, "Backup saved");

done_testing;
