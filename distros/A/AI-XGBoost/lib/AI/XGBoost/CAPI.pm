package AI::XGBoost::CAPI;
use strict;
use warnings;

use parent 'NativeCall';

our $VERSION = '0.001';    # VERSION

# ABSTRACT: Perl wrapper for XGBoost C API https://github.com/dmlc/xgboost

sub XGBGetLastError : Args() : Native(xgboost) : Returns(string) { }

sub XGDMatrixCreateFromFile : Args(string, int, opaque*) : Native(xgboost) : Returns(int) { }

sub XGDMatrixNumRow : Args(opaque, uint64*) : Native(xgboost) : Returns(int) { }

sub XGDMatrixNumCol : Args(opaque, uint64*) : Native(xgboost) : Returns(int) { }

sub XGBoosterCreate : Args(opaque[], uint64, opaque*) : Native(xgboost) : Returns(int) { }

sub XGBoosterFree : Args(opaque) : Native(xgboost) : Returns(int) { }

sub XGBoosterUpdateOneIter : Args(opaque, int, opaque) : Native(xgboost) : Returns(int) { }

sub XGBoosterPredict : Args(opaque, opaque, int, uint, uint64*, opaque*) : Native(xgboost) : Returns(int) { }

1;

__END__

=pod

=encoding utf-8

=head1 NAME

AI::XGBoost::CAPI - Perl wrapper for XGBoost C API https://github.com/dmlc/xgboost

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 use 5.010;
 use AI::XGBoost::CAPI;
 use FFI::Platypus;
 
 my $silent = 0;
 my ($dtrain, $dtest) = (0, 0);
 
 AI::XGBoost::CAPI::XGDMatrixCreateFromFile('agaricus.txt.test', $silent, \$dtest);
 AI::XGBoost::CAPI::XGDMatrixCreateFromFile('agaricus.txt.train', $silent, \$dtrain);
 
 my ($rows, $cols) = (0, 0);
 AI::XGBoost::CAPI::XGDMatrixNumRow($dtrain, \$rows);
 AI::XGBoost::CAPI::XGDMatrixNumCol($dtrain, \$cols);
 say "Dimensions: $rows, $cols";
 
 my $booster = 0;
 
 AI::XGBoost::CAPI::XGBoosterCreate( [$dtrain] , 1, \$booster);
 
 for my $iter (0 .. 10) {
     AI::XGBoost::CAPI::XGBoosterUpdateOneIter($booster, $iter, $dtrain);
 }
 
 my $out_len = 0;
 my $out_result = 0;
 
 AI::XGBoost::CAPI::XGBoosterPredict($booster, $dtest, 0, 0, \$out_len, \$out_result);
 my $ffi = FFI::Platypus->new();
 my $predictions = $ffi->cast(opaque => "float[$out_len]", $out_result);
 
 #say join "\n", @$predictions;
 
 AI::XGBoost::CAPI::XGBoosterFree($booster);

=head1 DESCRIPTION

Wrapper for the C API.

The doc for the methods is extracted from doxygen comments: https://github.com/dmlc/xgboost/blob/master/include/xgboost/c_api.h

=head1 FUNCTIONS

=head2 XGBGetLastError

Get string message of the last error

All functions in this file will return 0 when success
and -1 when an error occurred,
XGBGetLastError can be called to retrieve the error

This function is thread safe and can be called by different thread

Returns string error information

=head2 XGDMatrixCreateFromFile

Load a data matrix

Parameters:

=over 4

=item filename

the name of the file

=item silent 

whether print messages during loading

=item out 

a loaded data matrix

=back

=head2 XGDMatrixNumRow

Get number of rows.

Parameters:

=over 4

=item handle 

the handle to the DMatrix

=item out 

The address to hold number of rows.

=back

=head2 XGDMatrixNumCol

Get number of cols.

Parameters:

=over 4

=item handle 

the handle to the DMatrix

=item out 

The address to hold number of cols.

=back

=head2 XGBoosterCreate

Create xgboost learner

Parameters:

=over 4

=item dmats 

matrices that are set to be cached

=item len 

length of dmats

=item out 

handle to the result booster

=back

=head2 XGBoosterFree

Free obj in handle

Parameters:

=over 4

=item handle 

handle to be freed

=back

=head2 XGBoosterUpdateOneIter

Update the model in one round using dtrain

Parameters:

=over 4

=item handle 

handle

=item iter

current iteration rounds

=item dtrain

training data

=back

=head2 XGBoosterPredict

Make prediction based on dmat

Parameters:

=over 4

=item handle 

handle

=item dmat 

data matrix

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

=item out_len 

used to store length of returning result

=item out_result 

used to set a pointer to array

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2017 by Pablo Rodríguez González.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
