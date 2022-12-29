package AI::TensorFlow::Libtensorflow::Lib::FFIType::TFPtrSizeScalarRef;
# ABSTRACT: Type to hold pointer and size in a scalar reference
$AI::TensorFlow::Libtensorflow::Lib::FFIType::TFPtrSizeScalarRef::VERSION = '0.0.4';
use strict;
use warnings;
use FFI::Platypus::Buffer qw(scalar_to_buffer);
use FFI::Platypus::API qw(
	arguments_set_pointer
	arguments_set_uint32
	arguments_set_uint64
);


my @stack;

# See FFI::Platypus::Type::PointerSizeBuffer
*arguments_set_size_t
	= FFI::Platypus->new( api => 2 )->sizeof('size_t') == 4
	? \&arguments_set_uint32
	: \&arguments_set_uint64;

sub perl_to_native {
	my ($value, $i) = @_;
	die "Value must be a ScalarRef" unless ref $value eq 'SCALAR';

	my ($pointer, $size) = defined $$value
		? scalar_to_buffer($$value)
		: (0, 0);

	push @stack, [ $value, $pointer, $size ];
	arguments_set_pointer( $i  , $pointer);
	arguments_set_size_t(  $i+1, $size);
}

sub perl_to_native_post {
	pop @stack;
	();
}

sub ffi_custom_type_api_1 {
	{
		'native_type' => 'opaque',
		'perl_to_native' => \&perl_to_native,
		'perl_to_native_post' => \&perl_to_native_post,
		argument_count => 2,
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::Lib::FFIType::TFPtrSizeScalarRef - Type to hold pointer and size in a scalar reference

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
