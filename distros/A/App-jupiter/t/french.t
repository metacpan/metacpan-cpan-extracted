# Copyright (C) 2021  Alex Schroeder <alex@gnu.org>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

package Jupiter;
use Modern::Perl;
use Test::More tests => 58;

require './script/jupiter';

# test data from https://nonobstant.cafe/podcast/rss/

is(french("mar., 10 nov. 2020 18:14:00 +0100"), "Tue, 10 Nov 2020 18:14:00 +0100");

my $doc = XML::LibXML->load_xml(string => <<'EOT');
<test>
<entry><pubDate>mar., 06 avr. 2021 07:38:50 +0200</pubDate></entry>
<entry><pubDate>mar., 30 mars 2021 14:56:35 +0200</pubDate></entry>
<entry><pubDate>mer., 24 mars 2021 13:10:07 +0100</pubDate></entry>
<entry><pubDate>sam., 20 mars 2021 11:46:34 +0100</pubDate></entry>
<entry><pubDate>mar., 16 mars 2021 07:14:55 +0100</pubDate></entry>
<entry><pubDate>lun., 08 mars 2021 22:18:11 +0100</pubDate></entry>
<entry><pubDate>lun., 01 mars 2021 19:27:08 +0100</pubDate></entry>
<entry><pubDate>lun., 22 févr. 2021 21:17:57 +0100</pubDate></entry>
<entry><pubDate>lun., 15 févr. 2021 15:46:59 +0100</pubDate></entry>
<entry><pubDate>mar., 02 févr. 2021 17:28:28 +0100</pubDate></entry>
<entry><pubDate>mer., 27 janv. 2021 17:07:17 +0100</pubDate></entry>
<entry><pubDate>ven., 22 janv. 2021 18:21:28 +0100</pubDate></entry>
<entry><pubDate>lun., 18 janv. 2021 07:18:35 +0100</pubDate></entry>
<entry><pubDate>lun., 11 janv. 2021 18:02:44 +0100</pubDate></entry>
<entry><pubDate>lun., 04 janv. 2021 07:21:34 +0100</pubDate></entry>
<entry><pubDate>mer., 30 déc. 2020 09:02:22 +0100</pubDate></entry>
<entry><pubDate>jeu., 24 déc. 2020 08:11:35 +0100</pubDate></entry>
<entry><pubDate>sam., 19 déc. 2020 14:56:12 +0100</pubDate></entry>
<entry><pubDate>lun., 07 déc. 2020 19:03:57 +0100</pubDate></entry>
<entry><pubDate>dim., 29 nov. 2020 23:47:26 +0100</pubDate></entry>
<entry><pubDate>jeu., 26 nov. 2020 07:12:26 +0100</pubDate></entry>
<entry><pubDate>lun., 16 nov. 2020 16:04:26 +0100</pubDate></entry>
<entry><pubDate>mar., 10 nov. 2020 18:14:00 +0100</pubDate></entry>
<entry><pubDate>ven., 06 nov. 2020 09:59:30 +0100</pubDate></entry>
<entry><pubDate>jeu., 05 nov. 2020 16:31:27 +0100</pubDate></entry>
<entry><pubDate>jeu., 29 oct. 2020 12:18:30 +0100</pubDate></entry>
<entry><pubDate>dim., 25 oct. 2020 18:32:09 +0100</pubDate></entry>
<entry><pubDate>sam., 24 oct. 2020 15:22:43 +0200</pubDate></entry>
<entry><pubDate>jeu., 22 oct. 2020 06:37:30 +0200</pubDate></entry>
<entry><pubDate>lun., 19 oct. 2020 21:13:32 +0200</pubDate></entry>
<entry><pubDate>mer., 14 oct. 2020 10:23:03 +0200</pubDate></entry>
<entry><pubDate>lun., 05 oct. 2020 17:24:14 +0200</pubDate></entry>
<entry><pubDate>mer., 30 sept. 2020 14:18:02 +0200</pubDate></entry>
<entry><pubDate>lun., 21 sept. 2020 11:28:28 +0200</pubDate></entry>
<entry><pubDate>lun., 14 sept. 2020 08:34:36 +0200</pubDate></entry>
<entry><pubDate>lun., 07 sept. 2020 09:02:36 +0200</pubDate></entry>
<entry><pubDate>lun., 31 août 2020 21:07:18 +0200</pubDate></entry>
<entry><pubDate>dim., 23 août 2020 19:09:11 +0200</pubDate></entry>
<entry><pubDate>lun., 17 août 2020 11:04:04 +0200</pubDate></entry>
<entry><pubDate>dim., 09 août 2020 18:37:11 +0200</pubDate></entry>
<entry><pubDate>lun., 03 août 2020 12:40:40 +0200</pubDate></entry>
<entry><pubDate>mer., 29 juil. 2020 14:56:54 +0200</pubDate></entry>
<entry><pubDate>dim., 19 juil. 2020 16:13:48 +0200</pubDate></entry>
<entry><pubDate>dim., 12 juil. 2020 15:42:44 +0200</pubDate></entry>
<entry><pubDate>dim., 05 juil. 2020 16:17:51 +0200</pubDate></entry>
<entry><pubDate>dim., 28 juin 2020 14:15:52 +0200</pubDate></entry>
<entry><pubDate>mar., 23 juin 2020 17:03:22 +0200</pubDate></entry>
<entry><pubDate>dim., 14 juin 2020 18:31:05 +0200</pubDate></entry>
<entry><pubDate>mar., 09 juin 2020 11:46:15 +0200</pubDate></entry>
<entry><pubDate>dim., 07 juin 2020 20:46:01 +0200</pubDate></entry>
<entry><pubDate>lun., 01 juin 2020 10:24:02 +0200</pubDate></entry>
<entry><pubDate>dim., 24 mai 2020 15:41:37 +0200</pubDate></entry>
<entry><pubDate>mar., 19 mai 2020 11:53:34 +0200</pubDate></entry>
<entry><pubDate>lun., 11 mai 2020 11:58:10 +0200</pubDate></entry>
<entry><pubDate>lun., 11 mai 2020 11:58:06 +0200</pubDate></entry>
<entry><pubDate>lun., 04 mai 2020 19:38:33 +0200</pubDate></entry>
<entry><pubDate>mer., 29 avr. 2020 16:02:06 +0200</pubDate></entry>
</test>
EOT
for ($doc->findnodes("//entry")) {
  ok(updated($_), $_->textContent);
}
