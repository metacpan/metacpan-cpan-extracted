package Auth::ActiveDirectory;

=head1 NAME

Auth::ActiveDirectory - Authentication module for MS ActiveDirectory

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

use strict;
use warnings FATAL => 'all';
use Net::LDAP qw[];
use Net::LDAP::Constant qw[LDAP_INVALID_CREDENTIALS];
my $ErrorCodes = {
    '525' => { error => 'user not found' },
    '52e' => { error => 'invalid credentials' },
    '530' => { error => 'not permitted to logon at this time' },
    '531' => { error => 'not permitted to logon at this workstation' },
    '532' => { error => 'password expired' },
    '533' => { error => 'data 533' },
    '701' => { error => 'account expired' },
    '773' => { error => 'user must reset password' },
    '775' => { error => 'user account locked' },
    '534' => {
        error       => 'account disabled',
        description => 'The user has not been granted the requested logon type at this machine'
    },
};

=head1 SUBROUTINES/METHODS

=cut

{

=head2 _ad2unixtimestamp

This value represents the number of 100-nanosecond intervals since January 1, 1601 (UTC).
https://msdn.microsoft.com

ad_timestamp / nanoseconds - offset to 1601

=cut

    sub _ad2unixtimestamp { $_[0] / 10000000 - 11644473600 }

=head2 _create_connection

=cut

    sub _create_connection {
        my ( $host, $port, $timeout ) = @_;
        return Net::LDAP->new( $host, port => $port || 389, timeout => $timeout || 60 ) || sub {
            die qq/Failed to connect to '$host'. Reason: '$@'/;
            return;
        };
    }

=head2 _v_is_error

=cut

    sub _v_is_error {
        my ( $message, $s_user ) = @_;
        return 0 if ( !$message->is_error );
        my $error = $message->error;
        my $level = $message->code == LDAP_INVALID_CREDENTIALS ? 'debug' : 'error';
        die qq/Failed to authenticate user '$s_user'. Reason: '$error'/;
        return 1;
    }

=head2 _parse_error_message

=cut

    sub _parse_error_message {
        my ($message)   = @_;
        my ($errorcode) = $message->{errorMessage} =~ m/(?:data\s(.*)),/;
        return $ErrorCodes->{$errorcode};
    }

=head2 _search_users

=cut

    sub _search_users {
        my ( $self, $filter ) = @_;
        return $self->ldap->search( base => $self->base, filter => $filter );
    }

}

=head2 new

Constructor

=cut

sub new {
    my $class = shift;
    my $self  = {@_};
    bless $self, $class;
    $self->{base} = qq/dc=$self->{domain},dc=$self->{principal}/ unless $self->{base};
    $self->{ldap} = _create_connection( $self->{host}, $self->{port}, $self->{timeout} ) unless $self->{ldap};
    return $self;
}

=head2 authenticate

Basicaly the subroutine for authentication in the ActiveDirectory

=cut

