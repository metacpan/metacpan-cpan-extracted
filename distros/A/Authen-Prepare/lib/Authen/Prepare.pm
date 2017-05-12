#------------------------------------------------------------------------------
# $Id$
#
package Authen::Prepare;

use warnings;
use strict;

our $VERSION = '0.05';

#------------------------------------------------------------------------------
# Load Modules

use 5.006;

# Standard Modules
use Carp;
use English qw(-no_match_vars);
use Readonly;

#use Smart::Comments;

# Specific Modules
use Fcntl qw(:mode);
use IO::Prompt;
use Text::Glob qw(match_glob);

#------------------------------------------------------------------------------
# Class Specification

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(hostname username passfile prefix timeout));

#------------------------------------------------------------------------------
# Constants

Readonly my $DEFAULT_TIMEOUT => 10;
Readonly my $EMPTY_STR       => q{};
Readonly my $FIELD_DELIMITER => q{:};
Readonly my $PASSWORD_CHAR   => q{*};

#------------------------------------------------------------------------------
# Methods

sub credentials {
    my ($self) = @_;
    my $prefix = $self->prefix || $EMPTY_STR;

    my %cred = (
        hostname => $self->_prompt_while_empty(
            $self->hostname, qq|${prefix}Hostname: |
        ),
        username => $self->_prompt_while_empty(
            $self->username, qq|${prefix}Username: |
        ),
    );

    $cred{password} = $self->passfile
        ? $self->_get_password_for( @cred{qw(hostname username)} )
        : undef;

    if ( !defined $cred{password} ) {
        $cred{password} = $self->_prompt_timed(
            $self->timeout,
            qq|${prefix}Password: |,
            -echo => $PASSWORD_CHAR,
            -tty
        );
    }

    @cred{qw(host user)} = @cred{qw(hostname username)};

    return wantarray ? %cred : \%cred;
}

#------------------------------------------------------------------------------
# Internal Methods

sub _get_password_for {
    my ( $self, $hostname, $username ) = @_;

    $self->_check_passfile();

    # FIXME - duplicate string
    my $err_prefix = qq{Unable to use password file $self->passfile: };

    open my $fh, '<', $self->passfile or croak $err_prefix, $OS_ERROR;

    LINE:
    while (<$fh>) {
        next LINE if /^\s*\#/xms;
        chomp;
        my ( $stored_hostname, $stored_username, $stored_password )
            = split /$FIELD_DELIMITER/;

        return $stored_password
            if ( $stored_username eq $username
            && match_glob( $stored_hostname, $hostname ) );
    }

    return;
}

sub _check_passfile {
    my ($self) = @_;
    my $passfile = $self->passfile;

    croak qq{Unable to read unspecified password file} if !$passfile;

    # FIXME - duplicate string
    my $err_prefix = qq{Unable to use password file $passfile: };

    my $mode = ( stat $passfile )[2] or croak $err_prefix, $OS_ERROR;

    if ( ( $mode & S_IRWXG ) >> 3 ) {
        croak $err_prefix, 'Permissions include group';
    }

    if ( $mode & S_IRWXO ) {
        croak $err_prefix, 'Permissions include all users (other)';
    }

    return;
}

sub _prompt_while_empty {
    my ( $self, $response, $prompt ) = @_;
    $response = $EMPTY_STR if !defined $response;

    while ( $response eq $EMPTY_STR ) {
        $response = $self->_prompt_timed( $self->timeout, $prompt, -tty );
    }

    return $response;
}

sub _prompt_timed {
    my ( $self, $timeout, @args ) = @_;
    my $response;

    $timeout = $DEFAULT_TIMEOUT if !defined $timeout;

    eval {
        local $SIG{ALRM} = sub {
            die qq{Prompt timed out after $timeout seconds\n};
        };

        alarm $timeout;

        eval { $response = prompt @args; };

        alarm 0;
        die $EVAL_ERROR if $EVAL_ERROR;
    };

    alarm 0;
    croak $EVAL_ERROR if $EVAL_ERROR;

    # Stringify response since it is an IO::Prompt object
    return ( defined $response ) ? qq{$response} : $EMPTY_STR;
}

#------------------------------------------------------------------------------

1;    # Magic true value required at end of module
__END__

=head1 NAME

Authen::Prepare - Prepare a set of authentication credentials


=head1 VERSION

This document describes Authen::Prepare version 0.05


