package AI::TensorFlow::Libtensorflow::Lib;
# ABSTRACT: Private class for AI::TensorFlow::Libtensorflow
$AI::TensorFlow::Libtensorflow::Lib::VERSION = '0.0.3';
use strict;
use warnings;

use feature qw(state);
use FFI::CheckLib 0.28 qw( find_lib_or_die );
use Alien::Libtensorflow;
use FFI::Platypus;
use AI::TensorFlow::Libtensorflow::Lib::FFIType::Variant::PackableArrayRef;
use AI::TensorFlow::Libtensorflow::Lib::FFIType::Variant::PackableMaybeArrayRef;
use AI::TensorFlow::Libtensorflow::Lib::FFIType::TFPtrSizeScalar;

use base 'Exporter::Tiny';
our @EXPORT_OK = qw(arg);

sub lib {
	$ENV{AI_TENSORFLOW_LIBTENSORFLOW_LIB_DLL}
	// find_lib_or_die(
		lib => 'tensorflow',
		symbol => ['TF_Version'],
		alien => ['Alien::Libtensorflow'] );
}

sub ffi {
	state $ffi;
	$ffi ||= do {
		my $ffi = FFI::Platypus->new( api => 2 );
		$ffi->lib( __PACKAGE__->lib );

		$ffi->load_custom_type('::PointerSizeBuffer' => 'tf_config_proto_buffer');
		$ffi->load_custom_type('::PointerSizeBuffer' => 'tf_tensor_shape_proto_buffer');
		$ffi->load_custom_type('::PointerSizeBuffer' => 'tf_attr_value_proto_buffer');

		$ffi->load_custom_type('AI::TensorFlow::Libtensorflow::Lib::FFIType::TFPtrSizeScalar'
			=> 'tf_text_buffer');

		$ffi->load_custom_type( PackableMaybeArrayRef( 'DimsBuffer', pack_type => 'q' )
			=> 'tf_dims_buffer'
		);


		$ffi->type('object(AI::TensorFlow::Libtensorflow::SessionOptions)' => 'TF_SessionOptions');

		$ffi->type('object(AI::TensorFlow::Libtensorflow::Graph)' => 'TF_Graph');

		$ffi->type('object(AI::TensorFlow::Libtensorflow::OperationDescription)'
			=> 'TF_OperationDescription');

		$ffi->load_custom_type('::PtrObject', 'TF_Operation' => 'AI::TensorFlow::Libtensorflow::Operation');

		$ffi->type('opaque' => 'TF_Function');

		$ffi->type('opaque' => 'TF_FunctionOptions');

		$ffi->type('object(AI::TensorFlow::Libtensorflow::ImportGraphDefOptions)' => 'TF_ImportGraphDefOptions');

		$ffi->type('object(AI::TensorFlow::Libtensorflow::ImportGraphDefResults)' => 'TF_ImportGraphDefResults');

		$ffi->type('object(AI::TensorFlow::Libtensorflow::Session)' => 'TF_Session');

		$ffi->type('opaque' => 'TF_DeprecatedSession');

		$ffi->type('object(AI::TensorFlow::Libtensorflow::DeviceList)' => 'TF_DeviceList');

		$ffi->type('opaque' => 'TF_Library');

		$ffi->type('object(AI::TensorFlow::Libtensorflow::ApiDefMap)' => 'TF_ApiDefMap');

		$ffi->type('opaque' => 'TF_Server');



		$ffi->type('opaque' => 'TF_CheckpointReader');

		$ffi->type('opaque' => 'TF_AttrBuilder');

		$ffi->type('opaque' => 'TF_ShapeAndType');

		$ffi->type('opaque' => 'TF_ShapeAndTypeList');



		$ffi->type('opaque' => 'TF_WritableFileHandle');

		$ffi->type('opaque' => 'TF_StringStream');

		$ffi->type('opaque' => 'TF_Thread');


		$ffi->type('opaque' => 'TF_KernelBuilder');

		$ffi->type('opaque' => 'TF_OpKernelConstruction');

		$ffi->type('opaque' => 'TF_OpKernelContext');


		$ffi->type('opaque' => 'TF_VariableInputLockHolder');

		$ffi->type('opaque' => 'TF_CoordinationServiceAgent');


		$ffi->type('opaque' => 'TF_Shape');


		$ffi->type('object(AI::TensorFlow::Libtensorflow::Status)' => 'TF_Status');


		$ffi->load_custom_type('::PtrObject', 'TF_Tensor' => 'AI::TensorFlow::Libtensorflow::Tensor');


		$ffi->load_custom_type('::PtrObject', 'TF_TString' => 'AI::TensorFlow::Libtensorflow::TString');



		## Callbacks for deallocation
		# For TF_Buffer
		$ffi->type('(opaque,size_t)->void'        => 'data_deallocator_t');
		# For TF_Tensor
		$ffi->type('(opaque,size_t,opaque)->void' => 'tensor_deallocator_t');

		$ffi;
	};
}

sub mangler_default {
	sub {
		my ($name) = @_;
		"TF_$name";
	}
}

sub mangler_for_object {
	my ($class, $object_name) = @_;
	sub {
		my ($name) = @_;

		# constructor and destructors
		return "TF_New${object_name}" if $name eq 'New';
		return "TF_Delete${object_name}" if $name eq 'Delete';

		return "TF_${object_name}$name";
	};
}

sub arg(@) {
	my $arg = AI::TensorFlow::Libtensorflow::Lib::_Arg->new(
		type => shift,
		id => shift,
	);
	return $arg, @_;
}

# from FFI::Platypus::Type::StringArray
use constant _pointer_incantation =>
  $^O eq 'MSWin32' && do { require Config; $Config::Config{archname} =~ /MSWin32-x64/ }
  ? 'Q'
  : 'L!';
