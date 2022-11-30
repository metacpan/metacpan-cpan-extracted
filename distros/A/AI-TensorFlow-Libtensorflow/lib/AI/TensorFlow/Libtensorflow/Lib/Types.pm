package AI::TensorFlow::Libtensorflow::Lib::Types;
# ABSTRACT: Type library
$AI::TensorFlow::Libtensorflow::Lib::Types::VERSION = '0.0.2';
use Type::Library 0.008 -base,
	-declare => [qw(
		TFTensor
		TFGraph
		TFDataType

		Dims
	)];
use Type::Utils -all;
use Types::Standard qw(ArrayRef Int);

class_type TFTensor => { class => 'AI::TensorFlow::Libtensorflow::Tensor' };

class_type TFGraph => { class => 'AI::TensorFlow::Libtensorflow::Graph' };

class_type TFDataType => { class => 'AI::TensorFlow::Libtensorflow::DataType' };

class_type TFSession => { class => 'AI::TensorFlow::Libtensorflow::Session' };

class_type TFSessionOptions => { class => 'AI::TensorFlow::Libtensorflow::SessionOptions' };

class_type TFStatus => { class => 'AI::TensorFlow::Libtensorflow::Status' };

class_type TFBuffer => { class => 'AI::TensorFlow::Libtensorflow::Buffer' };

class_type TFOperation => { class => 'AI::TensorFlow::Libtensorflow::Operation' };


declare Dims => as ArrayRef[Int];


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

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
