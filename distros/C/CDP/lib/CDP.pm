package CDP;
our $VERSION = '0.032';

use 5.008006;
use strict;
use warnings;

use CDP::backupTask		qw /:ALL/;
use CDP::diskSafe		qw /:ALL/;
use CDP::mySQL			qw /:ALL/;
use CDP::taskRun 		qw /:ALL/;
use CDP::volume			qw /:ALL/;
use CDP::Connect		qw /:ALL/;
use CDP::host 			qw /:ALL/;
use CDP::storagepool	qw /:ALL/;
use CDP::user 			qw /:ALL/;
use CDP::Dump 			qw /:ALL/;

our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS, );

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use CDP ':ALL';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
@EXPORT = qw/

/;

@EXPORT_OK = qw/
	OpenCDP
	dumpARef
    dumpHRef

    editBackupTask
    getScheduledTaskIdsByHost
    runNow
    scheduleBackupTask
    scheduleMinutelyBackupTask

    addDiskSafe
    addDiskSafeWithEncryption
    deleteDiskSafe
    getActiveDiskSafe
    getActiveDiskSafeAsMap
    getActiveDiskSafeID
    getCompressionLevel
    getDiskSafe
    getDiskSafeAsMap
    getDiskSafeIDs
    getMaxFreeSpace
    getStorageDiskID
    getTimeCreated
    isEncryptionInitDone
    runEncryptionSetup
    setCompressionLevel
    setPassphrase

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

    addLocalMySQLInstance
    addRemoteMySQLInstance
    deleteMySQLInstance
    getMySQLInstance
    getMySQLInstanceIds
    setCustomInnoDBDataDirectory
    setCustomInnoDBLogDirectory
    setCustomMySQLDataDirectory
    setDescription
    setMySQLHost
    setMySQLPass
    setMySQLPort
    setMySQLSocketPath
    setMySQLUser

    getStoragePool
    getStoragePoolByName
    getStoragePoolIDByName
    getStoragePoolIDs

    getTaskLogs
    getTaskRun

    addAdmin
    addBasicUser
    addSuperUser
    addUser
    deleteUser
    getMe
    getMyId
    getUser
    getUserByUsername
    getUserIds
    removeAdmin
    removeAllUserAdminPrivileges
    setCanAddHost
    setCanAddUser
    setCanChangePassword
    setEmailAddress
    setEnabled
    setIsSuperUser
    setMustChangePassword
    setPassword
    setUsername

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
	'ALL' 	=> \@EXPORT_OK,
	'CONST'	=> [qw//],
);


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
#BEGIN Documentation

=head1 NAME

CDP - Perl wrapper R1Soft CDP (Constant Data Protection) API.

=head1 SYNOPSIS

This module is designed to provide a cleaner procedurally driven 
interface to the 

You may import all methods:
  use CDP qw/:ALL/;

Or You may impliment each module independently.

  use CDP::backupTask     qw /:ALL/;
  use CDP::diskSafe       qw /:ALL/;
  use CDP::mySQL          qw /:ALL/;
  use CDP::taskRun        qw /:ALL/;
  use CDP::volume         qw /:ALL/;
  use CDP::Connect        qw /:ALL/;
  use CDP::host           qw /:ALL/;
  use CDP::storagepool    qw /:ALL/;
  use CDP::user           qw /:ALL/;
  use CDP::Dump           qw /:ALL/;

=head1 DESCRIPTION

This is a wrapper module for the R1Soft CDP v2.0 API.

The goal behind this project was to make a cleaner interface between
the R1Soft API and Perl programs.

By default this module does not autoload any methods and allows you to 
import the specific methods you require.  However, I did write CDP.pm as
a parent module to allow a quick and easy way to import everything.

This module implements Frontier Client to make XML/Java Script calls to the CDP Server.

=head2 EXPORT

None by default.

=head1 Dependencies

  Frontier::Client

=head1 Comparison

Using Frontier::Client
  use Frontier::Client;

  # To connect:
  my $u_name  = 'test';
  my $pw      = 'password';
  my $cdp_url = 'cdp.example.com';
  
  my $control_server_url = "http://$u_name:$pw\@$cdp_url:8084/xmlrpc";
  my $debug = 0;
  my $encoding = 'ISO-8859-1';

  my $client = Frontier::Client->new(
                'url' => $control_server_url,
                'debug' => $debug,
                'encoding' => $encoding,
  );
    
  # Some example procedure calls:
  my $host_id_aref        = $client->call('host.getHostByHostname', $name);
  my $host_name           = $client->call('host.getHostname', $host_id);
  my $host_map            = $client->call('host.getHostAsMap', $host_id);
  my $host_disk_safe_aref = $client->call('diskSafe.getDiskSfaeIDs' $host_id);

Using CDP:
  use CDP qw/:ALL/;
  
  # To Connect
  my $u_name  = 'test';
  my $pw      = 'password';
  my $cdp_url = 'cdp.example.com';
  
  my $client = OpenCDP $cdp_url, $u_name, $pw;
  
  # Some example procedure calls
  my $host_id_aref         = getHostByHostname $client, $name;
  my $host_name            = getHostname $client, $host_id;  
  my $host_map             = getHostAsMap $client, $host_id;
  my $host_disk_safe_aref  = getDiskSfaeIDs $client, $host_id;

=head1 SEE ALSO

R1Soft API Documentation:
  http://wiki.r1soft.com/display/pdf/CDP+Server+API+Guide

=head1 AUTHOR

Please Feel Free to contact me with any questions, comments, or suggestions.

Jon A, E<lt>jon[replacewithat]cyberspacelogistics[replacewithdot]comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by jon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
