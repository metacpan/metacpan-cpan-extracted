package Business::RO::TaxDeduction::Ranges;
$Business::RO::TaxDeduction::Ranges::VERSION = '0.010';
# ABSTRACT: Deduction ranges by year

use 5.010001;
use utf8;
use Moo;
use Business::RO::TaxDeduction::Types qw(
    Int
);
with qw(Business::RO::TaxDeduction::Role::Utils);

has 'vbl_min' => (
    is      => 'ro',
    isa     => Int,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return 1000 if $self->base_year == 2005;
        return 1500 if $self->base_year == 2016;
        die "Not a valid year: " . $self->base_year;
    },
);

has 'vbl_max' => (
    is      => 'ro',
    isa     => Int,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return 3000 if $self->base_year == 2005;
        return 3000 if $self->base_year == 2016;
        die "Not a valid year: " . $self->base_year;
    },
);

has 'f_min' => (
    is      => 'ro',
    isa     => Int,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return 1000 if $self->base_year == 2005;
        return 1500 if $self->base_year == 2016;
        die "Not a valid year: " . $self->base_year;
    },
);

has 'f_max' => (
    is       => 'ro',
    isa      => Int,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return 2000 if $self->base_year == 2005;
        return 1500 if $self->base_year == 2016;
        die "Not a valid year: " . $self->base_year;
    },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::RO::TaxDeduction::Ranges - Deduction ranges by year

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    use Business::RO::TaxDeduction::Ranges;

    my $tdr = Business::RO::TaxDeduction::Ranges->new(
        year => $year,
    );
    my $vbl_min = $tdr->vbl_min;
    my $vbl_max = $tdr->vbl_max;
    my $f_min   = $tdr->f_min;
    my $f_max   = $tdr->f_max;

=head1 DESCRIPTION

Data module.  This module holds data used in the tax deduction
formula.

=head1 INTERFACE

=head2 ATTRIBUTES

=head3 vbl_min

The minimum amount (VBL) used in the tax deduction formula.

=head3 vbl_max

The maximum amount (VBL) used in the tax deduction formula.

=head3 f_min

The amount used in the tax deduction formula:

    250 x [ 1 - ( VBL - $f_min=1000 ) / 2000 ]  # 2005
    300 x [ 1 - ( VBL - $f_min=1500 ) / 1500 ]  # 2016

=head3 f_max

The amount used in the tax deduction formula:

    250 x [ 1 - ( VBL - 1000 ) / $f_max=2000 ]  # 2005
    300 x [ 1 - ( VBL - 1500 ) / $f_max=1500 ]  # 2016

=head2 INSTANCE METHODS

=head1 AUTHOR

Ștefan Suciu <stefan@s2i2.ro>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Ștefan Suciu.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
