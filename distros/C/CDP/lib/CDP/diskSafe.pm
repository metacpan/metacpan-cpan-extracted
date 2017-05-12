package CDP::diskSafe;

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
/;

%EXPORT_TAGS = (
    'ALL' => \@EXPORT_OK,
    'CONST' => [qw//],
);

Exporter::export_ok_tags(keys %EXPORT_TAGS);


sub addDiskSafe {
    my $client = shift;
    $client->call('diskSafe.addDiskSafe',@_);
}

sub addDiskSafeWithEncryption {
    my $client = shift;
    $client->call('diskSafe.addDiskSafeWithEncryption',@_);
}

sub deleteDiskSafe {
    my $client = shift;
    $client->call('diskSafe.deleteDiskSafe',@_);
}

sub getActiveDiskSafe {
    my $client = shift;
    $client->call('diskSafe.getActiveDiskSafe',@_);
}

sub getActiveDiskSafeAsMap {
    my $client = shift;
    $client->call('diskSafe.getActiveDiskSafeAsMap',@_);
}

sub getActiveDiskSafeID {
    my $client = shift;
    $client->call('diskSafe.getActiveDiskSafeID',@_);
}

sub getCompressionLevel {
    my $client = shift;
    $client->call('diskSafe.getCompressionLevel',@_);
}

sub getDiskSafe {
    my $client = shift;
    $client->call('diskSafe.getDiskSafe',@_);
}

sub getDiskSafeAsMap {
    my $client = shift;
    $client->call('diskSafe.getDiskSafeAsMap',@_);
}

sub getDiskSafeIDs {
    my $client = shift;
    $client->call('diskSafe.getDiskSafeIDs',@_);
}

sub getMaxFreeSpace {
    my $client = shift;
    $client->call('diskSafe.getMaxFreeSpace',@_);
}

sub getStorageDiskID {
    my $client = shift;
    $client->call('diskSafe.getStorageDiskID',@_);
}

sub getTimeCreated {
    my $client = shift;
    $client->call('diskSafe.getTimeCreated',@_);
}

sub isEncryptionInitDone {
    my $client = shift;
    $client->call('diskSafe.isEncryptionInitDone',@_);
}

sub runEncryptionSetup {
    my $client = shift;
    $client->call('diskSafe.runEncryptionSetup',@_);
}

sub setCompressionLevel {
    my $client = shift;
    $client->call('diskSafe.setCompressionLevel',@_);
}

sub setPassphrase {
    my $client = shift;
    $client->call('diskSafe.setPassphrase',@_);
}


1;
__END__
