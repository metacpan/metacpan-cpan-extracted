#
# This file is part of Authen-U2F-Tester
#
# This software is copyright (c) 2017 by Michael Schout.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Authen::U2F::Tester::Role::Response;
$Authen::U2F::Tester::Role::Response::VERSION = '0.02';
# ABSTRACT: U2F Successful Response Role

use Moose::Role;
use strictures 2;
use Authen::U2F::Tester::Const qw(OK);
use namespace::autoclean;


has response => (is => 'ro', isa => 'Value', required => 1);


has error_code => (is => 'ro', isa => 'Int', required => 1);


has client_data => (is => 'ro', isa => 'Str', required => 1);


sub is_success {
    my $self = shift;

    return $self->error_code == OK ? 1 : 0;
}

1;

__END__

=pod

=head1 NAME

Authen::U2F::Tester::Role::Response - U2F Successful Response Role

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 # This is used by successful tester U2F responses

=head1 DESCRIPTION

This is a role used by successful L<Authen::U2F::Tester> responses.  Successful
responses consume this role.

=head1 METHODS

=head2 response(): scalar

Get the raw U2F register response.  This is a binary string representing a
successful registration response.  See
L<The FIDO Specification|https://fidoalliance.org/specs/fido-u2f-v1.2-ps-20170411/fido-u2f-raw-message-formats-v1.2-ps-20170411.html#registration-response-message-success> for the details on the contents of this string.

=head2 error_code(): int

Get the error code

=head2 client_data()

Get the client data from the request, in Base64 URL format.

=head2 is_success(): bool

Returns true if the response was successful, false otherwise.

=for Pod::Coverage OK

=head1 SEE ALSO

=over 4

=item *

L<Authen::U2F::Tester::RegisterResponse>

=item *

L<Authen::U2F::Tester::SignResponse>

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
