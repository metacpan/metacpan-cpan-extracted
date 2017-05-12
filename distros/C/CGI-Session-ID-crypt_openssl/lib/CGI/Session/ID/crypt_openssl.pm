package CGI::Session::ID::crypt_openssl;

use warnings;
use strict;

=head1 NAME

CGI::Session::ID::crypt_openssl - CGI::Session ID driver for generating IDs based on Crypt::OpenSSL::Random

=head1 VERSION

Version 1.02

=cut

$CGI::Session::ID::crypt_openssl::VERSION = '1.02';

use CGI::Session::ErrorHandler;
@CGI::Session::ID::crypt_openssl::ISA = qw/CGI::Session::ErrorHandler/;

=head1 SYNOPSIS

    use CGI::Session;
    $session = CGI::Session->new('id:crypt_openssl', undef);

=cut

sub generate_id {
	my $self = shift;
	my $random	= Crypt::OpenSSL::Random::random_bytes(16) || $$. time(). rand(time);
	my $md5 = new Digest::MD5();
	$md5->add( $random );
	return $md5->hexdigest();
}

=head1 DESCRIPTION

Use this module to generate hexadecimal IDs generated with
L<Crypt::OpenSSL::Random> for L<CGI::Session> objects. This library does not
require any arguments. Use this module to generate security IDs with a high
level of randomnes.

=head2 METHODS

=over 4

=item generate_id()

This subroutine is calling by the L<CGI::Session> Module to generate an ID for the session.

=back

=head1 AUTHOR

Helmut Weber, C<< <helmut.weber at bitbetrieb.de> >>

=head1 CREDITS

My Sweetheart Sabrina and my lovely childs Jolina and Marcella

Mark Stosberg for the great support

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013 bitbetrieb. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<CGI::Session>,
L<Digest::MD5>,
L<Crypt::OpenSSL::Random>

=cut

1; # End of CGI::Session::ID::crypt_openssl
