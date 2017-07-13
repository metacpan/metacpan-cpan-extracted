package AI::XGBoost::DMatrix;

use strict;
use warnings;
use utf8;

our $VERSION = '0.006';    # VERSION

# ABSTRACT: XGBoost class for data

use Moose;
use AI::XGBoost::CAPI qw(:all);
use Carp;

has handle => ( is => 'ro', );

sub From {
    my ( $package, %args ) = @_;
    return __PACKAGE__->FromFile( filename => $args{file}, silent => $args{silent} ) if ( defined $args{file} );
    return __PACKAGE__->FromMat( map { $_ => $args{$_} if defined $_ } qw(matrix missing label) )
      if ( defined $args{matrix} );
    Carp::cluck( "I don't know how to build a " . __PACKAGE__ . " with this data: " . join( ", ", %args ) );
}

sub FromFile {
    my ( $package, %args ) = @_;
    my $handle = XGDMatrixCreateFromFile( @args{qw(filename silent)} );
    return __PACKAGE__->new( handle => $handle );
}

sub FromMat {
    my ( $package, %args ) = @_;
    my $handle = XGDMatrixCreateFromMat( @args{qw(matrix missing)} );
    my $matrix = __PACKAGE__->new( handle => $handle );
    if ( defined $args{label} ) {
        $matrix->set_label( $args{label} );
    }
    return $matrix;
}

sub set_float_info {
    my $self = shift();
    my ( $field, $info ) = @_;
    XGDMatrixSetFloatInfo( $self->handle, $field, $info );
    return $self;
}

sub get_float_info {
    my $self  = shift();
    my $field = shift();
    XGDMatrixGetFloatInfo( $self->handle, $field );
}

sub set_label {
    my $self  = shift();
    my $label = shift();
    $self->set_float_info( 'label', $label );
}

sub get_label {
    my $self = shift();
    $self->get_float_info('label');
}

sub set_weight {
    my $self   = shift();
    my $weight = shift();
    $self->set_float_info( 'weight', $weight );
    return $self;
}

sub get_weight {
    my $self = shift();
    $self->get_float_info('weight');
}

sub num_row {
    my $self = shift();
    XGDMatrixNumRow( $self->handle );
}

sub num_col {
    my $self = shift();
    XGDMatrixNumCol( $self->handle );
}

sub dims {
    my $self = shift();
    return ( $self->rows(), $self->cols() );
}

sub DEMOLISH {
    my $self = shift();
    XGDMatrixFree( $self->handle );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

AI::XGBoost::DMatrix - XGBoost class for data

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    use aliased 'AI::XGBoost::DMatrix';
    my $train_data = DMatrix->FromFile(filename => 'agaricus.txt.train');

=head1 DESCRIPTION

XGBoost DMatrix perl model

Work In Progress, the API may change. Comments and suggestions are welcome!

=head1 METHODS

=head2 From

Construct a DMatrix from diferent sources. Based on parameters
dispatch to the correct From* method

Refer to From* to see what can be done.

=head2 FromFile

Construct a DMatrix from a file

=head3 Parameters

=over 4

=item filename

File to read

=item silent

Supress messages

=back

=head2 FromMat

Construct a DMatrix from a bidimensional array

=head3 Parameters

=over 4

=item matrix

Bidimensional array

=item label

Array with the labels of the rows of matrix. Optional

=item missing

Value to identify missing values. Optional, default `NaN`

=back

=head2 set_float_info

Set float type property

=head3 Parameters

=over 4

=item field

Field name of the information

=item info

array with the information

=back

=head2 get_float_info

Get float type property

=head3 Parameters

=over 4

=item field

Field name of the information

=back

=head2 set_label

Set label of DMatrix. This label is the "classes" in classification problems

=head3 Parameters

=over 4

=item data

Array with the labels

=back

=head2 get_label

Get label of DMatrix. This label is the "classes" in classification problems

=head2 set_weight

Set weight of each instance

=head3 Parameters

=over 4

=item weight

Array with the weights

=back

=head2 get_weight

Get the weight of each instance

=head2 num_row

Number of rows

=head2 num_col

Number of columns

=head2 dims

Dimensions of the matrix. That is: rows, columns

=head2 DEMOLISH

Free the

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Pablo Rodríguez González.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
