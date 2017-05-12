package CDP::volume;

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
    addUser
    addVolume
    deleteVolume
    getAllowedScheduleFrequencies
    getVolume
    getVolumeByName
    getVolumeIds
    removeUser
    setAllowedScheduleFrequencies
    setControlPanelModuleEnabled
    setMaxCdpForMySqlAddons
    setMaxLinuxHosts
    setMaxWindowsHosts
    setQuota
    setStoragePool
    setVolumeName
/;

%EXPORT_TAGS = (
    'ALL' => \@EXPORT_OK,
    'CONST' => [qw//],
);

Exporter::export_ok_tags(keys %EXPORT_TAGS);


sub addUser {
    my $client = shift;
    $client->call('volume.addUser',@_);
}

sub addVolume {
    my $client = shift;
    $client->call('volume.addVolume',@_);
}

sub deleteVolume {
    my $client = shift;
    $client->call('volume.deleteVolume',@_);
}

sub getAllowedScheduleFrequencies {
    my $client = shift;
    $client->call('volume.getAllowedScheduleFrequencies',@_);
}

sub getVolume {
    my $client = shift;
    $client->call('volume.getVolume',@_);
}

sub getVolumeByName {
    my $client = shift;
    $client->call('volume.getVolumeByName',@_);
}

sub getVolumeIds {
    my $client = shift;
    $client->call('volume.getVolumeIds',@_);
}

sub removeUser {
    my $client = shift;
    $client->call('volume.removeUser',@_);
}

sub setAllowedScheduleFrequencies {
    my $client = shift;
    $client->call('volume.setAllowedScheduleFrequencies',@_);
}

sub setControlPanelModuleEnabled {
    my $client = shift;
    $client->call('volume.setControlPanelModuleEnabled',@_);
}

sub setMaxCdpForMySqlAddons {
    my $client = shift;
    $client->call('volume.setMaxCdpForMySqlAddons',@_);
}

sub setMaxLinuxHosts {
    my $client = shift;
    $client->call('volume.setMaxLinuxHosts',@_);
}

sub setMaxWindowsHosts {
    my $client = shift;
    $client->call('volume.setMaxWindowsHosts',@_);
}

sub setQuota {
    my $client = shift;
    $client->call('volume.setQuota',@_);
}

sub setStoragePool {
    my $client = shift;
    $client->call('volume.setStoragePool',@_);
}

sub setVolumeName {
    my $client = shift;
    $client->call('volume.setVolumeName',@_);
}


1;
__END__
