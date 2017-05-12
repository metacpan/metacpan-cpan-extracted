#!/usr/bin/perl
use strict;

use v5.10;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use File::Tail; # libfile-tail-perl
use HTTP::Tiny; # libhttp-tiny-perl
use JSON; # libjson-perl

# PODNAME: station-devmon

# ABSTRACT: station-devmon - Monitor Syslog for device events

our $VERSION = '0.5'; # VERSION


# Eventstreamr libs
use App::EventStreamr::Devices;
our $devices = App::EventStreamr::Devices->new();

my $log = File::Tail->new(name => "/var/log/syslog", maxinterval=>1, );

while(defined(my $line=$log->read)) {
  # Perform action on device created logs
  if ($line =~ m/firewire_core.+: created device/i) {
    # Extract the GUID
    $line =~ /.+].firewire_core.+:.created.device.fw\d+:.GUID.(?<guid>.+),.*/ix;
    my $guid = $+{guid};

    # Load DV devices
    my $dv = $devices->dv();
    
    # Avoid trying to restart the fw card as a dv device
    if (defined $dv->{"0x$guid"}) {
      # Trigger restart
      my $device->{id} = "0x$guid";
      my $json = to_json($device);
      my %post_data = (
            content => $json,
            'content-type' => 'application/json',
            'content-length' => length($json),
      );

      my $http = HTTP::Tiny->new(timeout => 15);
      my $post = $http->post("http://localhost:3000/command/restart", \%post_data);
    }
  } elsif ($line =~ m/new full-speed USB device/i) {
    my $http = HTTP::Tiny->new(timeout => 15);
    my $post = $http->post("http://localhost:3000/manager/refresh");
  }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

station-devmon - station-devmon - Monitor Syslog for device events

=head1 VERSION

version 0.5

=head1 SYNOPSIS

Usage:

    station-devmon.pl

=head1 AUTHOR

Leon Wright < techman@cpan.org >

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Leon Wright.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut
