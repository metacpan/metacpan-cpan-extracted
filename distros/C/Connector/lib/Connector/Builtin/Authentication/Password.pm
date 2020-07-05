# Connector::Builtin::Authentication::Password
#
# Check passwords against a unix style password file
#
package Connector::Builtin::Authentication::Password;

use strict;
use warnings;
use English;
use Data::Dumper;

use Moose;
extends 'Connector::Builtin';

sub _build_config {
    my $self = shift;

    if (! -r $self->{LOCATION}) {
       confess("Cannot open input file " . $self->{LOCATION} . " for reading.");
    }

    return 1;
}

sub get {
    my $self = shift;
    my $arg = shift;
    my $params = shift;

    my @path = $self->_build_path( $arg );
    my $user = shift @path;

    my $password = $params->{password};


    if (!$user) {
        $self->log()->error('No username');
        die "no username given";
    }

    if (!$password) {
        $self->log()->error('No password');
        die "no password given";
    }


    $self->log()->debug('verify password for ' . $user );

    if ($user =~ /[^a-zA-Z0-9_\-\.\@]/) {
        $self->log()->error('Invalid chars in username ('.$user.')');
        return $self->_node_not_exists( $user );
    }

    my $filename = $self->{LOCATION};

    if (! -r $filename || ! open FILE, "$filename") {
        $self->log()->error('Can\'t open/read from file ' . $filename);
        die 'Can\'t open/read from file ' . $filename;
    }

    while (<FILE>) {
        if (/^$user:/) {
            chomp;
            my @t = split(/:/, $_, 3);
            $self->log()->trace('found line ' . Dumper @t);
            #if ($password eq $t[1]) {
            if (not defined $t[1]) {
                $self->log()->info('Password value not defined for ' . $user);
                return 0;
            }

            if (crypt($password, $t[1]) eq $t[1]) {
                $self->log()->info('Password accepted for ' . $user);
                return 1;
            } else {
                $self->log()->info('Password mismatch for ' . $user);
                return 0;
            }
        }
    }
    return $self->_node_not_exists( $user );
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

    # No path = connector root which always exists
    my @path = $self->_build_path( shift );
    if (scalar @path == 0) {
        return 1;
    }

    my $user = shift @path;

    my $filename = $self->{LOCATION};
    if (! -r $filename || ! open FILE, "$filename") {
        $self->log()->error('Can\'t open/read from file ' . $filename);
        return 0;
    }

    while (<FILE>) {
        if (/^$user:/) {
            return 1;
        }
    }
    return 0;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head 1 Name

Connector::Builtin::Authentication::Password

=head 1 Description

Lightweight connector to check passwords against a unix style password file.
Path to the password file is taken from LOCATION.

=head2 Usage

The username is the first component of the path, the password needs to be
passed in the extended parameters using the key password.

Example:

   $connector->get('username', {  password => 'mySecret' } );

=head2 Return values

1 if the password matches, 0 if the user is found but the password does not
match and undef if the user is not found.

The connector will die if the password file is not readable or if one of
the parameters is missing.

=head2 Limitations

Usernames are limited to [a-zA-Z0-9_\-\.], invalid names are treated as not
found.

