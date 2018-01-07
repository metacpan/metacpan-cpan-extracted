#
# This file is part of Authen-U2F-Tester
#
# This software is copyright (c) 2017 by Michael Schout.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Authen::U2F::Tester::SignResponse;
$Authen::U2F::Tester::SignResponse::VERSION = '0.02';
# ABSTRACT: U2F Tester Sign Response

use Moose;
use MIME::Base64 qw(encode_base64url);
use namespace::autoclean;

with qw(Authen::U2F::Tester::Role::Response);


has key_handle => (is => 'ro', isa => 'Str', required => 1);


sub signature_data {
    encode_base64url(shift->response);
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

Authen::U2F::Tester::SignResponse - U2F Tester Sign Response

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 my $res = $tester->sign($app_id, $challenge, @keyhandles);

 print $res->client_data;
 print $res->key_handle;

 print unpack 'H*', $res->response;

=head1 DESCRIPTION

This class is a signing response from a U2F signing request.

=head1 METHODS

=head2 key_handle(): string

Get the key handle, in Base64 URL format.

=head2 signature_data(): string

Get the signature data from the response, in Base64 URL encoded format.

=head1 SEE ALSO

=over 4

=item *

L<Authen::U2F::Tester::Role::Response>

=item *

L<Authen::U2F::Tester>

=back

=head1 SOURCE

The development version is on github at L<https://github.com/mschout/perl-authen-u2f-tester>
and may be cloned from L<git://github.com/mschout/perl-authen-u2f-tester.git>

=head1 BUGS

Please report any bugs or feature requests to bug-authen-u2f-tester@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Authen-U2F-Tester

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
