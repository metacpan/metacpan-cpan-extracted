package Business::NAB;

# ABSTRACT: Top level namespace for the various NAB file formats

=head1 NAME

Business::NAB

=head1 VERSION

0.01

=head1 DESCRIPTION

Business::NAB is the top level namespace for the various modules
that are used to parse/create the file formats used for interchange
with NAB.

This module doesn't do anything, rather it serves to link to the
modules that you want to use.

=head1 L<Business::NAB::Types>

Package for defining type constraints for use in the Business::NAB
namespace. All types are namespaced to "NAB::Type::*".

=head1 L<Business::NAB::BPAY::Payments>

Class for parsing / creating a NAB BPAY batch payments file

=head1 L<Business::NAB::BPAY::Remittance::File>

Class for parsing / creating a NAB BPAY remittance/reporting file

=head1 L<Business::NAB::Australian::DirectEntry::Payments>

Class for building/parsing a "Australian Direct Entry Payments" file

=head1 L<Business::NAB::Australian::DirectEntry::Returns>

Class for building/parsing a "Australian Direct Entry Payments" return file

=head1 L<Business::NAB::Australian::DirectEntry::Report>

Class for building/parsing a "Australian Direct Entry Payments" report file

=head1 L<Business::NAB::AccountInformation::File>

Class for parsing a NAB "Account Information File (NAI/BAI2)" file

=head1 L<Business::NAB::Acknowledgement>

Class for parsing NAB file acknowledgements, which are XML files

=cut

$Business::NAB::VERSION = '0.01';

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/payprop/business-nab

=cut

1;
