# local test ldap server

package LDAPTest;
use strict;
use warnings;

use Net::LDAP::Server::Test;
use Net::LDAP::Entry;
use Net::LDAP;

sub server_port {10636}
sub server_host { 'ldap://127.0.0.1:' . server_port() }

sub spawn_server {
    my $server = Net::LDAP::Server::Test->new( server_port(), auto_schema => 1, @_ );

    my $ldap = Net::LDAP->new(server_host()) or die "Can't connect: $@";
    my $msg = $ldap->bind;
    die "Can't bind: " . $msg->error if $msg->is_error;

    for my $user (
        {
            uid         => 'somebody',
            displayName => 'Some Body',
            cn          => [qw(value1 value2)]
        },
        {
            uid         => 'some*',
            displayName => 'Some Star',
            cn          => [qw(value1 value2)]
        },
        {
            uid         => 'sunnO)))',
            displayName => 'Sunn O)))',
            cn          => [qw(value1 value2)]
        }
    ) {
        my $msg = $ldap->add("uid=$user->{uid},ou=foobar", attrs => [
            objectClass => 'person',
            ou => 'foobar',
            %{$user},
        ]);
        die "Can't bind: " . $msg->error if $msg->is_error;
    };
    return bless { server => $server, client => $ldap }, 'ServerWrapper';
}

sub ServerWrapper::stop {
    my ($self) = @_;
    $self->{client}->unbind;
    $self->{server}->stop;
}

1;
