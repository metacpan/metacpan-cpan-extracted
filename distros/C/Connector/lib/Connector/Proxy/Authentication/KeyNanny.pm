# Connector::Proxy::Authentication::Password
#
# Check given authentication passwords against KeyNanny
#
package Connector::Proxy::Authentication::KeyNanny;

use strict;
use warnings;
use English;
use Data::Dumper;
use KeyNanny::Connector;

use Moose;
extends 'Connector::Proxy';

has keynanny => (
    is => 'ro',
    isa => 'KeyNanny::Connector',
    lazy => 1,
    builder => '_init_keynanny',
);

sub _init_keynanny {

    my $self = shift;
    return KeyNanny::Connector->new({
        LOCATION => $self->LOCATION(),
    });
}

sub get {
    my $self = shift;
    my $arg = shift;
    my $params = shift;

    my @path = $self->_build_path_with_prefix( $arg );
    my $user = $path[ (scalar @path) - 1 ];

    my $password = $params->{password};

    if (!$user) {
        $self->log()->error('No username');
        die "no username given";
    }

    if (!$password) {
        $self->log()->error('No password');
        die "no password given";
    }

    if ($user =~ /[^a-zA-Z0-9_\-\.]/) {
        $self->log()->error('Invalid chars in username ('.$user.')');
        return $self->_node_not_exists( $user );
    }

    my $knpath = join("/", @path );
    $self->log()->debug('verify password for ' . $user . ', path ' . $knpath );

    # Keynanny uses the slash as seperator
    my $secret;
    eval {
        $secret = $self->keynanny()->get( $knpath );
    };
    if ($EVAL_ERROR) {
        $self->log()->error('Error talking to keynanny ' . $EVAL_ERROR);
        return $self->_node_not_exists( $user );
    }

    if (!$secret) {
        return $self->_node_not_exists( $user );
    } elsif ($secret eq $password) {
        $self->log()->info('Password accepted for ' . $user);
        return 1;
    } else {
        $self->log()->info('Password mismatch for ' . $user);
        return 0;
    }
}


sub get_meta {
    my $self = shift;

    # If we have no path, we tell the caller that we are a connector
    my @path = $self->_build_path( shift );
    if (scalar @path == 0) {
        return { TYPE  => "connector" };
    }
    return {TYPE  => "scalar" };
}

sub exists {

    my $self = shift;
    my $arg = shift;

    if ((scalar @{$arg}) == 0) {
        return 1;
    }

    my @path = $self->_build_path_with_prefix( $arg );

    my $secret = $self->keynanny()->get( join("/", @path ) );

    if ($secret) {
        return 1;
    } else {
        return 0;
    }

}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head 1 Name

Connector::Proxy::Authentication::KeyNanny

=head 1 Description

Lightweight connector to check passwords against a Keynanny daemon.
LOCATION must point to the keynannyd socket file, PREFIX can be set
and is added in front of the username to build the keynanny path.
Note that prefix must be given in connector syntax (dot seperator).

=head2 Usage

The username is the last component of the path, the password needs to be
passed in the extended parameters using the key password.

Example:

   $connector->get('username', {  password => 'mySecret' } );

=head2 Return values

1 if the password matches, 0 if the user is found but the password does not
match and undef if the user is not found.

The connector will die if keynanny is unreachable.

=head2 Limitations

Usernames are limited to [a-zA-Z0-9_\-\.], invalid names are treated as not
found.




