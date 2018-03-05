package Business::RO::TaxDeduction;
$Business::RO::TaxDeduction::VERSION = '0.012';
# ABSTRACT: Romanian salary tax deduction calculator

use 5.010001;
use utf8;
use Moo;
use MooX::HandlesVia;
use Math::BigFloat;
use Scalar::Util qw(blessed);
use Business::RO::TaxDeduction::Types qw(
    Int
    MathBigFloat
);
use Business::RO::TaxDeduction::Amount;
use Business::RO::TaxDeduction::Ranges;
use Business::RO::TaxDeduction::Table;

has 'vbl' => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has 'year' => (
    is       => 'ro',
    isa      => Int,
    default  => sub { 2018 },
);

has 'persons' => (
    is       => 'ro',
    isa      => Int,
    default  => sub { 0 },
);

has 'deduction' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return Business::RO::TaxDeduction::Amount->new(
            year    => $self->year,
            persons => $self->persons,
        );
    },
);

has 'ranges' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return Business::RO::TaxDeduction::Ranges->new(
            year => $self->year,
        );
    },
    handles => [ qw( vbl_min vbl_max f_min f_max ) ],
);

has 'ten' => (
    is      => 'ro',
    isa     => MathBigFloat,
    default => sub {
        return Math::BigFloat->new(10);
    },
);

sub tax_deduction {
    my $self   = shift;
    my $vbl    = $self->_round_to_int( $self->vbl );

    return $self->_amount_for_2018 if $self->year >= 2018;

    my $amount = $self->deduction->amount;
    if ( $vbl <= $self->vbl_min ) {
        return $amount;
    }
    elsif ( ( $vbl > $self->vbl_min ) && ( $vbl <= $self->vbl_max ) ) {
        $amount = $self->_tax_deduction_formula($vbl, $amount);
        return ( blessed $amount ) ? $amount->bstr : $amount;
    }
    else {
        return 0;               # 0 for VBL > vbl_max
    }
}

sub _tax_deduction_formula {
    my ( $self, $vbl, $base_deduction ) = @_;
    my $amount = $base_deduction * ( 1 - ( $vbl - $self->f_min ) / $self->f_max );
    return $self->_round_to_tens($amount);
}

sub _round_to_int {
    my ( $self, $amount ) = @_;
    return int( $amount + 0.5 * ( $amount <=> 0 ) );
}

sub _round_to_tens {
    my ( $self, $para_amount ) = @_;
    my $amount = Math::BigFloat->new($para_amount);

    return 0 if $amount == 0;

    my $afloor  = $amount->copy()->bfloor();
    my $amodulo = $afloor->copy()->bmod( $self->ten );

    return $amount if $amount->is_int && $amodulo == 0;
    return $afloor->bsub($amodulo)->badd( $self->ten );
}

sub _amount_for_2018 {
    my $self = shift;
    my $table =  Business::RO::TaxDeduction::Table->new(
        year    => $self->year,
        persons => $self->persons,
        vbl     => $self->vbl,
    );
    return $table->deduction;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::RO::TaxDeduction - Romanian salary tax deduction calculator

=head1 VERSION

version 0.012

=head1 SYNOPSIS

    use Business::RO::TaxDeduction;

    my $brtd = Business::RO::TaxDeduction->new(
        vbl     => 1400,
        persons => 3,
    );
    my $amount = $brtd->tax_deduction;

=head1 DESCRIPTION

Romanian salary tax deduction calculator.

=head1 INTERFACE

=head2 ATTRIBUTES

=head3 vbl

The C<vbl> attribute holds the input amount of the tax deduction
calculation.  (ro: Venit Brut Lunar).

=head3 year

The C<year> attribute holds the year of the tax deduction calculation.

=head3 persons

The C<persons> attribute holds the number of persons.  Not required,
the default is 0.

=head3 deduction

The C<deduction> attribute holds a
C<Business::RO::TaxDeduction::Amount> object instance.

=head3 ten

A Math::BigFloat object instance for 10.

=head3 five

A Math::BigFloat object instance for 5.

=head2 INSTANCE METHODS

=head3 tax_deduction

Return the deduction calculated for the given amount.

Starting with the current version (0.004) the appropriate algorithm
for the tax deduction calculation year is chosen.

=head3 _tax_deduction_formula

Formula for calculating the tax deduction for amounts above C<vbl_min>
and less or equal to C<vbl_max>.

=head3 _round_to_int

Custom rounding method to the nearest integer.  It uses the Romanian
standard for rounding in bookkeeping.

Example:

  10.01 -:- 10.49 => 10
  10.50 -:- 10.99 => 11

=head3 _round_to_tens

Round up to tens.  Uses Math::BigFloat to prevent rounding errors like
when amount minus floor(amount) gives something like 7.105427357601e-15.

=head1 AUTHOR

Ștefan Suciu <stefan@s2i2.ro>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Ștefan Suciu.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
