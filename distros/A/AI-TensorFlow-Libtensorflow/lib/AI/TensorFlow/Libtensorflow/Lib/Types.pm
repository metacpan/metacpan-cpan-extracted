package AI::TensorFlow::Libtensorflow::Lib::Types;
# ABSTRACT: Type library
$AI::TensorFlow::Libtensorflow::Lib::Types::VERSION = '0.0.7';
use strict;
use warnings;
use Type::Library 0.008 -base,
	-declare => [qw(
		TFTensor
		TFGraph
		TFDataType

		Dims
	)];
use Type::Utils -all;
use Types::Standard qw(ArrayRef Int Tuple InstanceOf);

class_type TFTensor => { class => 'AI::TensorFlow::Libtensorflow::Tensor' };

class_type TFGraph => { class => 'AI::TensorFlow::Libtensorflow::Graph' };

class_type TFDataType => { class => 'AI::TensorFlow::Libtensorflow::DataType' };

class_type TFSession => { class => 'AI::TensorFlow::Libtensorflow::Session' };

class_type TFSessionOptions => { class => 'AI::TensorFlow::Libtensorflow::SessionOptions' };

class_type TFStatus => { class => 'AI::TensorFlow::Libtensorflow::Status' };

class_type TFBuffer => { class => 'AI::TensorFlow::Libtensorflow::Buffer' };

class_type TFOperation => { class => 'AI::TensorFlow::Libtensorflow::Operation' };


declare Dims => as ArrayRef[Int];

class_type TFOutput => { class => 'AI::TensorFlow::Libtensorflow::Output' };

declare_coercion "TFOutputFromTuple",
	to_type 'TFOutput',
	from Tuple[InstanceOf['AI::TensorFlow::Libtensorflow::Operation'],Int],
	q {
		AI::TensorFlow::Libtensorflow::Output->New({
			oper  => $_->[0],
			index => $_->[1],
		});
	};

class_type TFInput => { class => 'AI::TensorFlow::Libtensorflow::Input' };

declare_coercion "TFInputFromTuple",
	to_type 'TFInput',
	from Tuple[InstanceOf['AI::TensorFlow::Libtensorflow::Operation'],Int],
	q {
		AI::TensorFlow::Libtensorflow::Input->New({
			oper  => $_->[0],
			index => $_->[1],
		});
	};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::Lib::Types - Type library

=head1 TYPES

=head2 TFTensor

Type for class L<AI::TensorFlow::Libtensorflow::Tensor>.

=head2 TFGraph

Type for class L<AI::TensorFlow::Libtensorflow::Graph>.

=head2 TFDataType

Type for class L<AI::TensorFlow::Libtensorflow::DataType>

=head2 TFSession

Type for class L<AI::TensorFlow::Libtensorflow::Session>

=head2 TFSessionOptions

Type for class L<AI::TensorFlow::Libtensorflow::SessionOptions>

=head2 TFStatus

Type for class L<AI::TensorFlow::Libtensorflow::Status>

=head2 TFBuffer

Type for class L<AI::TensorFlow::Libtensorflow::Buffer>

=head2 TFOperation

Type for class L<AI::TensorFlow::Libtensorflow::Operation>

=head2 Dims

C<ArrayRef> of C<Int>

=head2 TFOutput

Type for class L<AI::TensorFlow::Libtensorflow::Output>

=head2 TFInput

Type for class L<AI::TensorFlow::Libtensorflow::Input>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022-2023 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
