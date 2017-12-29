#
# This file is part of Authen-U2F-Tester
#
# This software is copyright (c) 2017 by Michael Schout.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Authen::U2F::Tester::Const;
$Authen::U2F::Tester::Const::VERSION = '0.01';
# ABSTRACT: Constants for Authen::U2F::Tester

use base 'Exporter';
use strictures 2;

my %constants;

BEGIN {
    %constants = (
        OK                        => 0,
        OTHER_ERROR               => 1,
        BAD_REQUEST               => 2,
        CONFIGURATION_UNSUPPORTED => 3,
        DEVICE_INELIGIBLE         => 4,
        TIMEOUT                   => 5);
}

use constant \%constants;

our @EXPORT_OK = keys %constants;

our %EXPORT_TAGS = (
    all => \@EXPORT_OK
);


1;

__END__

=pod

=head1 NAME

Authen::U2F::Tester::Const - Constants for Authen::U2F::Tester

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 # import constants explicitly by name
 use Authen::U2F::Tester::Const qw(OK DEVICE_INELIGIBLE);

 # import all constants
 use Authen::U2F::Tester::Const ':all';

 # example of a sign() request where the device has not been registered
 my $r = $tester->sign(...);

 if ($r->error_code == DEVICE_INELIGIBLE) {
    die "this device has not been registered";
 }

=head1 DESCRIPTION

This module provides error constants that are used by L<Authen::U2F::Tester>.

=head1 ATTRIBUTES

=head2 OK

This error code indicates a successful response.

=head2 OTHER_ERROR

This error indicates some other error happened.

=head2 BAD_REQUEST

This error code indicates the request cannot be processed.

=head2 CONFIGURATION_UNSUPPORTED

This error code indicates the client configuration is not supported.

=head2 DEVICE_INELIGIBLE

This error code indicates that the device is not eligible for this request.
For a registration request, this may mean the device has already been
registered.  For a signing request, this may mean the device was never
registered.

=head2 TIMEOUT

This error code indicates a timeout occurred waiting for the request to be
satisfied.

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
