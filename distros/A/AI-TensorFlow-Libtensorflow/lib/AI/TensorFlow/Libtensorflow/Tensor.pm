package AI::TensorFlow::Libtensorflow::Tensor;
# ABSTRACT: A multi-dimensional array of elements of a single data type
$AI::TensorFlow::Libtensorflow::Tensor::VERSION = '0.0.4';
use strict;
use warnings;
use namespace::autoclean;
use AI::TensorFlow::Libtensorflow::Lib qw(arg);
use FFI::Platypus::Closure;
use FFI::Platypus::Buffer qw(window);
use List::Util qw(product);

my $ffi = AI::TensorFlow::Libtensorflow::Lib->ffi;
$ffi->mangler(AI::TensorFlow::Libtensorflow::Lib->mangler_default);

$ffi->load_custom_type('AI::TensorFlow::Libtensorflow::Lib::FFIType::TFPtrSizeScalarRef'
	=> 'tf_tensor_buffer'
);



$ffi->attach( [ 'NewTensor' => 'New' ] =>
	[
		arg 'TF_DataType' => 'dtype',

		# const int64_t* dims, int num_dims
		arg 'tf_dims_buffer'   => [ qw(dims num_dims) ],

		# void* data, size_t len
		arg 'tf_tensor_buffer' => [ qw(data len) ],

		arg 'opaque'      => 'deallocator',  # tensor_deallocator_t (deallocator)
		arg 'opaque'      => 'deallocator_arg',
	],
	=> 'TF_Tensor' => sub {
		my ($xs, $class,
			$dtype, $dims, $data,
			$deallocator, $deallocator_arg,
		) = @_;
		my $deallocator_closure = $ffi->closure( $deallocator );
		$deallocator_closure->sticky;
		my $deallocator_ptr = $ffi->cast(
			'tensor_deallocator_t', 'opaque',
			$deallocator_closure );

		my $obj = $xs->(
			$dtype,
			$dims,
			$data,
			$deallocator_ptr, $deallocator_arg,
		);

		# Return early if no TF_Tensor created
		# TODO should this throw an exception instead?
		return unless $obj;

		$obj->{_deallocator_closure} = $deallocator_closure;

		$obj;
	});


# C: TF_AllocateTensor
#
# Constructor
$ffi->attach( [ 'AllocateTensor', 'Allocate' ],
	[
		arg 'TF_DataType'     => 'dtype',
		arg 'tf_dims_buffer'  => [ qw(dims num_dims) ],
		arg 'size_t'          => 'len',
	],
	=> 'TF_Tensor' => sub {
		my ($xs, $class, @rest) = @_;
		my ($dtype, $dims, $len) = @rest;
		if( ! defined $len ) {
			$len = product($dtype->Size, @$dims);
		}
		my $obj = $xs->($dtype, $dims, $len);
	}
);

$ffi->attach( [ 'DeleteTensor' => 'DESTROY' ],
	[ arg 'TF_Tensor' => 't' ]
	=> 'void'
	=> sub {
		my ($xs, $self) = @_;
		$xs->($self);
		if( exists $self->{_deallocator_closure} ) {
			$self->{_deallocator_closure}->unstick;
		}
	}
);

$ffi->attach( [ 'TensorData' => 'Data' ],
	[ arg 'TF_Tensor' => 'self' ],
	=> 'opaque'
	=> sub {
		my ($xs, @rest) = @_;
		my ($self) = @rest;
		my $data_p = $xs->(@rest);
		window(my $buffer, $data_p, $self->ByteSize);
		\$buffer;
	}
);

$ffi->attach( [ 'TensorByteSize' => 'ByteSize' ],
	[ arg 'TF_Tensor' => 'self' ],
	=> 'size_t'
);

$ffi->attach( [ 'TensorType' => 'Type' ],
	[ arg 'TF_Tensor' => 'self' ],
	=> 'TF_DataType'
);

$ffi->attach( [ 'NumDims' => 'NumDims' ],
	[ arg 'TF_Tensor' => 'self' ],
	=> 'int',
);

