package CDP::mySQL;

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
/;

%EXPORT_TAGS = (
    'ALL' => \@EXPORT_OK,
    'CONST' => [qw//],
);

Exporter::export_ok_tags(keys %EXPORT_TAGS);


sub addLocalMySQLInstance {
    my $client = shift;
    $client->call('mySQL.addLocalMySQLInstance',@_);
}

sub addRemoteMySQLInstance {
    my $client = shift;
    $client->call('mySQL.addRemoteMySQLInstance',@_);
}

sub deleteMySQLInstance {
    my $client = shift;
    $client->call('mySQL.deleteMySQLInstance',@_);
}

sub getMySQLInstance {
    my $client = shift;
    $client->call('mySQL.getMySQLInstance',@_);
}

sub getMySQLInstanceIds {
    my $client = shift;
    $client->call('mySQL.getMySQLInstanceIds',@_);
}

sub setCustomInnoDBDataDirectory {
    my $client = shift;
    $client->call('mySQL.setCustomInnoDBDataDirectory',@_);
}

sub setCustomInnoDBLogDirectory {
    my $client = shift;
    $client->call('mySQL.setCustomInnoDBLogDirectory',@_);
}

sub setCustomMySQLDataDirectory {
    my $client = shift;
    $client->call('mySQL.setCustomMySQLDataDirectory',@_);
}

sub setDescription {
    my $client = shift;
    $client->call('mySQL.setDescription',@_);
}

sub setMySQLHost {
    my $client = shift;
    $client->call('mySQL.setMySQLHost',@_);
}

sub setMySQLPass {
    my $client = shift;
    $client->call('mySQL.setMySQLPass',@_);
}

sub setMySQLPort {
    my $client = shift;
    $client->call('mySQL.setMySQLPort',@_);
}

sub setMySQLSocketPath {
    my $client = shift;
    $client->call('mySQL.setMySQLSocketPath',@_);
}

sub setMySQLUser {
    my $client = shift;
    $client->call('mySQL.setMySQLUser',@_);
}


1;
__END__
