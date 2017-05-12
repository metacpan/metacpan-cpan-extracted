#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

# 0-desktop-file-validate.t is shared by several distributions.
#
# 0-desktop-file-validate.t is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# 0-desktop-file-validate.t is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

BEGIN { require 5 }
use strict;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
# use Smart::Comments;

{
  package Test::DesktopFile::Validate;
  use strict;
  use Carp;
  use IPC::Cmd;
  use Test::More;
  use ExtUtils::Manifest;

  sub skip_reason {
    eval { require IPC::Cmd; 1 }
      or return 'IPC::Cmd not available';
    my ($success, $error_message, $buffer)
      = IPC::Cmd::run (command => ['desktop-file-validate','--help'],
                       verbose => 0);
    ### $buffer
    if ($success) {
      return undef;
    }
    my $skip = "desktop-file-validate program not available: $error_message";
    if (defined $buffer) {
      $skip .= join('',$buffer);
    }
    return $skip;
  }

  sub desktop_file_validate {
    my ($filename) = @_;
    require IPC::Cmd;
    my ($success, $error_message, $buffer)
      = IPC::Cmd::run(command => ['desktop-file-validate',
                                  '--no-warn-deprecated',
                                  $filename],
                      verbose => 0);
    if ($success) {
      return undef;
    } else {
      return "$error_message\n$buffer";
    }
  }

  sub check_all_desktop_files {
    ### check_all_desktop_files() ...

  SKIP: {
      my $skip = skip_reason();
      if (defined $skip) {
        skip $skip, 1;
      }

      my $manifest = ExtUtils::Manifest::maniread();
      my @filenames = grep /\.desktop$/, keys %$manifest;
      ### @filenames
      my $bad = 0;
      foreach my $filename (@filenames) {
        my $reason = desktop_file_validate($filename);
        if (defined $reason) {
          diag "$filename: $reason";
          $bad++;
        }
      }
      is ($bad, 0, 'desktop-file-validate failures');
    }
  }
}

use Test::More tests => 1;
Test::DesktopFile::Validate::check_all_desktop_files();
exit 0;

__END__

# my $devnull = File::Spec->devnull;
# my $wait = do {
#   local *STDOUT;
#   local *STDERR;
#   if (! open STDOUT, ">$devnull") {
#     die "Oops, cannot open $devnull: $!";
#   }
#   if (! open STDERR, ">$devnull") {
#     die "Oops, cannot open $devnull: $!";
#   }
#   system 'desktop-file-validate --help';
# };
#
# if ($wait == 0) {
#   return undef;
# }
# return 'desktop-file-validate program not available';
