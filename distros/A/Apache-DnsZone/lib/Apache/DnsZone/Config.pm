package Apache::DnsZone::Config;

# $Id: Config.pm,v 1.12 2001/06/03 11:10:23 thomas Exp $

use strict;
use vars qw($VERSION);
use Apache ();
use Apache::DnsZone;

($VERSION) = qq$Revision: 1.12 $ =~ /([\d\.]+)/;

sub new {
    my $class = shift;
    my $r = shift;
    my %cfg = ();
    $cfg{DnsZoneLangDir} = $r->dir_config('DnsZoneLangDir') || '/usr/local/modperl/dnszone';
    $cfg{DnsZoneDebugLevel} = $r->dir_config('DnsZoneDebugLevel');
    $cfg{DnsZoneDBsrc} = $r->dir_config('DnsZoneDBsrc');
    $cfg{DnsZoneDBuser} = $r->dir_config('DnsZoneDBuser');
    $cfg{DnsZoneDBpass} = $r->dir_config('DnsZoneDBpass');
    $cfg{DnsZoneTemplateDir} = $r->dir_config('DnsZoneTemplateDir') || '/usr/local/modperl/dnszone/template';
    $cfg{DnsZoneLoginLang} = $r->dir_config('DnsZoneLoginLang') || 'en';
    $cfg{DnsZoneLogoutHandler} = $r->dir_config('DnsZoneLogoutHandler') || '/logout';
    $cfg{DnsZoneTableEvenColor} = $r->dir_config('DnsZoneTableEvenColor') || '#EDECF5';
    $cfg{DnsZoneTableOddColor} = $r->dir_config('DnsZoneTableOddColor') || '#DAD9E9';

    my $cfg = \%cfg;
    $Apache::DnsZone::DebugLevel = $cfg->{DnsZoneDebugLevel};
    return bless { cfg => $cfg }, $class;
}

1;
