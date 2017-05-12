package CDP::storagepool;

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
    getStoragePool
    getStoragePoolByName
    getStoragePoolIDByName
    getStoragePoolIDs
/;

%EXPORT_TAGS = (
    'ALL' => \@EXPORT_OK,
    'CONST' => [qw//],
);

Exporter::export_ok_tags(keys %EXPORT_TAGS);


sub getStoragePool {
    my $client = shift;
    $client->call('storagepool.getStoragePool',@_);
}

sub getStoragePoolByName {
    my $client = shift;
    $client->call('storagepool.getStoragePoolByName',@_);
}

sub getStoragePoolIDByName {
    my $client = shift;
    $client->call('storagepool.getStoragePoolIDByName',@_);
}

sub getStoragePoolIDs {
    my $client = shift;
    $client->call('storagepool.getStoragePoolIDs',@_);
}


1;
__END__
