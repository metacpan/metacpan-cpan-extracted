package Authen::Simple::Gmail;

use strict;
use warnings;

$Authen::Simple::Gmail::VERSION = '0.2';

use IO::Socket::SSL         ();
use Authen::Simple::Adapter ();
use base 'Authen::Simple::Adapter';

my $portable_crlf = "\015\012";    # "\r\n" is not portable

sub check {
    my ( $self, $username, $password ) = @_;

    my $sock = IO::Socket::SSL->new(
        'PeerHost'        => "pop.gmail.com",
        'PeerPort'        => "995",
        'SSL_verify_mode' => IO::Socket::SSL::SSL_VERIFY_NONE,    # Patches welcome!
    );

    if ( !$sock ) {
        $self->log->error( IO::Socket::SSL->errstr() ) if $self->log;
        return;
    }

    my $line = <$sock>;                                           # welcome msg

    # d("init: $line");
    print {$sock} "USER $username$portable_crlf";
    $line = <$sock>;

    # d("user: $line");
    if ( $line !~ /^\+OK/ ) {
        $self->log->debug("user not OK: $line") if $self->log;
        __socket_end($sock);
        return;
    }

    print {$sock} "PASS $password$portable_crlf";
    $line = <$sock>;

    # d("pass: $line");
    if ( $line !~ /^\+OK/ ) {
        $self->log->debug("user/pass not OK: $line") if $self->log;
        __socket_end($sock);
        return;
    }

    __socket_end($sock);
    return 1;
}

sub __socket_end {
    my ($sock) = @_;
    print {$sock} "QUIT$portable_crlf";
    $sock->close( 'SSL_ctx_free' => 1 );
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Authen::Simple::Gmail - Simple authentication using Gmail

=head1 VERSION

This document describes Authen::Simple::Gmail version 0.2

=head1 SYNOPSIS

    use Authen::Simple::Gmail;

    my $gmail_auth = Authen::Simple::Gmail->new();

    if ( $gmail_auth->authenticate( $username, $password ) ) {
        # successful Gmail authentication
    }
    else {
        # failed Gmail authentication
    }

=head1 DESCRIPTION

This adapter allows you to have gmail authentication support yo your L<Authen::Simple> stack.

=head1 INTERFACE 

Same as any L<Authen::Simple> adapter. See SYNOPSIS and L<Authen::Simple>.

=head2 check()

The adapter method. See L<Authen::Simple::Adapter>.

=head1 DIAGNOSTICS

Throws no warnings or errors of its own.

If authenticate() returns false and the object has a log() it will call: 

=over 4

=item error() if the SSL object could not be created

=item debug() if the user or pass did not work

=back

=head1 CONFIGURATION AND ENVIRONMENT
  
Authen::Simple::Gmail requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Authen::Simple::Adapter> for subclassing.

L<IO::Socket::SSL> for the SSL socket

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-authen-simple-gmail@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

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
