package CDP::taskRun;

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
    getTaskLogs
    getTaskRun
/;

%EXPORT_TAGS = (
    'ALL' => \@EXPORT_OK,
    'CONST' => [qw//],
);

Exporter::export_ok_tags(keys %EXPORT_TAGS);


sub getTaskLogs {
    my $client = shift;
    $client->call('taskRun.getTaskLogs',@_);
}

sub getTaskRun {
    my $client = shift;
    $client->call('taskRun.getTaskRun',@_);
}


1;
__END__
