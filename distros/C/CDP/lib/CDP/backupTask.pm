package CDP::backupTask;

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
    editBackupTask
    getScheduledTaskIdsByHost
    runNow
    scheduleBackupTask
    scheduleMinutelyBackupTask
/;

%EXPORT_TAGS = (
    'ALL' => \@EXPORT_OK,
    'CONST' => [qw//],
);

Exporter::export_ok_tags(keys %EXPORT_TAGS);


sub editBackupTask {
    my $client = shift;
    $client->call('backupTask.editBackupTask',@_);
}

sub getScheduledTaskIdsByHost {
    my $client = shift;
    $client->call('backupTask.getScheduledTaskIdsByHost',@_);
}

sub runNow {
    my $client = shift;
    $client->call('backupTask.runNow',@_);
}

sub scheduleBackupTask {
    my $client = shift;
    $client->call('backupTask.scheduleBackupTask',@_);
}

sub scheduleMinutelyBackupTask {
    my $client = shift;
    $client->call('backupTask.scheduleMinutelyBackupTask',@_);
}


1;
__END__
