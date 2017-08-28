package AI::XGBoost::CAPI::RAW;
use strict;
use warnings;

use Alien::XGBoost;
use FFI::Platypus;

my $ffi = FFI::Platypus->new;
$ffi->lib( Alien::XGBoost->dynamic_libs );

our $VERSION = '0.11';    # VERSION

# ABSTRACT: Perl wrapper for XGBoost C API https://github.com/dmlc/xgboost

$ffi->attach( XGBGetLastError => [] => 'string' );

$ffi->attach( XGDMatrixCreateFromFile => [qw(string int opaque*)] => 'int' );

$ffi->attach( XGDMatrixCreateFromCSREx => [qw(size_t[] uint[] float[] size_t size_t size_t opaque*)] => 'int' );

$ffi->attach( XGDMatrixCreateFromCSCEx => [qw(size_t[] uint[] float[] size_t size_t size_t opaque*)] => 'int' );

$ffi->attach( XGDMatrixCreateFromMat => [qw(float[] uint64 uint64 float opaque*)] => 'int' );

$ffi->attach( XGDMatrixCreateFromMat_omp => [qw(float[] uint64 uint64 float opaque* int)] => 'int' );

$ffi->attach( XGDMatrixSliceDMatrix => [qw(opaque int[] uint64 opaque*)] => 'int' );

$ffi->attach( XGDMatrixNumRow => [qw(opaque uint64*)] => 'int' );

$ffi->attach( XGDMatrixNumCol => [qw(opaque uint64*)] => 'int' );

$ffi->attach( XGDMatrixSaveBinary => [qw(opaque string int)] => 'int' );

$ffi->attach( XGDMatrixSetFloatInfo => [qw(opaque string float[] uint64)] => 'int' );

$ffi->attach( XGDMatrixSetUIntInfo => [qw(opaque string uint32* uint64)] => 'int' );

$ffi->attach( XGDMatrixSetGroup => [qw(opaque uint32* uint64)] => 'int' );

$ffi->attach( XGDMatrixGetFloatInfo => [qw(opaque string uint64* opaque*)] => 'int' );

$ffi->attach( XGDMatrixGetUIntInfo => [qw(opaque string uint64* opaque*)] => 'int' );

$ffi->attach( XGDMatrixFree => [qw(opaque)] => 'int' );

$ffi->attach( XGBoosterCreate => [qw(opaque[] uint64 opaque*)] => 'int' );

$ffi->attach( XGBoosterFree => [qw(opaque)] => 'int' );

$ffi->attach( XGBoosterSetParam => [qw(opaque string string)] => 'int' );

$ffi->attach( XGBoosterBoostOneIter => [qw(opaque opaque float[] float[] uint64)] => 'int' );

$ffi->attach( XGBoosterUpdateOneIter => [qw(opaque int opaque)] => 'int' );

$ffi->attach( XGBoosterEvalOneIter => [qw(opaque int opaque[] opaque[] uint64 opaque*)] => 'int' );

$ffi->attach( XGBoosterPredict => [qw(opaque opaque int uint uint64* opaque*)] => 'int' );

$ffi->attach( XGBoosterLoadModel => [qw(opaque string)] => 'int' );

$ffi->attach( XGBoosterSaveModel => [qw(opaque string)] => 'int' );

$ffi->attach( XGBoosterLoadModelFromBuffer => [qw(opaque opaque uint64)] => 'int' );

$ffi->attach( XGBoosterGetModelRaw => [qw(opaque uint64* opaque*)] => 'int' );

$ffi->attach( XGBoosterDumpModel => [qw(opaque string int uint64* opaque*)] => 'int' );

$ffi->attach( XGBoosterDumpModelEx => [qw(opaque string int string uint64* opaque*)] => 'int' );

$ffi->attach( XGBoosterDumpModelWithFeatures => [qw(opaque int opaque[] opaque[] int uint64* opaque*)] => 'int' );

$ffi->attach(
           XGBoosterDumpModelExWithFeatures => [qw(opaque int opaque[] opaque[] int string uint64* opaque*)] => 'int' );

$ffi->attach( XGBoosterSetAttr => [qw(opaque string string)] => 'int' );

$ffi->attach( XGBoosterGetAttr => [qw(opaque string opaque* int*)] => 'int' );

$ffi->attach( XGBoosterGetAttrNames => [qw(opaque uint64* opaque*)] => 'int' );

$ffi->attach( XGBoosterLoadRabitCheckpoint => [qw(opaque int)] => 'int' );

$ffi->attach( XGBoosterSaveRabitCheckpoint => [qw(opaque)] => 'int' );

1;

__END__

=pod

=encoding utf-8

=head1 NAME

AI::XGBoost::CAPI::RAW - Perl wrapper for XGBoost C API https://github.com/dmlc/xgboost

=head1 VERSION

version 0.11

