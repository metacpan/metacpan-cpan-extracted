package CDP::host;

use Frontier::Client;

use strict;
use warnings;

our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS, );
require Exporter;      
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT =qw//;

@EXPORT_OK =
qw/
    addAdmin
    addBackupUser
    addFullControlUser
    addHost
    addHostWithDescription
    addLinuxControlPanelHost
    addLinuxHost
    addLinuxHostWithDescription
    addRestoreUser
    addUnknownHost
    addUnknownHostWithDescription
    addUser
    addWindowsHost
    addWindowsHostWithDescription
    deleteHost
    getDescription
    getHost
    getHostAsMap
    getHostByDescription
    getHostByHostname
    getHostIds
    getHostIdsByVolume
    getHostname
    getHostType
    getLastFinishedBackupTaskInfo
    getQuota
    getRemotePort
    getTimeout
    isCdpForMySqlAddonEnabled
    isControlPanelModuleEnabled
    isEnabled
    isHostDiscoveryFinished
    removeUser
    runHostDiscovery
    setDescription
    setEnabled
    setHostname
    setHostType
    setLinuxHostType
    setQuota
    setRemotePort
    setsCdpForMySqlAddonEnabled
    setsControlPanelModuleEnabled
    setTimeout
    setWindowsHostType
/;

%EXPORT_TAGS = (
    'ALL' => \@EXPORT_OK,
    'CONST' => [qw//],
);

Exporter::export_ok_tags(keys %EXPORT_TAGS);


sub addAdmin {
    my $client = shift;
    $client->call('host.addAdmin',@_);
}

sub addBackupUser {
    my $client = shift;
    $client->call('host.addBackupUser',@_);
}

sub addFullControlUser {
    my $client = shift;
    $client->call('host.addFullControlUser',@_);
}

sub addHost {
    my $client = shift;
    $client->call('host.addHost',@_);
}

sub addHostWithDescription {
    my $client = shift;
    $client->call('host.addHostWithDescription',@_);
}

sub addLinuxControlPanelHost {
    my $client = shift;
    $client->call('host.addLinuxControlPanelHost',@_);
}

sub addLinuxHost {
    my $client = shift;
    $client->call('host.addLinuxHost',@_);
}

sub addLinuxHostWithDescription {
    my $client = shift;
    $client->call('host.addLinuxHostWithDescription',@_);
}

sub addRestoreUser {
    my $client = shift;
    $client->call('host.addRestoreUser',@_);
}

sub addUnknownHost {
    my $client = shift;
    $client->call('host.addUnknownHost',@_);
}

sub addUnknownHostWithDescription {
    my $client = shift;
    $client->call('host.addUnknownHostWithDescription',@_);
}

sub addUser {
    my $client = shift;
    $client->call('host.addUser',@_);
}

sub addWindowsHost {
    my $client = shift;
    $client->call('host.addWindowsHost',@_);
}

sub addWindowsHostWithDescription {
    my $client = shift;
    $client->call('host.addWindowsHostWithDescription',@_);
}

sub deleteHost {
    my $client = shift;
    $client->call('host.deleteHost',@_);
}

sub getDescription {
    my $client = shift;
    $client->call('host.getDescription',@_);
}

sub getHost {
    my $client = shift;
    $client->call('host.getHost',@_);
}

sub getHostAsMap {
    my $client = shift;
    $client->call('host.getHostAsMap',@_);
}

sub getHostByDescription {
    my $client = shift;
    $client->call('host.getHostByDescription',@_);
}

sub getHostByHostname {
    my $client = shift;
    $client->call('host.getHostByHostname',@_);
}

sub getHostIds {
    my $client = shift;
    $client->call('host.getHostIds',@_);
}

sub getHostIdsByVolume {
    my $client = shift;
    $client->call('host.getHostIdsByVolume',@_);
}

sub getHostname {
    my $client = shift;
    $client->call('host.getHostname',@_);
}

sub getHostType {
    my $client = shift;
    $client->call('host.getHostType',@_);
}

sub getLastFinishedBackupTaskInfo {
    my $client = shift;
    $client->call('host.getLastFinishedBackupTaskInfo',@_);
}

sub getQuota {
    my $client = shift;
    $client->call('host.getQuota',@_);
}

sub getRemotePort {
    my $client = shift;
    $client->call('host.getRemotePort',@_);
}

sub getTimeout {
    my $client = shift;
    $client->call('host.getTimeout',@_);
}

sub isCdpForMySqlAddonEnabled {
    my $client = shift;
    $client->call('host.isCdpForMySqlAddonEnabled',@_);
}

sub isControlPanelModuleEnabled {
    my $client = shift;
    $client->call('host.isControlPanelModuleEnabled',@_);
}

sub isEnabled {
    my $client = shift;
    $client->call('host.isEnabled',@_);
}

sub isHostDiscoveryFinished {
    my $client = shift;
    $client->call('host.isHostDiscoveryFinished',@_);
}

sub removeUser {
    my $client = shift;
    $client->call('host.removeUser',@_);
}

sub runHostDiscovery {
    my $client = shift;
    $client->call('host.runHostDiscovery',@_);
}

sub setDescription {
    my $client = shift;
    $client->call('host.setDescription',@_);
}

sub setEnabled {
    my $client = shift;
    $client->call('host.setEnabled',@_);
}

sub setHostname {
    my $client = shift;
    $client->call('host.setHostname',@_);
}

sub setHostType {
    my $client = shift;
    $client->call('host.setHostType',@_);
}

sub setLinuxHostType {
    my $client = shift;
    $client->call('host.setLinuxHostType',@_);
}

sub setQuota {
    my $client = shift;
    $client->call('host.setQuota',@_);
}

sub setRemotePort {
    my $client = shift;
    $client->call('host.setRemotePort',@_);
}

sub setsCdpForMySqlAddonEnabled {
    my $client = shift;
    $client->call('host.setsCdpForMySqlAddonEnabled',@_);
}

sub setsControlPanelModuleEnabled {
    my $client = shift;
    $client->call('host.setsControlPanelModuleEnabled',@_);
}

sub setTimeout {
    my $client = shift;
    $client->call('host.setTimeout',@_);
}

sub setWindowsHostType {
    my $client = shift;
    $client->call('host.setWindowsHostType',@_);
}


1;
__END__
