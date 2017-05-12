package CDP::user;

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
/;

%EXPORT_TAGS = (
    'ALL' => \@EXPORT_OK,
    'CONST' => [qw//],
);

Exporter::export_ok_tags(keys %EXPORT_TAGS);


sub addAdmin {
    my $client = shift;
    $client->call('user.addAdmin',@_);
}

sub addBasicUser {
    my $client = shift;
    $client->call('user.addBasicUser',@_);
}

sub addSuperUser {
    my $client = shift;
    $client->call('user.addSuperUser',@_);
}

sub addUser {
    my $client = shift;
    $client->call('user.addUser',@_);
}

sub deleteUser {
    my $client = shift;
    $client->call('user.deleteUser',@_);
}

sub getMe {
    my $client = shift;
    $client->call('user.getMe',@_);
}

sub getMyId {
    my $client = shift;
    $client->call('user.getMyId',@_);
}

sub getUser {
    my $client = shift;
    $client->call('user.getUser',@_);
}

sub getUserByUsername {
    my $client = shift;
    $client->call('user.getUserByUsername',@_);
}

sub getUserIds {
    my $client = shift;
    $client->call('user.getUserIds',@_);
}

sub removeAdmin {
    my $client = shift;
    $client->call('user.removeAdmin',@_);
}

sub removeAllUserAdminPrivileges {
    my $client = shift;
    $client->call('user.removeAllUserAdminPrivileges',@_);
}

sub setCanAddHost {
    my $client = shift;
    $client->call('user.setCanAddHost',@_);
}

sub setCanAddUser {
    my $client = shift;
    $client->call('user.setCanAddUser',@_);
}

sub setCanChangePassword {
    my $client = shift;
    $client->call('user.setCanChangePassword',@_);
}

sub setEmailAddress {
    my $client = shift;
    $client->call('user.setEmailAddress',@_);
}

sub setEnabled {
    my $client = shift;
    $client->call('user.setEnabled',@_);
}

sub setIsSuperUser {
    my $client = shift;
    $client->call('user.setIsSuperUser',@_);
}

sub setMustChangePassword {
    my $client = shift;
    $client->call('user.setMustChangePassword',@_);
}

sub setPassword {
    my $client = shift;
    $client->call('user.setPassword',@_);
}

sub setUsername {
    my $client = shift;
    $client->call('user.setUsername',@_);
}


1;
__END__
