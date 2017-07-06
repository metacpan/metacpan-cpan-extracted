package AI::XGBoost::DMatrix;

use strict;
use warnings;
use utf8;

use Moose;
use AI::XGBoost::CAPI qw(:all);

has handler => ( is => 'ro' );

sub FromFile {
    my ( $package, %args ) = @_;
    my $matrix = XGDMatrixCreateFromFile( @args{qw(filename silent)} );
    return __PACKAGE__->new( handler => $matrix );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

AI::XGBoost::DMatrix

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    use aliased 'AI::XGBoost::DMatrix';
    my $train_data = DMatrix->FromFile(filename => 'agaricus.txt.train');

=head1 DESCRIPTION

XGBoost DMatrix perl model

Work In Progress, the API may change. Comments and suggestions are welcome!

=head1 METHODS

=head2 FromFile

Construct a DMatrix from a file

=head3 Parameters

=over 4

=item filename

File to read

=item silent

Supress messages

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Pablo Rodríguez González.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
