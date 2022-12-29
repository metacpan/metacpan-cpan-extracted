package AI::TensorFlow::Libtensorflow::Lib::_Alloc;
# ABSTRACT: [private] Allocation utilities
$AI::TensorFlow::Libtensorflow::Lib::_Alloc::VERSION = '0.0.4';
use strict;
use warnings;
use AI::TensorFlow::Libtensorflow::Lib;
use AI::TensorFlow::Libtensorflow::Tensor;
use AI::TensorFlow::Libtensorflow::DataType qw(INT8);
use FFI::Platypus::Memory qw(malloc free strcpy);
use FFI::Platypus::Buffer qw(buffer_to_scalar window);
use Sub::Quote qw(quote_sub);

use Feature::Compat::Defer;

# If _aligned_alloc() implementation needs the size to be a multiple of the
# alignment.
our $_ALIGNED_ALLOC_ALIGNMENT_MULTIPLE = 0;

my $ffi = FFI::Platypus->new;
$ffi->lib(undef);
if( $ffi->find_symbol('aligned_alloc') ) {
	# C11 aligned_alloc()
	# NOTE: C11 aligned_alloc not available on Windows.
	# void *aligned_alloc(size_t alignment, size_t size);
	$ffi->attach( [ 'aligned_alloc' => '_aligned_alloc' ] =>
		[ 'size_t', 'size_t' ] => 'opaque' );
	*_aligned_free = *free;
	$_ALIGNED_ALLOC_ALIGNMENT_MULTIPLE = 1;
} else {
	# Pure Perl _aligned_alloc()
	quote_sub '_aligned_alloc', q{
		my ($alignment, $size) = @_;

		# $alignment must fit in 8-bits
		die "\$alignment must be <= 255" if $alignment > 0xFF;

		my $requested_size = $alignment + $size;       # size_t
		my $ptr = malloc($requested_size);             # void*
		my $offset = $alignment - $ptr % $alignment;   # size_t
		my $aligned = $ptr + $offset;                  # void*

		strcpy $aligned - 1, chr($offset);

		return $aligned;
	};
	quote_sub '_aligned_free', q{
		my ($aligned) = @_;
		my $offset = ord(buffer_to_scalar($aligned - 1, 1));
		free( $aligned - $offset );
	};
	$_ALIGNED_ALLOC_ALIGNMENT_MULTIPLE = 0;
}

use Const::Fast;
# See <https://github.com/tensorflow/tensorflow/issues/58112>.
# This is a power-of-two.
const our $EIGEN_MAX_ALIGN_BYTES => do { _tf_alignment(); };

sub _tf_alignment {
	# Bytes of alignment sorted in descending order:
	# NOTE Alignment can not currently be larger than 128-bytes as the pure
	# Perl implementation of _aligned_alloc() only supports alignment of up
	# to 255 bytes (which means 128 bytes is the maximum power-of-two
	# alignment).
	my @alignments = map 2**$_, reverse 0..7;

	# 1-byte element
	my $el = INT8;
	my $el_size = $el->Size;

	my $max_alignment = $alignments[0];
	my $req_size = 2 * $max_alignment + $el_size;
	# All data that is sent to TF_NewTensor here is within the block of
	# memory allocated at $ptr_base.
	my $ptr_base = malloc($req_size);
	defer { free($ptr_base); }

	# start at offset that is aligned with $max_alignment
	my $ptr = $ptr_base + ( $max_alignment - $ptr_base % $max_alignment );

	my $create_tensor_at_alignment = sub {
		my ($n, $dealloc_called) = @_;
		my $offset = $n - $ptr % $n;
		my $ptr_offset = $ptr + $offset;
		my $space_for_data = $req_size - $offset;

		window(my $data, $ptr_offset, $space_for_data);

		return AI::TensorFlow::Libtensorflow::Tensor->New(
			$el, [int($space_for_data/$el_size)], \$data, sub {
				$$dealloc_called = 1
			}
		);
	};

	for my $a_idx (0..@alignments-2) {
		my @dealloc = (0, 0);
		my @t = map {
			$create_tensor_at_alignment->($alignments[$a_idx + $_], \$dealloc[$_]);
		} (0..1);
		return $alignments[$a_idx] if $dealloc[0] == 0 && $dealloc[1] == 1;
	}

	return 1;
}

sub _tf_aligned_alloc {
	my ($class, $size) = @_;
	return _aligned_alloc($EIGEN_MAX_ALIGN_BYTES,
		$_ALIGNED_ALLOC_ALIGNMENT_MULTIPLE
		# since $EIGEN_MAX_ALIGN_BYTES is a power-of-two, use
		# two's complement bit arithmetic
		?  ($size + $EIGEN_MAX_ALIGN_BYTES - 1 ) & -$EIGEN_MAX_ALIGN_BYTES
		: $size
	);
}

sub _tf_aligned_free {
	my ($class, $ptr) = @_;
	_aligned_free($ptr);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::Lib::_Alloc - [private] Allocation utilities

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
