#line 1
package Net::Ping::External;

# Author:   Colin McMillen (colinm AT cpan.org)
# See also the CREDITS section in the POD below.
#
# Copyright (c) 2001-2003 Colin McMillen.  All rights reserved.  This
# program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.
# Copyright (c) 2006-2008 Alexandr Ciornii

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $DEBUG);
use Carp;
use Socket qw(inet_ntoa);
require Exporter;

$VERSION = "0.13";
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(ping);

sub ping {
  # Set up defaults & override defaults with parameters sent.
  my %args = (count => 1, size => 56, @_);

  # "host" and "hostname" are synonyms.
  $args{host} = $args{hostname} if defined $args{hostname};

  # If we have an "ip" argument, convert it to a hostname and use that.
  $args{host} = inet_ntoa($args{ip}) if defined $args{ip};

  # croak() if no hostname was provided.
  croak("You must provide a hostname") unless defined $args{host};
  $args{timeout} = 5 unless defined $args{timeout} && $args{timeout} > 0;

  my %dispatch = 
    (linux    => \&_ping_linux,
     mswin32  => \&_ping_win32,
     cygwin   => \&_ping_cygwin,
     solaris  => \&_ping_solaris,
     bsdos    => \&_ping_bsdos,
     beos     => \&_ping_beos,
     hpux     => \&_ping_hpux,
     dec_osf  => \&_ping_dec_osf,
     bsd      => \&_ping_bsd,
     darwin   => \&_ping_darwin,
     openbsd  => \&_ping_unix,
     freebsd  => \&_ping_freebsd,
     next     => \&_ping_next,
     unicosmk => \&_ping_unicosmk,
     netbsd   => \&_ping_netbsd,
     irix     => \&_ping_unix,
     aix      => \&_ping_aix,
    );

  my $subref = $dispatch{lc $^O};

  croak("External ping not supported on your system") unless $subref;

  return $subref->(%args);
}

# Win32 is the only system so far for which we actually need to parse the
# results of the system ping command.
sub _ping_win32 {
  my %args = @_;
  $args{timeout} *= 1000;    # Win32 ping timeout is specified in milliseconds
  #for each ping
  my $command = "ping -l $args{size} -n $args{count} -w $args{timeout} $args{host}";
  print "$command\n" if $DEBUG;
  my $result = `$command`;
  return 1 if $result =~ /time.*ms/;
  return 1 if $result =~ /TTL/;
  return 1 if $result =~ /is alive/; # ppt (from CPAN) ping
#  return 1 if $result !~ /\(100%/; # 100% packages lost
  return 0;
}

# Mac OS X 10.2 ping does not handle -w timeout now does it return a
# status code if it fails to ping (unless it cannot resolve the domain 
# name)
# Thanks to Peter N. Lewis for this one.
sub _ping_darwin {
   my %args = @_;
   my $command = "ping -s $args{size} -c $args{count} $args{host}";
   my $devnull = "/dev/null";
   $command .= " 2>$devnull";
   print "$command\n" if $DEBUG;
   my $result = `$command`;
   return 1 if $result =~ /(\d+) packets received/ && $1 > 0;
   return 0;
}

# Generic subroutine to handle pinging using the system() function. Generally,
# UNIX-like systems return 0 on a successful ping and something else on
# failure. If the return value of running $command is equal to the value
# specified as $success, the ping succeeds. Otherwise, it fails.
sub _ping_system {
  my ($command,   # The ping command to run
      $success,   # What value the system ping command returns on success
     ) = @_;
  my $devnull = "/dev/null";
  $command .= " 1>$devnull 2>$devnull";
  print "#$command\n" if $DEBUG;
  my $exit_status = system($command) >> 8;
  return 1 if $exit_status == $success;
  return 0;
}

# Below are all the systems on which _ping_system() has been tested
# and found OK.

# Assumed OK for DEC OSF
sub _ping_dec_osf {
  my %args = @_;
  my $command = "ping -c $args{count} -s $args{size} -q -u $args{host}";
  return _ping_system($command, 0);
}

# Assumed OK for unicosmk
sub _ping_unicosmk {
  my %args = @_;
  my $command = "ping -s $args{size} -c $args{count} $args{host}";
  return _ping_system($command, 0);
}

# NeXTStep 3.3/sparc
sub _ping_next {
  my %args = @_;
  my $command = "ping $args{host} $args{size} $args{count}";
  return _ping_system($command, 0);
}

# Assumed OK for HP-UX.
sub _ping_hpux {
  my %args = @_;
  my $command = "ping $args{host} $args{size} $args{count}";
  return _ping_system($command, 0);
}

# Assumed OK for BSD/OS 4.
sub _ping_bsdos {
  my %args = @_;
  my $command = "ping -c $args{count} -s $args{size} $args{host}";
  return _ping_system($command, 0);
}

# Assumed OK for BeOS.
sub _ping_beos {
  my %args = @_;
  my $command = "ping -c $args{count} -s $args{size} $args{host}";
  return _ping_system($command, 0);
}

# Assumed OK for AIX
sub _ping_aix {
  my %args = @_;
  my $command = "ping -c $args{count} -s $args{size} -q $args{host}";
  return _ping_system($command, 0);
}

# OpenBSD 2.7 OK, IRIX 6.5 OK
# Assumed OK for NetBSD & FreeBSD, but needs testing
sub _ping_unix {
  my %args = @_;
  my $command = "ping -s $args{size} -c $args{count} -w $args{timeout} $args{host}";
  return _ping_system($command, 0);
}


sub _locate_ping_netbsd {
  return '/usr/sbin/ping' if (-x '/usr/sbin/ping');
  return 'ping';
}

sub _ping_netbsd {
  my %args = @_;
  my $command = _locate_ping_netbsd()." -s $args{size} -c $args{count} -w $args{timeout} $args{host}";
  return _ping_system($command, 0);
}
#-s size -c count -w timeout 
#http://netbsd.gw.com/cgi-bin/man-cgi?ping++NetBSD-current

# Assumed OK for FreeBSD 3.4
# -s size option supported -- superuser only... fixme
sub _ping_bsd {
  my %args = @_;
  my $command = "ping -c $args{count} -q $args{hostname}";
  return _ping_system($command, 0);
}

# Debian 2.2 OK, RedHat 6.2 OK
# -s size option available to superuser... FIXME?
sub _ping_linux {
  my %args = @_;
  my $command;
#for next version
  if (-e '/etc/redhat-release' || -e '/etc/SuSE-release') {
    $command = "ping -c $args{count} -s $args{size} $args{host}";
  } else {
    $command = "ping -c $args{count} $args{host}";
  }
  return _ping_system($command, 0);
}

# Solaris 2.6, 2.7 OK
sub _ping_solaris {
  my %args = @_;
  my $command = "ping -s $args{host} $args{size} $args{timeout}";
  return _ping_system($command, 0);
}

# FreeBSD. Tested OK for Freebsd 4.3
# -s size option supported -- superuser only... FIXME?
# -w timeout option for BSD replaced by -t
sub _ping_freebsd {
  my %args = @_;
  my $command = "ping -c $args{count} -t $args{timeout} $args{host}";
  return _ping_system($command, 0);
}

#No timeout
#Usage:  ping [-dfqrv] host [packetsize [count [preload]]]
sub _ping_cygwin {
  my %args = @_;
  my $command = "ping $args{host} $args{size} $args{count}";
  return _ping_system($command, 0);
}
#Problem is that we may be running windows ping

1;

__END__

#line 450
