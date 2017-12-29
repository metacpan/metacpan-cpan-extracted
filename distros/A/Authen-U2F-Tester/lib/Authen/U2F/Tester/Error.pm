#
# This file is part of Authen-U2F-Tester
#
# This software is copyright (c) 2017 by Michael Schout.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Authen::U2F::Tester::Error;
$Authen::U2F::Tester::Error::VERSION = '0.01';
# ABSTRACT: Authen::U2F::Tester Error Response

use Moose;
use MooseX::AttributeShortcuts;
use MooseX::SingleArg;

use Authen::U2F::Tester::Const ':all';
use namespace::autoclean;


has error_code => (is => 'ro', isa => 'Int', required => 1);


has error_message => (is => 'lazy', isa => 'Str');

single_arg 'error_code';


sub is_success { 0 }

sub _build_error_message {
    my $self = shift;

    my %errors = (
        OTHER_ERROR               => 'Other Error',
        BAD_REQUEST               => 'Bad Request',
        CONFIGURATION_UNSUPPORTED => 'Configuration Unsupported',
        DEVICE_INELIGIBLE         => 'Device Ineligible',
        TIMEOUT                   => 'Timeout');
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

Authen::U2F::Tester::Error - Authen::U2F::Tester Error Response

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 $r = $tester->register(...);

 # or

 $r = $tester->sign(...);

 unless ($r->is_success) {
     print $r->error_code;
     print $r->error_message;
 }

=head1 DESCRIPTION

This object is returned from L<Authen::U2F::Tester> sign or register requests
if the request resulted in an error.

=head1 METHODS

=head2 new(int)

Single arg constructor.  Argument is a U2F error code.  See
L<Authen::U2F::Tester::Const> for constants that should be used for this.

=head2 error_code(): int

Get the error code

=head2 error_message(): string

Get the error message

=head2 is_success(): bool

Returns false as this object is only returned for errors.

=head1 SEE ALSO

=over 4

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
