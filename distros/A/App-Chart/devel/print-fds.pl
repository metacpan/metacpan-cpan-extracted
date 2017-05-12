#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use POSIX ();
use IO::Handle;

# return the F_GETFD flags from a file descriptor
sub fd_getfd {
  my ($fd) = @_;

  # don't let new_from_fd() turn on FD_CLOEXEC
  local $^F = 999_999_999;

  my $fh = IO::Handle->new_from_fd ($fd, 'r');
  return fcntl ($fh, POSIX::F_GETFD(), 0);
}

foreach my $fd (0 .. 100) {
  my @a = POSIX::fstat ($fd)
    or next;

  my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
      $atime,$mtime,$ctime,$blksize,$blocks) = @a;

  my $flags = fd_getfd ($fd);
  if (defined $flags) {
    $flags += 0;
  } else {
    $flags = "$!";
  }

  print "$fd  $dev,$ino  GETFD=$flags\n";
}
exit 0;
