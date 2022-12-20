package AI::TensorFlow::Libtensorflow::DataType;
# ABSTRACT: Datatype enum
$AI::TensorFlow::Libtensorflow::DataType::VERSION = '0.0.3';
use strict;
use warnings;
use AI::TensorFlow::Libtensorflow::Lib;
use Const::Exporter;

use Devel::StrictMode;
use Types::Common qw(Int Str);

use namespace::autoclean;

# enum TF_DataType
# From <tensorflow/c/tf_datatype.h>
my %_ENUM_DTYPE = (
	FLOAT      =>  1,
	DOUBLE     =>  2,
	INT32      =>  3, #// Int32 tensors are always in 'host' memory.
	UINT8      =>  4,
	INT16      =>  5,
	INT8       =>  6,
	STRING     =>  7,
	COMPLEX64  =>  8, #// Single-precision complex
	# NOTE Stubbing out this duplicate so that no new code uses this.
	#COMPLEX    =>  8, #// Old identifier kept for API backwards compatibility
	INT64      =>  9,
	BOOL       => 10,
	QINT8      => 11, #// Quantized int8
	QUINT8     => 12, #// Quantized uint8
	QINT32     => 13, #// Quantized int32
	BFLOAT16   => 14, #// Float32 truncated to 16 bits.  Only for cast ops.
	QINT16     => 15, #// Quantized int16
	QUINT16    => 16, #// Quantized uint16
	UINT16     => 17,
	COMPLEX128 => 18, #// Double-precision complex
	HALF       => 19,
	RESOURCE   => 20,
	VARIANT    => 21,
	UINT32     => 22,
	UINT64     => 23,
);
my %_REV_ENUM_DTYPE = reverse %_ENUM_DTYPE;
if( STRICT ) { # ASSERT
	die "Duplicate values for \%_ENUM_DTYPE" unless keys %_ENUM_DTYPE == keys %_REV_ENUM_DTYPE
}

my %_DTYPES;
Const::Exporter->import(
	dtypes => [
		do {
			%_DTYPES = map {
				$_ => bless \do {
					my $value = $_ENUM_DTYPE{$_};
				}, __PACKAGE__;
			} keys %_ENUM_DTYPE;
		},
		'@DTYPES' => [ sort { $$a <=> $$b } values %_DTYPES ],
	]
);
use namespace::autoclean;

my $ffi = AI::TensorFlow::Libtensorflow::Lib->ffi;
$ffi->mangler(AI::TensorFlow::Libtensorflow::Lib->mangler_for_object('DataType'));

$ffi->type('object(AI::TensorFlow::Libtensorflow::DataType,int)', 'TF_DataType');

$ffi->attach( 'Size' => ['TF_DataType'] => 'size_t' );


use overload
	'==' => '_op_num_equals',
	'eq'  => '_op_eq',
	'""'  => '_op_stringify';

sub _op_num_equals {
	my ($a, $b, $swap) = @_;
	my $int_a = ref $a ? 0+$$a : 0+$a;
	my $int_b = ref $b ? 0+$$b : 0+$b;
	if( STRICT ) { # ASSERT
		Int->assert_valid($int_a);
		Int->assert_valid($int_b);
	}
	!$swap
		? $int_a == $int_b
		: $int_b == $int_b
}

sub _op_eq {
	my ($a, $b, $swap) = @_;
	my $str_a = "$a";
	my $str_b = "$b";
	if( STRICT ) { # ASSERT
		Str->assert_valid($str_a);
		Str->assert_valid($str_b);
	}
	!$swap
		?  $str_a eq $str_b
		:  $str_b eq $str_a;
}

sub _op_stringify { $_REV_ENUM_DTYPE{ 0 + ${$_[0]}} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::DataType - Datatype enum

=head1 SYNOPSIS

  use AI::TensorFlow::Libtensorflow::DataType qw(FLOAT @DTYPES);
  use List::Util qw(max);

  my $dtype = FLOAT;
  is FLOAT->Size, 4, 'FLOAT is 4 bytes large';
  is max(map { $_->Size } @DTYPES), 16,
    'Largest type has sizeof() == 16 bytes';

=head1 DESCRIPTION

Enum representing native data types used inside of containers such as
L<TFTensor|AI::TensorFlow::Libtensorflow::Lib::Types/TFTensor>.

=head1 CONSTANTS

=head2 STRING

String.

=head2 BOOL

Boolean.

=head2 HALF

16-bit half-precision floating-point (C<float16>).

=head2 FLOAT

32-bit single-precision floating-point (C<float32>).

=head2 DOUBLE

64-bit double-precision floating-point (C<float64>).

=head2 BFLOAT16

16-bit truncated floating-point.

=head2 COMPLEX64

32-bit single-precision complex floating-point.

=head2 COMPLEX128

64-bit double-precision complex floating-point.

=head2 INT8

8-bit signed integer.

=head2 INT16

16-bit signed integer.

=head2 INT32

32-bit signed integer.

=head2 INT64

64-bit signed integer.

=head2 UINT8

8-bit unsigned integer.

=head2 UINT16

16-bit unsigned integer.

=head2 UINT32

32-bit unsigned integer.

=head2 UINT64

64-bit unsigned integer.

=head2 QINT8

8-bit quantized signed integer.

=head2 QINT16

16-bit quantized signed integer.

=head2 QINT32

32-bit quantized signed integer.

=head2 QUINT8

8-bit quantized unsigned integer.

=head2 QUINT16

16-bit quantized unsigned integer.

=head2 RESOURCE

Handle to a mutable resource.

=head2 VARIANT

Variant.

=head1 METHODS

=head2 Size

  my $size = $dtype->Size();

B<Returns>

=over 4

=item size_t

The number of bytes used for the DataType C<$dtype>. Returns C<0> for variable
length types such as C<STRING> or for invalid types.

=back

B<C API>: L<< C<TF_DataTypeSize>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_DataTypeSize >>

=head1 OPERATORS

=head2 C<< == >>

Numeric equality of the underlying enum integer value.

  use AI::TensorFlow::Libtensorflow::DataType qw(FLOAT);
  cmp_ok FLOAT, '==', FLOAT, 'Compare FLOAT objects numerically';
  cmp_ok FLOAT, '==', 1    , 'FLOAT enumeration is internally 1';

=head2 C<< eq >>

Compare string equality against type name.

  use AI::TensorFlow::Libtensorflow::DataType qw(FLOAT);
  cmp_ok FLOAT, 'eq', 'FLOAT', 'Compare FLOAT object to string';

=head2 C<< "" >>

Stringification to the name of the enumerated type name (e.g., FLOAT, DOUBLE).

  use AI::TensorFlow::Libtensorflow::DataType qw(DOUBLE);
  is "@{[ DOUBLE ]}", 'DOUBLE', 'Stringifies';

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
