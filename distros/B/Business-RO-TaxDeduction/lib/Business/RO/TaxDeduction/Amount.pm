package Business::RO::TaxDeduction::Amount;
$Business::RO::TaxDeduction::Amount::VERSION = '0.010';
# ABSTRACT: Personal deduction amount by year and number of persons

use 5.010001;
use utf8;
use Moo;
use MooX::HandlesVia;
use Business::RO::TaxDeduction::Types qw(
    Int
    HashRef
    TaxPersons
);
with qw(Business::RO::TaxDeduction::Role::Utils);

has 'persons' => (
    is       => 'ro',
    isa      => TaxPersons,
    required => 1,
    coerce   => 1,
    default  => sub { 0 },
);

has '_deduction_map_2005' => (
    is          => 'ro',
    isa         => HashRef,
    lazy        => 1,
    default     => sub {
        return {
            0 => 250,
            1 => 350,
            2 => 450,
            3 => 550,
            4 => 650,
        };
    },
);

has '_deduction_map_2016' => (
    is          => 'ro',
    isa         => HashRef,
    lazy        => 1,
    default     => sub {
        return {
            0 => 300,
            1 => 400,
            2 => 500,
            3 => 600,
            4 => 800,
        };
    },
);

has '_deduction_map' => (
    is          => 'ro',
    handles_via => 'Hash',
    lazy        => 1,
    default     => sub {
        my $self = shift;
        my $year = $self->base_year;
        my $meth = "_deduction_map_$year";
        return $self->$meth;
    },
    handles => {
        _get_deduction_for => 'get',
    }
);

has amount => (
    is      => 'ro',
    isa     => Int,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->_get_deduction_for( $self->persons );
    },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::RO::TaxDeduction::Amount - Personal deduction amount by year and number of persons

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    my $ded = Business::RO::TaxDeduction::Amount->new(
        persons => 4,
        year    => 2015,
    );
    say $ded->amount;

=head1 DESCRIPTION

Data module.  Personal deduction amount by year and number of persons.

=head1 INTERFACE

=head2 ATTRIBUTES

=head3 persons

Number of persons.  Coerced to 4 if is greater than 4.

=head3 _deduction_map_2005

Uses the amounts described in the document:

"ORDINUL nr. 1.016/2005 din 18 iulie 2005 privind aprobarea deducerilor
personale lunare pentru contribuabilii care realizează venituri din
salarii la funcția de bază, începând cu luna iulie 2005, potrivit
prevederilor Legii nr. 571/2003 privind Codul fiscal și ale Legii
nr. 348/2004 privind denominarea monedei naționale".

=head3 _deduction_map_2016

Uses the amounts described in the document:

"ORDIN Nr. 52/2016 din 14 ianuarie 2016 privind aprobarea
calculatorului pentru determinarea deducerilor personale lunare pentru
contribuabilii care realizează venituri din salarii la funcţia de
bază, începând cu luna ianuarie 2016, potrivit prevederilor art. 77
alin. (2) şi ale art. 66 din Legea nr. 227/2015 privind Codul fiscal".

=head3 _deduction_map

Choses the appropriate deduction map by year and returns the amount
for the number of persons given as parameter.

=head3 amount

Returns the C<amount> using the C<_deduction_map> method.

=head2 INSTANCE METHODS

=head1 AUTHOR

Ștefan Suciu <stefan@s2i2.ro>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Ștefan Suciu.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
