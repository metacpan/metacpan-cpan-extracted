# -*- mode: perl -*-
# Copyright (C) 2017–2021  Alex Schroeder <alex@gnu.org>

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

=encoding utf8

=head1 NAME

App::Phoebe::BlockFediverse - block Fediverse instances from Phoebe wiki

=head1 DESCRIPTION

This extension blocks the Fediverse user agent from your website (Mastodon,
Friendica, Pleroma). The reason is this: when these sites federate a status
linking to your site, each instance will fetch a preview, so your site will get
hit by hundreds of requests from all over the Internet. Blocking them helps us
weather the storm.

There is no configuration. Simply add it to your F<config> file:

    use App::Phoebe::BlockFediverse;

Sure, we could also think of better caching and all that. I hate the fact that
other developers are forcing us to build “software that scales” – I hate how
they think that I have nothing better to do than think about blocking and
caching. Phoebe is software for the Smolnet, not for people that keep thinking
about scaling.

The solution implemented is this: if the user agent of a HTTP request matches
the regular expression, quit immediatly. The result:

    $ curl --header "User-Agent: Pleroma" https://transjovian.org:1965/
    Blocking Fediverse previews

Yeah, we could respond with a error, but fediverse developers aren’t interested
in a new architecture for this problem. They think the issue has been solved.
See L<#4486|https://github.com/tootsuite/mastodon/issues/4486>, “Mastodon can be
used as a DDOS tool.”

=cut

package App::Phoebe::BlockFediverse;
use App::Phoebe qw(@extensions);
use App::Phoebe::Web qw(http_error);
use Modern::Perl;

push(@extensions, \&block_fediverse);

sub block_fediverse {
  my ($stream, $url, $headers) = @_;
  # quit as quickly as possible: return 1 means the request has been handled
  return 0 unless $headers and $headers->{"user-agent"} and $headers->{"user-agent"} =~ m!Mastodon|Friendica|Pleroma!i;
  http_error($stream, "Blocking Fediverse previews");
  return 1;
}

1;
