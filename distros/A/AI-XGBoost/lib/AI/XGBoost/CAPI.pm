package AI::XGBoost::CAPI;
use strict;
use warnings;

use Exporter::Easy (
    TAGS => [
        all => [
            qw(
              XGDMatrixCreateFromFile
              XGDMatrixNumRow
              XGDMatrixNumCol
              XGDMatrixFree
              XGBoosterCreate
              XGBoosterUpdateOneIter
              XGBoosterPredict
              XGBoosterFree
              )
        ]
    ]
);
use AI::XGBoost::CAPI::RAW;
use FFI::Platypus;
use Exception::Class ( 'XGBoostException' );

our $VERSION = '0.004';    # VERSION

# ABSTRACT: Perl wrapper for XGBoost C API https://github.com/dmlc/xgboost

sub XGDMatrixCreateFromFile {
    my ( $filename, $silent ) = @_;
    $silent //= 1;
    my $matrix = 0;
    my $error = AI::XGBoost::CAPI::RAW::XGDMatrixCreateFromFile( $filename, $silent, \$matrix );
    _CheckCall($error);
    return $matrix;
}

sub XGDMatrixNumRow {
    my ($matrix) = @_;
    my $rows = 0;
    _CheckCall( AI::XGBoost::CAPI::RAW::XGDMatrixNumRow( $matrix, \$rows ) );
    return $rows;
}

sub XGDMatrixNumCol {
    my ($matrix) = @_;
    my $cols = 0;
    _CheckCall( AI::XGBoost::CAPI::RAW::XGDMatrixNumCol( $matrix, \$cols ) );
    return $cols;
}

sub XGDMatrixFree {
    my ($matrix) = @_;
    _CheckCall( AI::XGBoost::CAPI::RAW::XGDMatrixFree($matrix) );
    return ();
}

sub XGBoosterCreate {
    my ($matrices) = @_;
    my $booster = 0;
    _CheckCall( AI::XGBoost::CAPI::RAW::XGBoosterCreate( $matrices, scalar @$matrices, \$booster ) );
    return $booster;
}

sub XGBoosterUpdateOneIter {
    my ( $booster, $iter, $train_matrix ) = @_;
    _CheckCall( AI::XGBoost::CAPI::RAW::XGBoosterUpdateOneIter( $booster, $iter, $train_matrix ) );
    return ();
}

sub XGBoosterPredict {
    my ( $booster, $data_matrix, $option_mask, $ntree_limit ) = @_;
    my $out_len    = 0;
    my $out_result = 0;
    _CheckCall(
                AI::XGBoost::CAPI::RAW::XGBoosterPredict( $booster,     $data_matrix, $option_mask,
                                                          $ntree_limit, \$out_len,    \$out_result
                )
    );
    my $ffi = FFI::Platypus->new();
    return $ffi->cast( opaque => "float[$out_len]", $out_result );
}

sub XGBoosterFree {
    my ($booster) = @_;
    _CheckCall( AI::XGBoost::CAPI::RAW::XGBoosterFree($booster) );
    return ();
}

# _CheckCall
#
#  Check return code and if necesary, launch an exception
#
sub _CheckCall {
    my ($return_code) = @_;
    if ($return_code) {
        my $error_message = AI::XGBoost::CAPI::RAW::XGBGetLastError();
        XGBoostException->throw( error => $error_message );
    }
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

AI::XGBoost::CAPI - Perl wrapper for XGBoost C API https://github.com/dmlc/xgboost

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 use 5.010;
 use AI::XGBoost::CAPI qw(:all);
 
 my $dtrain = XGDMatrixCreateFromFile('agaricus.txt.train');
 my $dtest = XGDMatrixCreateFromFile('agaricus.txt.test');
 
 my ($rows, $cols) = (XGDMatrixNumRow($dtrain), XGDMatrixNumCol($dtrain));
 say "Train dimensions: $rows, $cols";
 
 my $booster = XGBoosterCreate([$dtrain]);
 
 for my $iter (0 .. 10) {
     XGBoosterUpdateOneIter($booster, $iter, $dtrain);
 }
 
 my $predictions = XGBoosterPredict($booster, $dtest, 0, 0);
 # say join "\n", @$predictions;
 
 XGBoosterFree($booster);
 XGDMatrixFree($dtrain);
 XGDMatrixFree($dtest);

=head1 DESCRIPTION

Perlified wrapper for the C API

=head2 Error handling

XGBoost c api functions returns some int to signal the presence/absence of error.
In this module that is achieved using Exceptions from L<Exception::Class>

=head1 FUNCTIONS

=head2 XGDMatrixCreateFromFile

Load a data matrix

Parameters:

=over 4

=item filename

the name of the file

=item silent 

whether print messages during loading

=back

Returns a loaded data matrix

=head2 XGDMatrixNumRow

Get number of rows

Parameters:

=over 4

=item matrix

DMatrix

=back

=head2 XGDMatrixNumCol

Get number of cols

Parameters:

=over 4

=item matrix

DMatrix

=back

=head2 XGDMatrixFree

Free space in data matrix

Parameters:

=over 4

=item matrix

DMatrix to be freed

=back

=head2 XGBoosterCreate

Create XGBoost learner

Parameters:

=over 4

=item matrices

matrices that are set to be cached

=back

=head2 XGBoosterUpdateOneIter

Update the model in one round using train matrix

Parameters:

=over 4

=item booster

XGBoost learner to train

=item iter

current iteration rounds

=item train_matrix

training data

=back

=head2 XGBoosterPredict

Make prediction based on train matrix

Parameters:

=over 4

=item booster

XGBoost learner 

=item data_matrix

Data matrix with the elements to predict

=item option_mask

bit-mask of options taken in prediction, possible values

=over 4

=item

0: normal prediction

=item

1: output margin instead of transformed value

=item

2: output leaf index of trees instead of leaf value, note leaf index is unique per tree

=item

4: output feature contributions to individual predictions

=back

=item ntree_limit

limit number of trees used for prediction, this is only valid for boosted trees
when the parameter is set to 0, we will use all the trees

=back

Returns an arrayref with the predictions corresponding to the rows of data matrix

=head2 XGBoosterFree

Free booster object

Parameters:

=over 4

=item booster

booster to be freed

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Pablo Rodríguez González.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