sub authenticate {
    my ( $self, $username, $password ) = @_;
    return unless $self->ldap;
    my $user = sprintf( '%s@%s', $username, $self->domain );
    my $message = $self->ldap->bind( $user, password => $password );
    if ( _v_is_error( $message, $user ) ) {
        $self->error_message( _parse_error_message($message) );
        return;
    }

    my $result = $self->_search_users( qq/(&(objectClass=person)(userPrincipalName=$user./ . $self->principal . '))' );
    foreach ( $result->entries ) {
        require Auth::ActiveDirectory::Group;
        require Auth::ActiveDirectory::User;
        return Auth::ActiveDirectory::User->new(
            uid               => $username,
            user              => $user,
            firstname         => $_->get_value(q/givenName/),
            surname           => $_->get_value(q/sn/),
            display_name      => $_->get_value(q/displayName/),
            mail              => $_->get_value(q/mail/),
            last_password_set => _ad2unixtimestamp( $_->get_value('pwdLastSet') ),

            # A value of 0 or 0x7FFFFFFFFFFFFFFF (9223372036854775807) indicates that the account never expires.
            # https://msdn.microsoft.com/en-us/library/ms675098(v=vs.85).aspx
            account_expires => ( $_->get_value('accountExpires') != 9223372036854775807 ) ? _ad2unixtimestamp( $_->get_value('accountExpires') ) : undef,
            groups => [ map { m/^CN=(.*),OU=.*$/ ? Auth::ActiveDirectory::Group->new( name => $1 ) : () } $_->get_value(q/memberOf/) ],

        );
    }
    return;
}

=head2 list_users

=cut

sub list_users {
    my ( $self, $user, $password, $search_string ) = @_;
    my $connection = $self->ldap || return;
    my $message = $connection->bind( $user, password => $password );
    if ( _v_is_error( $message, $user ) ) {
        $self->error_message( _parse_error_message($message) );
        return;
    }
    my $result = $self->_search_users(qq/(&(objectClass=person)(name=$search_string*))/);
    return [ map { Auth::ActiveDirectory::User->new( name => $_->get_value(q/name/), uid => $_->get_value(q/sAMAccountName/) ) } $result->entries ];
}

=head2 host

Getter/Setter for internal hash key host.

=cut

sub host {
    return $_[0]->{host} unless $_[1];
    $_[0]->{host} = $_[1];
    return $_[0]->{host};
}

=head2 port

Getter/Setter for internal hash key port.

=cut

sub port {
    return $_[0]->{port} unless $_[1];
    $_[0]->{port} = $_[1];
    return $_[0]->{port};
}

=head2 timeout

Getter/Setter for internal hash key timeout.

=cut

sub timeout {
    return $_[0]->{timeout} unless $_[1];
    $_[0]->{timeout} = $_[1];
    return $_[0]->{timeout};
}

=head2 domain

Getter/Setter for internal hash key domain.

=cut

sub domain {
    return $_[0]->{domain} unless $_[1];
    $_[0]->{domain} = $_[1];
    return $_[0]->{domain};
}

=head2 principal

Getter/Setter for internal hash key principal.

=cut

sub principal {
    return $_[0]->{principal} unless $_[1];
    $_[0]->{principal} = $_[1];
    return $_[0]->{principal};
}

=head2 ldap

Getter/Setter for internal hash key ldap.

=cut

sub ldap {
    return $_[0]->{ldap} unless $_[1];
    $_[0]->{ldap} = $_[1];
    return $_[0]->{ldap};
}

=head2 base

Getter/Setter for internal hash key base.

=cut

sub base {
    return $_[0]->{base} unless $_[1];
    $_[0]->{base} = $_[1];
    return $_[0]->{base};
}

=head2 error_message

Get error message if something is going wrong.

=cut

sub error_message {
    return $_[0]->{_error_message} unless $_[1];
    $_[0]->{_error_message} = $_[1];
    return $_[0]->{_error_message};
}

1;    # Auth::ActiveDirectory

__END__

=head1 SYNOPSIS

    use Auth::ActiveDirectory;

    my $obj = Auth::ActiveDirectory->new(
        host      => $args{host},
        port      => $args{port} || 389,
        timeout   => $args{timeout} || 60,
        domain    => $args{domain},
        principal => $args{principal},
    );

    # returns object from logged in user or undef if it fails
    my $user = $obj->authenticate( $args{username}, $args{password} );
    

=head1 AUTHOR

Mario Zieschang, C<< <mziescha at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Auth-ActiveDirectory at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Auth-ActiveDirectory>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 MOTIVATION

If you have a run in programming you don't always notice all packages in this moment.
And later when someone will know which packages are used, it's not neccessary to look at all of the packages.

Usefull for the Makefile.PL or Build.PL.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Auth::ActiveDirectory


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Auth-ActiveDirectory>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Auth-ActiveDirectory>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Auth-ActiveDirectory>

=item * Search CPAN

L<http://search.cpan.org/dist/Auth-ActiveDirectory/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Mario Zieschang.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