use constant _size_of_pointer => FFI::Platypus->new( api => 2 )->sizeof('opaque');
use constant _pointer_buffer => "P" . _size_of_pointer;

package # hide from PAUSE
  AI::TensorFlow::Libtensorflow::Lib::_Arg {

use Class::Tiny qw(type id);

use overload
	q{""} => 'stringify',
	eq => 'eq';

sub stringify { $_[0]->type }

sub eq {
	my ($self, $other, $swap) = @_;
	"$self" eq "$other";
}

}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::Lib - Private class for AI::TensorFlow::Libtensorflow

=head2 C<tensorflow/c/c_api.h>

=head3 TF_SessionOptions

L<AI::TensorFlow::Libtensorflow::SessionOptions>

=for TF_CAPI_DEF typedef struct TF_SessionOptions TF_SessionOptions;

=head3 TF_Graph

L<AI::TensorFlow::Libtensorflow::Graph>

=for TF_CAPI_DEF typedef struct TF_Graph TF_Graph;

=head3 TF_OperationDescription

L<AI::TensorFlow::Libtensorflow::OperationDescription>

=for TF_CAPI_DEF typedef struct TF_OperationDescription TF_OperationDescription;

=head3 TF_Operation

L<AI::TensorFlow::Libtensorflow::Operation>

=for TF_CAPI_DEF typedef struct TF_Operation TF_Operation;

=head3 TF_Function

=for TF_CAPI_DEF typedef struct TF_Function TF_Function;

=head3 TF_FunctionOptions

=for TF_CAPI_DEF typedef struct TF_FunctionOptions TF_FunctionOptions;

=head3 TF_ImportGraphDefOptions

L<AI::TensorFlow::Libtensorflow::ImportGraphDefOptions>

=for TF_CAPI_DEF typedef struct TF_ImportGraphDefOptions TF_ImportGraphDefOptions;

=head3 TF_ImportGraphDefResults

L<AI::TensorFlow::Libtensorflow::ImportGraphDefResults>

=for TF_CAPI_DEF typedef struct TF_ImportGraphDefResults TF_ImportGraphDefResults;

=head3 TF_Session

L<AI::TensorFlow::Libtensorflow::Session>

=for TF_CAPI_DEF typedef struct TF_Session TF_Session;

=head3 TF_DeprecatedSession

=for TF_CAPI_DEF typedef struct TF_DeprecatedSession TF_DeprecatedSession;

=head3 TF_DeviceList

L<AI::TensorFlow::Libtensorflow::DeviceList>

=for TF_CAPI_DEF typedef struct TF_DeviceList TF_DeviceList;

=head3 TF_Library

=for TF_CAPI_DEF typedef struct TF_Library TF_Library;

=head3 TF_ApiDefMap

L<AI::TensorFlow::Libtensorflow::ApiDefMap>

=for TF_CAPI_DEF typedef struct TF_ApiDefMap TF_ApiDefMap;

=head3 TF_Server

=for TF_CAPI_DEF typedef struct TF_Server TF_Server;

=head2 C<tensorflow/c/c_api_experimental.h>

=head3 TF_CheckpointReader

=for TF_CAPI_DEF typedef struct TF_CheckpointReader TF_CheckpointReader;

=head3 TF_AttrBuilder

=for TF_CAPI_DEF typedef struct TF_AttrBuilder TF_AttrBuilder;

=head3 TF_ShapeAndType

=for TF_CAPI_DEF typedef struct TF_ShapeAndType TF_ShapeAndType;

=head3 TF_ShapeAndTypeList

=for TF_CAPI_DEF typedef struct TF_ShapeAndTypeList TF_ShapeAndTypeList;

=head2 C<tensorflow/c/env.h>

=head3 TF_WritableFileHandle

=for TF_CAPI_DEF typedef struct TF_WritableFileHandle TF_WritableFileHandle;

=head3 TF_StringStream

=for TF_CAPI_DEF typedef struct TF_StringStream TF_StringStream;

=head3 TF_Thread

=for TF_CAPI_DEF typedef struct TF_Thread TF_Thread;

=head2 C<tensorflow/c/kernels.h>

=head3 TF_KernelBuilder

=for TF_CAPI_DEF typedef struct TF_KernelBuilder TF_KernelBuilder;

=head3 TF_OpKernelConstruction

=for TF_CAPI_DEF typedef struct TF_OpKernelConstruction TF_OpKernelConstruction;

=head3 TF_OpKernelContext

=for TF_CAPI_DEF typedef struct TF_OpKernelContext TF_OpKernelContext;

=head2 C<tensorflow/c/kernels_experimental.h>

=head3 TF_VariableInputLockHolder

=for TF_CAPI_DEF typedef struct TF_VariableInputLockHolder TF_VariableInputLockHolder;

=head3 TF_CoordinationServiceAgent

=for TF_CAPI_DEF typedef struct TF_CoordinationServiceAgent TF_CoordinationServiceAgent;

=head2 C<tensorflow/c/tf_shape.h>

=head3 TF_Shape

=for TF_CAPI_DEF typedef struct TF_Shape TF_Shape;

=head2 C<tensorflow/c/tf_status.h>

=head3 TF_Status

L<AI::TensorFlow::Libtensorflow::Status>

=for TF_CAPI_DEF typedef struct TF_Status TF_Status;

=head2 C<tensorflow/c/tf_tensor.h>

=head3 TF_Tensor

L<AI::TensorFlow::Libtensorflow::Tensor>

=for TF_CAPI_DEF typedef struct TF_Tensor TF_Tensor;

=head2 C<tensorflow/tsl/platform/ctstring_internal.h>

=head3 TF_TString

L<AI::TensorFlow::Libtensorflow::TString>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
