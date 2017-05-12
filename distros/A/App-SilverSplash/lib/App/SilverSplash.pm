package App::SilverSplash;

use strict;
use warnings;

=head1 NAME

App::SilverSplash - A network captive portal for Linux platforms.

=head1 ABSTRACT

See http://groups.google.com/group/silversplash for information.  This
module is currently beta status and being polished.

=head1 DESCRIPTION

Silver Splash is a captive portal for Linux platforms.

Setup is still rough - see the Google Group for discussion of setup.

But there are a few notes being added here.

You will need to add the apache user to /etc/sudoers and give it
permission to run iptables.  Here's the entry I'm using:

 apache  ALL=NOPASSWD:/sbin/iptables

Adding apache to iptables worked quite well, however I also had to
comment out
# Defaults    requiretty

=cut

use constant DEBUG => $ENV{SL_DEBUG} || 0;

our $VERSION = 0.02;

use Data::Dumper qw(Dumper);

use Config::SL       ();
use App::SilverSplash::IPTables (); # ugh
use URI::Escape ();
use DB_File;
use Fcntl qw(O_CREAT);


our ( $Config, $Lease_file, $Auth_url, $Max_rate, %Db,
      $Min_count, $Wan_if, $Lan_if, $Lan_ip, $Wan_mac );

BEGIN {
    $Config     = Config::SL->new;
    $Lease_file = $Config->sl_dhcp_lease_file    || die 'oops';
    $Wan_if     = $Config->sl_wan_if              || die 'oops';
    $Lan_if     = $Config->sl_lan_if              || die 'oops';
    ($Lan_ip)   = `/sbin/ifconfig $Lan_if` =~ m/inet addr:(\S+)/;
    ($Wan_mac)  = `/sbin/ifconfig $Wan_if` =~ m/HWaddr\s(\S+)/;
}

sub tie_db {
    my $class = shift;
    my $fn = $Config->sl_dbfile;
    tie %Db, 'DB_File', $fn, O_CREAT, 0777, $DB_BTREE
        or die "Can't tie $fn: $!";
}


sub lan_ip {
    my $self = shift;
    return $Lan_ip;
}

sub wan_mac {
    my $self = shift;
    return $Wan_mac;
}
  
sub get {
    my ($class, $key) = @_;

    $class->tie_db;
    my $val = $Db{uc($key)};
    untie %Db;
    return $val if $val;
    return;
}

sub set {
    my ($class, $key, $val) = @_;

    $class->tie_db;
    $Db{uc($key)} = $val;
    untie %Db;
    return 1;
}

# returns true if the mac address may pass

sub check_auth {
    my ($class, $mac, $ip) = @_;

    my $chain = $class->not_timed_out($mac, $ip);

    return unless $chain;

    # fixup the firewall rules based on the chain type
    my $fixup = App::SilverSplash::IPTables->fixup_access($mac, $ip, $chain);

    return unless $fixup;

    return $fixup;
}


sub make_post_url {
    my ( $class, $splash_url, $dest_url ) = @_;

    $dest_url = URI::Escape::uri_escape($dest_url);
    my $separator = ($splash_url =~ m/\?/) ? '&' : '?';

    my $location = $splash_url . $separator . "url=$dest_url";

    return $location;
}


sub mac_from_ip {
    my ($class, $ip) = @_;

    my $fh;
    open($fh, '<', $Lease_file) or die "couldn't open lease $Lease_file";
    my $client_mac;
    while (my $line = <$fh>) {

        my ($time, $mac, $hostip, $hostname, $othermac) = split(/\s/, $line);
        if ($ip eq $hostip) {

            $client_mac = $mac;
            last;
        }
    }
    close($fh) or die $!;

    return unless $client_mac;

    warn("$$ found mac $client_mac for ip $ip") if DEBUG;

    return $client_mac;
}


sub ip_from_mac {
    my ($class, $client_mac) = @_;

    my $fh;
    open($fh, '<', $Lease_file) or die "couldn't open lease $Lease_file";
    my $client_ip;
    while (my $line = <$fh>) {

        my ($time, $mac, $hostip, $hostname, $othermac) = split(/\s/, $line);
        if ($client_mac eq $mac) {

            $client_ip = $hostip;
            last;
        }
    }
    close($fh) or die $!;

    return unless $client_ip;

    warn("$$ found ip $client_ip for mac $client_mac") if DEBUG;

    return $client_ip;
}

# returns the auth chain if the user is not timed out

sub not_timed_out {
    my ($class, $mac, $ip) = @_;

    my $exp = $class->get($mac);

    return unless $exp;

    my ($exp_time, $chain) = split(/\|/, $exp);

    return if time() > $exp_time;

    return $chain; # paid, ads
}

=head1 COPYRIGHT AND LICENSE

Copyright 2010 Silver Lining Networks.  All rights reserved.

This program is licensed under the Apache 2.0 software license.

A copy of this license is included in the module distribution.

=cut

1;

