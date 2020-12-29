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

our (@extensions, $log);

=head1 Speed Bump

We want to block crawlers that are too fast or that don't follow the
instructions in robots.txt. We do this by keeping a list of recent visitors: for
every IP number, we remember the timestamps of their last visits. If they make
more than 20 requests in 20s, we block them for an ever increasing amount of
seconds, starting with 60s and doubling every time this happens.

The exact number of requests and the length of this time window (in seconds) can
be changed in the config file.

    our $speed_bump_requests = 20;
    our $speed_bump_window = 20;

=cut

our $speed_bump_requests = 20;
our $speed_bump_window = 20;

# $speed_data->{visitors}->{$ip} = [$last, ... , $oldest]
# $speed_data->{blocks}->{$ip}->{seconds} = $sec
# $speed_data->{blocks}->{$ip}->{until} = $ts
# $speed_data->{blocks}->{$ip}->{probation} = $ts + $sec
my $speed_data;

push(@extensions, \&speed_bump, \&speed_bump_admin);

sub speed_bump {
  my ($stream, $url) = @_;
  my $now = time;
  # go through all the blocks we kept and delete the old data
  for my $ip (keys %{$speed_data->{blocks}}) {
    # delete the time limits if they are in the past
    delete($speed_data->{blocks}->{$ip}->{until})
	if $speed_data->{blocks}->{$ip}->{until} and $speed_data->{blocks}->{$ip}->{until} < $now;
    delete($speed_data->{blocks}->{$ip}->{probation})
	if $speed_data->{blocks}->{$ip}->{probation} and $speed_data->{blocks}->{$ip}->{probation} < $now;
    # if the probation period elapsed, delete the current block length
    delete($speed_data->{blocks}->{$ip}->{seconds})
	if not $speed_data->{blocks}->{$ip}->{probation};
  }
  # go through all the request time stamps and delete data outside the time window
  for my $ip (keys %{$speed_data->{visitors}}) {
    # if the latest visit was longer ago than the time window, forget it
    delete($speed_data->{visitors}->{$ip})
	if $speed_data->{visitors}->{$ip}->[0] + $speed_bump_window < $now;
  }
  # check if we are currently blocked now that the maintenance is done
  my $ip = $stream->handle->peerhost;
  my $until = $speed_data->{blocks}->{$ip}->{until};
  if ($until and $until > $now) {
    $log->debug("Blocking a peer");
    my $delta = $until - $now;
    $stream->write("44 $delta\r\n");
    # no more processing
    return 1;
  }
  # add a timestamp to the front for the current $ip
  unshift(@{$speed_data->{visitors}->{$ip}}, $now);
  # if there are enough timestamps, pop the last one and see if it falls within
  # the time window
  if (@{$speed_data->{visitors}->{$ip}} > $speed_bump_requests
      and $now + $speed_bump_window > pop(@{$speed_data->{visitors}->{$ip}})) {
    $log->debug("Adding peer block");
    # if so, we're going to block you, and if you're a repeating offender, we're
    # going to double the block
    my $probation = $speed_data->{blocks}->{$ip}->{probation};
    my $seconds = $speed_data->{blocks}->{$ip}->{seconds};
    $seconds *= 2 if $seconds and $probation and $probation > $now;
    $seconds ||= 60; # the default for first time offenders
    $speed_data->{blocks}->{$ip}->{seconds} = $seconds;
    $speed_data->{blocks}->{$ip}->{until} = $now + $seconds;
    $speed_data->{blocks}->{$ip}->{probation} = $now + 2 * $seconds;
    $stream->write("44 $seconds\r\n");
    # no more processing
    return 1;
  }
  # maintenance is done and no block was required, carry on
  return 0;
}

sub speed_bump_admin {
  my $stream = shift;
  my $url = shift;
  my $port = port($stream);
  if ($url =~ m!^gemini://127.0.0.1(?::$port)?/do/speed-bump/reset$!) {
    $speed_data = undef;
    $stream->write("20 text/plain\r\n");
    $stream->write("Data reset\n");
    return 1;
  }
  return;
}