=head1 SYNOPSIS

    use Authen::Prepare;

    # Prompt for the hostname, username, and password
    my $authen = Authen::Prepare->new();

    # The '%cred' hash now has the keys 'hostname', 'username', 
    # and 'password'
    my %cred = $authen->credentials();

    # Specify hostname as 'localhost'. Prompt for username and password
    my $authen = Authen::Prepare->new( { hostname => 'localhost' } );
    my %cred = $authen->credentials();

    # Specify a hostname as 'localhost', username as 'testuser', and a 
    # password file as '~/.authrc'. No prompting will occur if the 
    # hostname and username are found in the password file.
    my $authen = Authen::Prepare->new( 
        { 
            hostname => 'localhost',
            username => 'testuser',
            passfile => '~/.authrc',
        } 
    );

    my %cred = $authen->credentials();

    # Assuming %opt contains the set of command-line arguments, specify 
    # the hostname, username, and password file with the command-line 
    # arguments or with environment variables as a fallback.  
    my $authen = Authen::Prepare->new( 
        { 
            hostname => $opt{hostname} || $ENV{MY_HOSTNAME},
            username => $opt{username} || $ENV{MY_USERNAME},
            passfile => $opt{passfile} || $ENV{MY_PASSFILE},
        } 
    );

    my %cred = $authen->credentials();
  
    # The '%cred' hash can be used to authenticate in scripts or modules with
    # the stored hostname, username, and password
    $foo->authenticate(%cred);
  

=head1 DESCRIPTION

Authen::Prepare sets up authentication credentials for a specific hostname,
username, and password using a combination of stored information and user
prompts. These credentials can be used in other scripts or modules that
require authentication information. Using this module allows these other
scripts to be flexible in their usage of authentication information without
recoding user prompts or storing passwords in the code.

The simplest use of this module is to create the initial object it with no
arguments; the credentials will be built from a set of user prompts.

A more full-featured use of this module is to specify all authentication
information ahead of time using a password file and command-line arguments or
environment variables. The initial object can then be created with three named
arguments (hostname, username, and passfile) and the credentials for the
specified hostname and username will be extracted from the password file. This
allows the calling script to be used in an automated environment.

Any combination of the named arguments can be provided; the user will be
prompted for any missing information.

=head2 Password File

The password file must not have any group or world permissions in order to be
usable by this module. Each line of the password file should contain the
hostname, username, and password separated by a colon.

Wildcards are supported in the hostname field only. This allows a default host
to be specified.

Comments may be added by prefixing a line with the '#' character. (Inline
comments are not supported at this time.)

NOTE: The password file is read from top to bottom so only the first match
will be returned.

  Example:

  # this is a comment
  hostname1:username1:password1
  hostname2:username2:password2
  host*:username:password
  # default hostname
  *:username:password


=head1 INTERFACE 

=over

=item new()

=item new(\%options)

The constructor 'new' creates the initial object and sets up the cached
credentials for a hostname, username, and password file. If the hostname,
username, or passfile accessors are not specified, the user will be prompted.

Any of the accessors (see below) can be used as named arguments.

  Example:
  # Prompt for everything
  my $authen = Authen::Prepare->new();

  # Prompt for hostname. Use specified username and passfile
  my $authen = Authen::Prepare->new(
    { username => $username, passfile => $passfile });

  # Prompt for username. Use specified hostname and passfile
  my $authen = Authen::Prepare->new(
    { hostname => $hostname, passfile => $passfile });

  # Prompt for password. Use specified hostname and username
  my $authen = Authen::Prepare->new(
    { hostname => $hostname, username => $username });

=item credentials()

The 'credentials' method returns the cached credentials in the form of a hash
with the following keys:

  * hostname
  * username
  * password

Note: This method is context sensitive: in scalar context, it will return a
hash reference.

=back

=head2 Accessors

=over

=item hostname()

=item hostname(HOSTNAME)

Get or set the hostname.

=item username()

=item username(USERNAME)

Get or set the username.

=item passfile()

=item passfile(PASSFILE)

Get or set the password file.

=item prefix()

=item prefix(PREFIX)

Get or set the prompt prefix. Default is no prefix.

=item timeout()

=item timeout(TIMEOUT)

Get or set the prompt timeout (in seconds). Default is 10.

=back

=head1 DIAGNOSTICS

=over

=item C<< Unable to use password file %s: %s >>

The password file doesn't exist or invalid permissions. Make sure the password
file has no 'group' or 'other' permissions and is formatted correctly.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Authen::Prepare requires no configuration files or environment variables.

An optional password file may be used to store authentication credentials.
Environment variables from calling scripts may be used to specify one or more
of the named arguments to the constructor (e.g. $ENV{MY_HOSTNAME} or
$ENV{MY_PASSFILE}).

=head1 DEPENDENCIES

=over

=item IO::Prompt

=item Readonly

=item Text::Glob

=back

=head1 INCOMPATIBILITIES


None reported.


=head1 BUGS AND LIMITATIONS


No bugs have been reported.

Please report any bugs or feature requests to
C<bug-authen-prepare@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

David Narayan  C<< <dnarayan@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, David Narayan  C<< <dnarayan@cpan.org> >>. All rights
reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
