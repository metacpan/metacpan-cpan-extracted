#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Send a block of data from one process to another on the local machine
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc, 2016-2017
#-------------------------------------------------------------------------------

package Data::Send::Local;
our $VERSION = 20180405;
use v5.8.0;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use Socket;

#1 Send and receive

sub sendLocal($$;$)                                                             #S Send a block of data locally. Returns B<undef> on success otherwise an error message
 {my ($socketName, $data, $timeOut) = @_;                                       # Socket name (a socket file name that already exists), data, optional timeout for socket to be created - defaults to 10 seconds

  if (!-S $socketName)                                                          # Wait for a bit if necessary for the socket to be created
   {for(1..($timeOut//10)) {sleep 1; last if -S $socketName}
   }
  -S $socketName or return "No such socket: $socketName";                       # Socket not available

  socket(my $socket, AF_UNIX, SOCK_DGRAM, 0)  or return $!;
  connect($socket, sockaddr_un($socketName))  or return $!;
  send($socket, dump($data), 0)               or return $!;
  close($socket);

  undef                                                                         # Return without errors
 }

sub recvLocal($;$$)                                                             #S Receive a block of data sent locally.  Returns the data received.
 {my ($socketName, $user, $length) = @_;                                        # Socket name (a socket file name that is created), optional username of the owner of the socket, maximum length to receive - defaults to one megabyte.

  unlink $socketName;                                                           # Remove existing socket to avoid 'already in use';
  makePath($socketName);                                                        # Create socket directory
  socket(my $socket, AF_UNIX, SOCK_DGRAM, 0) or confess $!;
  bind($socket, sockaddr_un($socketName))    or confess $!;

  if ($user)                                                                    # Do this to make the socket writable by some one else
   {qx(chown $user:$user $socketName);
   }

  recv($socket, my $read, $length // 1e6, 0);
  close($socket);
  unlink $socketName;                                                           # Remove existing socket to force send to wait while the socket is created

  my $r = eval $read;                                                           # Reconstitute data
  $@ and confess $@;                                                            # Bad data block

  $r                                                                            # Return data
 }

#-------------------------------------------------------------------------------
# Tests
#-------------------------------------------------------------------------------

sub test2()
 {my $socket = 'socket';                                                        # Socket name
  my $data   = 'hello';                                                         # Data
  autoflush STDOUT 1;

  if ($^O !~ m/\AMSWin32\Z/)                                                    # Ignore windows
   {say STDOUT "1..2";
    if (fork())
     {say STDOUT "ok" if Data::Send::Local::recvLocal($socket) eq $data;        # Receive data
     }
    else
     {autoflush STDOUT 1;
      say STDOUT "ok" unless Data::Send::Local::sendLocal($socket, $data);      # Send data without error
     }
   }
 }

test2 unless caller;

# podDocumentation

=pod

=encoding utf-8

=head1 Name

Data::Send::Local - Send and receive a block of data between processes on the
local machine.

=head1 Synopsis

Send B<hello> between two processes running on the same machine over the
socket named B<socket>.

  use Test2::Bundle::More;

  my $socket = 'socket';                                                        # Socket name
  my $data   = 'hello';                                                         # Data

  if (fork())
   {ok Data::Send::Local::recvLocal($socket) eq $data;                          # Receive data
   }
  else
   {ok !Data::Send::Local::sendLocal($socket, $data);                           # Send data without error
   }

  done_testing;

=head1 Description

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Send and receive

=head2 sendLocal($$$)

Send a block of data locally. Returns B<undef> on success otherwise an error message

  1  $socketName  Socket name (a socket file name that already exists)
  2  $data        Data
  3  $timeOut     Optional timeout for socket to be created - defaults to 10 seconds

This is a static method and so should be invoked as:

  Data::Send::Local::sendLocal


=head2 recvLocal($$)

Receive a block of data sent locally.  Returns the data received.

  1  $socketName  Socket name (a socket file name that is created)
  2  $length      Optional maximum length to receive - defaults to one megabyte.

This is a static method and so should be invoked as:

  Data::Send::Local::recvLocal



=head1 Index


1 L<recvLocal|/recvLocal>

2 L<sendLocal|/sendLocal>

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read, use,
modify and install.

Standard L<Module::Build> process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2017 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
 }

test unless caller;

1;
__DATA__
use Test2::Bundle::More;

my $socket = 'socket';                                                          # Socket name
my $data   = 'hello';                                                           # Data

if (fork())
 {ok Data::Send::Local::recvLocal($socket) eq $data;                            # Receive data
 }
else
 {ok !Data::Send::Local::sendLocal($socket, $data);                             # Send data without error
 }

done_testing;
