# -*- mode: perl -*-
# Copyright (C) 2017–2020  Alex Schroeder <alex@gnu.org>

# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <https://www.gnu.org/licenses/>.

package App::Phoebe;
use Modern::Perl;

our (@extensions);

# block fediverse

push(@extensions, \&block_fediverse);

sub block_fediverse {
  my ($stream, $url, $headers) = @_;
  # quit as quickly as possible: return 1 means the request has been handled
  return 1 if $headers and $headers->{"user-agent"} =~ m!Mastodon|Friendica|Pleroma!i;
  return 0;
}