=head1 SYNOPSIS

 use 5.010;
 use AI::XGBoost::CAPI::RAW;
 use FFI::Platypus;
 
 my $silent = 0;
 my ($dtrain, $dtest) = (0, 0);
 
 AI::XGBoost::CAPI::RAW::XGDMatrixCreateFromFile('agaricus.txt.test', $silent, \$dtest);
 AI::XGBoost::CAPI::RAW::XGDMatrixCreateFromFile('agaricus.txt.train', $silent, \$dtrain);
 
 my ($rows, $cols) = (0, 0);
 AI::XGBoost::CAPI::RAW::XGDMatrixNumRow($dtrain, \$rows);
 AI::XGBoost::CAPI::RAW::XGDMatrixNumCol($dtrain, \$cols);
 say "Dimensions: $rows, $cols";
 
 my $booster = 0;
 
 AI::XGBoost::CAPI::RAW::XGBoosterCreate( [$dtrain] , 1, \$booster);
 
 for my $iter (0 .. 10) {
     AI::XGBoost::CAPI::RAW::XGBoosterUpdateOneIter($booster, $iter, $dtrain);
 }
 
 my $out_len = 0;
 my $out_result = 0;
 
 AI::XGBoost::CAPI::RAW::XGBoosterPredict($booster, $dtest, 0, 0, \$out_len, \$out_result);
 my $ffi = FFI::Platypus->new();
 my $predictions = $ffi->cast(opaque => "float[$out_len]", $out_result);
 
 #say join "\n", @$predictions;
 
 AI::XGBoost::CAPI::RAW::XGBoosterFree($booster);
 AI::XGBoost::CAPI::RAW::XGDMatrixFree($dtrain);
 AI::XGBoost::CAPI::RAW::XGDMatrixFree($dtest);

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

=head2 XGDMatrixCreateFromCSREx

Create a matrix content from CSR fromat

Parameters:

=over 4

=item indptr

pointer to row headers

=item indices

findex

=item data

fvalue

=item nindptr

number of rows in the matrix + 1

=item nelem

number of nonzero elements in the matrix

=item num_col

number of columns; when it's set to 0, then guess from data

=item out

created dmatrix

=back

=head2 XGDMatrixCreateFromCSCEx

Create a matrix content from CSC format

Parameters:

=over 4

=item col_ptr

pointer to col headers

=item indices

findex

=item data

fvalue

=item nindptr

number of rows in the matrix + 1

=item nelem

number of nonzero elements in the matrix

=item num_row

number of rows; when it's set to 0, then guess from data

=back

=head2 XGDMatrixCreateFromMat

Create matrix content from dense matrix

Parameters:

=over 4

=item data 

pointer to the data space

=item nrow

number of rows

=item ncol

number columns

=item missing

which value to represent missing value

=item out

created dmatrix

=back

=head2 XGDMatrixCreateFromMat_omp

Create matrix content from dense matrix

Parameters:

=over 4

=item data 

pointer to the data space

=item nrow

number of rows

=item ncol

number columns

=item missing

which value to represent missing value

=item out

created dmatrix

=item nthread

number of threads (up to maximum cores available, if <=0 use all cores)

=back

=head2 XGDMatrixSliceDMatrix

Create a new dmatrix from sliced content of existing matrix

Parameters:

=over 4

=item handle

instance of data matrix to be sliced

=item idxset

index set

=item len

length of index set

=item out

a sliced new matrix

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

=head2 XGDMatrixSaveBinary

load a data matrix into binary file

Parameters:

=over 4

=item handle

a instance of data matrix

=item fname

file name

=item silent

print statistics when saving

=back

=head2 XGDMatrixSetFloatInfo

Set float vector to a content in info

Parameters:

=over 4

=item handle

a instance of data matrix

=item field

field name, can be label, weight

=item array

pointer to float vector

=item len

length of array

=back

=head2 XGDMatrixSetUIntInfo

Set uint32 vector to a content in info

Parameters:

=over 4

=item handle

a instance of data matrix

=item field

field name, can be label, weight

=item array

pointer to unsigned int vector

=item len

length of array

=back

=head2 XGDMatrixSetGroup

Set label of the training matrix

Parameters:

=over 4

=item handle

a instance of data matrix

=item group

pointer to group size

=item len

length of the array

=back

=head2 XGDMatrixGetFloatInfo

Get float info vector from matrix

Parameters:

=over 4

=item handle

a instance of data matrix

=item field

field name

=item out_len

used to set result length

=item out_dptr

pointer to the result

=back

=head2 XGDMatrixGetUIntInfo

Get uint32 info vector from matrix

Parameters:

=over 4

=item handle

a instance of data matrix

=item field

field name

=item out_len

The length of the field

=item out_dptr

pointer to the result

=back

=head2 XGDMatrixFree

Free space in data matrix

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

=head2 XGBoosterSetParam

Update the model in one round using dtrain

Parameters:

=over 4

=item handle

handle

=item name

parameter name

=item value

value of parameter

=back

=head2 XGBoosterBoostOneIter

Update the modelo, by directly specify grandient and second order gradient,
this can be used to replace UpdateOneIter, to support customized loss function

Parameters:

=over 4

=item handle

handle

=item dtrain

training data

=item grad

gradient statistics

=item hess

second order gradinet statistics

=item len

length of grad/hess array

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

=head2 XGBoosterEvalOneIter

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

=head2 XGBoosterLoadModel

Load model form existing file

Parameters:

=over 4

=item handle

handle

=item fname

file name

=back

=head2 XGBoosterSaveModel

Save model into existing file

Parameters:

=over 4

=item handle

handle

=item fname

file name

=back

=head2 XGBoosterLoadModelFromBuffer

=head2 XGBoosterGetModelRaw

=head2 XGBoosterDumpModel

=head2 XGBoosterDumpModelEx

=head2 XGBoosterDumpModelWithFeatures

=head2 XGBoosterDumpModelExWithFeatures

=head2 XGBoosterSetAttr

=head2 XGBoosterGetAttr

=head2 XGBoosterGetAttrNames

=head2 XGBoosterLoadRabitCheckpoint

=head2 XGBoosterSaveRabitCheckpoint

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2017 by Pablo Rodríguez González.

=cut
