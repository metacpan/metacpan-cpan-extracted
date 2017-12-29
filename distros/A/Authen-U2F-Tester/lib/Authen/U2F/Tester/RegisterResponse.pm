#
# This file is part of Authen-U2F-Tester
#
# This software is copyright (c) 2017 by Michael Schout.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Authen::U2F::Tester::RegisterResponse;
$Authen::U2F::Tester::RegisterResponse::VERSION = '0.01';
# ABSTRACT: U2F Tester Registration Response

use Moose;
use strictures 2;
use MIME::Base64 qw(encode_base64url);
use namespace::autoclean;

with qw(Authen::U2F::Tester::Role::Response);


sub registration_data {
    return encode_base64url(shift->response);
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

Authen::U2F::Tester::RegisterResponse - U2F Tester Registration Response

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 use Authen::U2F::Tester;

 my $tester = Authen::U2F::Tester->new(...);

 my $res = $tester->register(...);

 print $res->client_data;
 print $res->registration_data;

 # print the binary response in hex format
 print unpack 'H*', $res->response;

=head1 DESCRIPTION

This class represents a successful response to a registration request.

=head1 METHODS

=head2 registration_data(): string

Get the registration data from the tester's register request, in
Base64 URL encoding.

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