$ffi->attach( [ 'TensorElementCount' => 'ElementCount' ] =>
	[ arg 'TF_Tensor' => 'self' ]
	=> 'int64_t'
);

$ffi->attach( [ 'Dim' => 'Dim' ],
	[
		arg 'TF_Tensor' => 't',
		arg 'int'       => 'dim_index',
	],
	=> 'int64_t',
);

$ffi->attach(  [ 'TensorMaybeMove' => 'MaybeMove' ] =>
	[ arg 'TF_Tensor' => 'self' ],
	=> 'TF_Tensor',
);

$ffi->attach( ['TensorIsAligned' => 'IsAligned'] => [
	arg TF_Tensor => 't'
] => 'bool' );

eval {# TF v2.10.0
$ffi->attach(  [ 'SetShape' => 'SetShape' ] =>
	[
		arg 'TF_Tensor' => 'self',
		arg 'tf_dims_buffer'   => [ qw(dims num_dims) ],
	]
	=> 'void'
);
};

$ffi->attach( [  'TensorBitcastFrom' => 'BitcastFrom' ] => [
	arg TF_Tensor => 'from',
	arg TF_DataType => 'type',
	arg TF_Tensor => 'to',
	arg 'tf_dims_buffer'   => [ qw(new_dims num_new_dims) ],
	arg TF_Status => 'status',
] => 'void' );

#### Array helpers ####
use FFI::C::ArrayDef;
use FFI::C::StructDef;
my $adef = FFI::C::ArrayDef->new(
	$ffi,
	name => 'TF_Tensor_array',
	members => [
		FFI::C::StructDef->new(
			$ffi,
			members => [
				p => 'opaque'
			]
		)
	],
);
sub _adef {
	$adef;
}
sub _as_array {
	my $class = shift;
	my $array = $class->_adef->create(0 + @_);
	for my $idx (0..@_-1) {
		next unless defined $_[$idx];
		$array->[$idx]->p($ffi->cast('TF_Tensor', 'opaque', $_[$idx]));
	}
	$array;
}
sub _from_array {
	my ($class, $array) = @_;
	return [
		map {
			$ffi->cast(
				'opaque',
				'TF_Tensor',
				$array->[$_]->p)
		} 0.. $array->count - 1
	]
}

