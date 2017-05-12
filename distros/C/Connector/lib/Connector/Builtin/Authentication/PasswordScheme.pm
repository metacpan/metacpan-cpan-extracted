# Connector::Builtin::Authentication::PasswordScheme
#
# Check passwords against a file with salted hashes and scheme prefix
#
package Connector::Builtin::Authentication::PasswordScheme;

use strict;
use warnings;
use English;
use Data::Dumper;

use MIME::Base64;
use Digest::SHA;
use Digest::MD5;

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

            # This code is mainly a copy of OpenXPKI::Server::Authentication::Password
            # but we do not support unsalted passwords
            # digest specified in RFC 2307 userPassword notation?
            my $encrypted;
            my $scheme;
            if ($t[1] =~ m{ \{ (\w+) \} (.+) }xms) {
                $scheme = lc($1);
                $encrypted = $2;
            } else {
                $self->log()->error('unparsable entry ' . $t[1]);
                return 0;
            }

            my ($computed_secret, $salt);
            eval {
                if ($scheme eq 'ssha') {
                    $salt = substr(decode_base64($encrypted), 20);
                    my $ctx = Digest::SHA->new();
                    $ctx->add($password);
                    $ctx->add($salt);
                    $computed_secret = encode_base64($ctx->digest() . $salt, '');
                } elsif ($scheme eq 'smd5') {
                    $salt = substr(decode_base64($encrypted), 16);
                    my $ctx = Digest::MD5->new();
                    $ctx->add($password);
                    $ctx->add($salt);
                    $computed_secret = encode_base64($ctx->digest() . $salt, '');
                } elsif ($scheme eq 'crypt') {
                    $computed_secret = crypt($password, $encrypted);
                } else {
                    $self->log()->error('unsupported scheme' . $scheme);
                    return 0;
                }
            };

            $self->log()->debug('eval failed ' . $EVAL_ERROR->message()) if ($EVAL_ERROR);

            if (! defined $computed_secret) {
                $self->log()->error('unable to compute secret using scheme ' . $scheme);
                return 0;
            }

            ##! 2: "ident user ::= $account and digest ::= $computed_secret"
            $computed_secret =~ s{ =+ \z }{}xms;
            $encrypted       =~ s{ =+ \z }{}xms;

            ## compare passphrases
            if ($computed_secret eq $encrypted) {
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

Connector::Builtin::Authentication::PasswordScheme

=head 1 Description

Lightweight connector to check passwords against a password file holding
username/password pairs where the password is encrypted using a salted hash.
Password notation follows RFC2307 ({scheme}saltedpassword) but we support
only salted schemes: smd5, ssha and crypt.

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

