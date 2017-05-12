use strict;
use warnings;

use 5.006;

package Business::CA::GST;
$Business::CA::GST::VERSION = '1.03';
use Moo;
use Carp qw( croak );

my %TAX = (
    AB => { rate => 0.05, type => 'GST' },
    BC => { rate => 0.12, type => 'GST' },
    MB => { rate => 0.05, type => 'GST' },
    NB => { rate => 0.13, type => 'HST' },
    NL => { rate => 0.13, type => 'HST' },
    NS => { rate => 0.15, type => 'HST' },
    NT => { rate => 0.05, type => 'GST' },
    ON => { rate => 0.13, type => 'HST' },
    PE => { rate => 0.05, type => 'GST' },
    SK => { rate => 0.05, type => 'GST' },
    QC => { rate => 0.05, type => 'GST' },
    YT => { rate => 0.05, type => 'GST' },
    NU => { rate => 0.05, type => 'GST' },
);

has 'buyer_region' => ( is => 'rw', );

sub rate {
    my $self = shift;

    $self->_validate_region;
    return $TAX{ $self->buyer_region }->{rate};
}

sub tax_type {
    my $self = shift;

    $self->_validate_region;
    return $TAX{ $self->buyer_region }->{type};
}

sub _validate_region {
    my $self = shift;

    if ( !exists $TAX{ $self->buyer_region } ) {
        croak "invalid buyer_region: " . $self->buyer_region;
    }

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Look up Canadian Federal Sales Tax rates

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CA::GST - Look up Canadian Federal Sales Tax rates

=head1 VERSION

version 1.03

=head1 SYNOPSIS

    use Business::CA::GST
    my $tax = Business::CA::GST->new;
    $tax->buyer_region('ON');

    print $tax->rate, "\n";     # gives 0.13
    print $tax->tax_type, "\n"; # gives 'HST'

=head1 DESCRIPTION

A tax table for Canadian GST/HST payments. Actual tax calculations are left as
an exercise for the reader. Please see
L<http://en.wikipedia.org/wiki/Sales_taxes_in_Canada> for a more detailed
explanation of how GST and HST works (it's not as simple as one might hope).

=head1 CONSTRUCTOR AND STARTUP

=head2 new( buyer_region => $region )

Creates and returns a new Business::CA::GST object.

    my $tax = Business::CA::GST->new();

=over 4

=item C<< buyer_region => $region_code >>

You may pass this parameter to new(), and/or you may use the buyer_region()
method after having created the object. See the buyer_region() documentation
below for a list of allowable region codes.

    my $tax = Business::CA::GST->new( buyer_region => $region_code );

=back

=head1 SUBROUTINES/METHODS

=head2 buyer_region( $region )

The only required parameter.  Must be one of:

AB, BC, MB, NB, NL, NS, NT, ON, PE, SK, QC, YT, NU

=head2 rate

Returns the GST/HST as a floating point number. eg 13% is returned as 0.13

=head2 tax_type

Returns either 'GST' or 'HST'

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Business::CA::GST

You can also look for information at:

=over 4

=item Source code

L<http://github.com/oalders/business-ca-gst>

=item Search CPAN

L<https://metacpan.org/module/Business::CA::GST>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Raybec Communications L<http://www.raybec.com> for funding my
work on this module and for releasing it to the world.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