#### Data::Printer ####
sub _data_printer {
	my ($self, $ddp) = @_;

	my @data = (
		[ Type => $ddp->maybe_colorize( $self->Type, 'class' ), ],
		[ Dims =>  sprintf "%s %s %s",
				$ddp->maybe_colorize('[', 'brackets'),
				join(" ",
					map $ddp->maybe_colorize( $self->Dim($_), 'number' ),
						0..$self->NumDims-1),
				$ddp->maybe_colorize(']', 'brackets'),
		],
		[ NumDims => $ddp->maybe_colorize( $self->NumDims, 'number' ), ],
		[ ElementCount => $ddp->maybe_colorize( $self->ElementCount, 'number' ), ],
	);

	my $output;

	$output .= $ddp->maybe_colorize(ref $self, 'class' );
	$output .= ' ' . $ddp->maybe_colorize('{', 'brackets');
	$ddp->indent;
	for my $item (@data) {
		$output .= $ddp->newline;
		$output .= join " ",
			$ddp->maybe_colorize(sprintf("%-15s", $item->[0]), 'hash'),
			$item->[1];
	}
	$ddp->outdent;
	$output .= $ddp->newline;
	$output .= $ddp->maybe_colorize('}', 'brackets');

	return $output;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::Tensor - A multi-dimensional array of elements of a single data type

=head1 SYNOPSIS

  use aliased 'AI::TensorFlow::Libtensorflow::Tensor' => 'Tensor';
  use AI::TensorFlow::Libtensorflow::DataType qw(FLOAT);
  use List::Util qw(product);

  my $dims = [3, 3];

  # Allocate a 3 by 3 ndarray of type FLOAT
  my $t = Tensor->Allocate(FLOAT, $dims);
  is $t->ByteSize, product(FLOAT->Size, @$dims), 'correct size';

  my $scalar_dims = [];
  my $scalar_t = Tensor->Allocate(FLOAT, $scalar_dims);
  is $scalar_t->ElementCount, 1, 'single element';
  is $scalar_t->ByteSize, FLOAT->Size, 'single FLOAT';

=head1 DESCRIPTION

A C<TFTensor> is an object that contains values of a
single type arranged in an n-dimensional array.

For types other than L<STRING|AI::TensorFlow::Libtensorflow::DataType/STRING>,
the data buffer is stored in L<row major order|https://en.wikipedia.org/wiki/Row-_and_column-major_order>.

Of note, this is different from the definition of I<tensor> used in
mathematics and physics which can also be represented as a
multi-dimensional array in some cases, but these tensors are
defined not by the representation but by how they transform. For
more on this see

=over 4

Lim, L.-H. (2021). L<Tensors in computations|https://galton.uchicago.edu/~lekheng/work/acta.pdf>.
Acta Numerica, 30, 555–764. Cambridge University Press.
DOI: L<https://doi.org/10.1017/S0962492921000076>.

=back

=head1 CONSTRUCTORS

=head2 New

=over 2

C<<<
New( $dtype, $dims, $data, $deallocator, $deallocator_arg )
>>>

=back

Creates a C<TFTensor> from a data buffer C<$data> with the given specification
of data type C<$dtype> and dimensions C<$dims>.

  # Create a buffer containing 0 through 8 single-precision
  # floating-point data.
  my $data = pack("f*",  0..8);

  $t = Tensor->New(
    FLOAT, [3,3], \$data, sub { undef $data }, undef
  );

  ok $t, 'Created 3-by-3 float TFTensor';

Implementation note: if C<$dtype> is not a
L<STRING|AI::TensorFlow::Libtensorflow::DataType/STRING>
or
L<RESOURCE|AI::TensorFlow::Libtensorflow::DataType/RESOURCE>,
then the pointer for C<$data> is checked to see if meets the
TensorFlow's alignment preferences. If it does not, the
contents of C<$data> are copied into a new buffer and
C<$deallocator> is called during construction.
Otherwise the contents of C<$data> are not owned by the returned
C<TFTensor>.

B<Parameters>

=over 4

=item L<TFDataType|AI::TensorFlow::Libtensorflow::Lib::Types/TFDataType> $dtype

DataType for the C<TFTensor>.

=item L<Dims|AI::TensorFlow::Libtensorflow::Lib::Types/Dims> $dims

An C<ArrayRef> of the size of each dimension.

=item ScalarRef[Bytes] $data

Data buffer for the contents of the C<TFTensor>.

=item CodeRef $deallocator

A callback used to deallocate C<$data> which is passed the
parameters C<<
  $deallocator->( opaque $pointer, size_t $size, opaque $deallocator_arg)
>>.

=item Ref $deallocator_arg [optional, default: C<undef>]

Argument that is passed to the C<$deallocator> callback.

=back

B<Returns>

=over 4

=item L<TFTensor|AI::TensorFlow::Libtensorflow::Lib::Types/TFTensor>

A new C<TFTensor> with the given data and specification.

=back

B<C API>: L<< C<TF_NewTensor>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_NewTensor >>

=head2 Allocate

=over 2

C<<<
Allocate($dtype, $dims, $len = )
>>>

=back

This constructs a C<TFTensor> with the memory for the C<TFTensor>
allocated and owned by the C<TFTensor> itself. Unlike with L</New>
the allocated memory satisfies TensorFlow's alignment preferences.

See L</Data> for how to write to the data buffer.

  use AI::TensorFlow::Libtensorflow::DataType qw(DOUBLE);

  # Allocate a 2-by-2 ndarray of type DOUBLE
  $dims = [2,2];
  my $t = Tensor->Allocate(DOUBLE, $dims, product(DOUBLE->Size, @$dims));

B<Parameters>

=over 4

=item L<TFDataType|AI::TensorFlow::Libtensorflow::Lib::Types/TFDataType> $dtype

DataType for the C<TFTensor>.

=item L<Dims|AI::TensorFlow::Libtensorflow::Lib::Types/Dims> $dims

An C<ArrayRef> of the size of each dimension.

=item size_t $len [optional]

Number of bytes for the data buffer. If a value is not given,
this is calculated from C<$dtype> and C<$dims>.

=back

B<Returns>

=over 4

=item L<TFTensor|AI::TensorFlow::Libtensorflow::Lib::Types/TFTensor>

A C<TFTensor> with memory allocated for data buffer.

=back

B<C API>: L<< C<TF_AllocateTensor>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_AllocateTensor >>

=head1 ATTRIBUTES

=head2 Data

Provides a way to access the data buffer for the C<TFTensor>. The
C<ScalarRef> that it returns is read-only, but the underlying
pointer can be accessed as long as one is careful when handling the
data (do not write to memory outside the size of the buffer).

  use AI::TensorFlow::Libtensorflow::DataType qw(DOUBLE);
  use FFI::Platypus::Buffer qw(scalar_to_pointer);
  use FFI::Platypus::Memory qw(memcpy);

  my $t = Tensor->Allocate(DOUBLE, [2,2]);

  # [2,2] identity matrix
  my $eye_data = pack 'd*', (1, 0, 0, 1);

  memcpy scalar_to_pointer(${ $t->Data }),
         scalar_to_pointer($eye_data),
         $t->ByteSize;

  ok ${ $t->Data } eq $eye_data, 'contents are the same';

B<Returns>

=over 4

=item ScalarRef[Bytes]

Returns a B<read-only> ScalarRef for the C<TFTensor>'s data
buffer.

=back

B<C API>: L<< C<TF_TensorData>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_TensorData >>

=head2 ByteSize

B<Returns>

=over 4

=item size_t

Returns the number of bytes for the C<TFTensor>'s data buffer.

=back

B<C API>: L<< C<TF_TensorByteSize>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_TensorByteSize >>

=head2 Type

B<Returns>

=over 4

=item L<TFDataType|AI::TensorFlow::Libtensorflow::Lib::Types/TFDataType>

The C<TFTensor>'s data type.

=back

B<C API>: L<< C<TF_TensorType>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_TensorType >>

=head2 NumDims

B<Returns>

=over 4

=item Int

The number of dimensions for the C<TFTensor>.

=back

B<C API>: L<< C<TF_NumDims>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_NumDims >>

=head2 ElementCount

B<Returns>

=over 4

=item int64_t

Number of elements in the C<TFTensor>.

=back

B<C API>: L<< C<TF_TensorElementCount>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_TensorElementCount >>

=head1 METHODS

=head2 Dim

=over 2

C<<<
Dim( $dim_index )
>>>

=back

B<Parameters>

=over 4

=item Int $dim_index

The zero-based index for a given dimension.

=back

B<Returns>

=over 4

=item Int

The extent of the given dimension.

=back

B<C API>: L<< C<TF_Dim>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_Dim >>

=head2 MaybeMove

B<Returns>

=over 4

=item Maybe[TFTensor]

Deletes the C<TFTensor> and returns a new C<TFTensor> with the
same content if possible. Returns C<undef> and leaves the
C<TFTensor> untouched if not.

=back

B<C API>: L<< C<TF_TensorMaybeMove>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_TensorMaybeMove >>

=head2 IsAligned

B<C API>: L<< C<TF_TensorIsAligned>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_TensorIsAligned >>

=head2 SetShape

=over 2

C<<<
SetShape( $dims )
>>>

=back

Set a new shape for the C<TFTensor>.

B<Parameters>

=over 4

=item L<Dims|AI::TensorFlow::Libtensorflow::Lib::Types/Dims> $dims

=back

B<C API>: L<< C<TF_SetShape>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_SetShape >>

C<libtensorflow> version: v2.10.0

=head2 BitcastFrom

B<C API>: L<< C<TF_TensorBitcastFrom>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_TensorBitcastFrom >>

=head1 DESTRUCTORS

=head2 DESTROY

Default destructor.

B<C API>: L<< C<TF_DeleteTensor>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_DeleteTensor >>

=head1 SEE ALSO

=over 4

=item L<PDL>

Provides ndarrays for access from Perl.

=back

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
