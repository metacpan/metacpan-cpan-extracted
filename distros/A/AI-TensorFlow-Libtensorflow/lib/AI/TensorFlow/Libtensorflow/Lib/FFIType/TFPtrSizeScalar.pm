package AI::TensorFlow::Libtensorflow::Lib::FFIType::TFPtrSizeScalar;
# ABSTRACT: Type to hold pointer and size in a scalar (input only)
$AI::TensorFlow::Libtensorflow::Lib::FFIType::TFPtrSizeScalar::VERSION = '0.0.6';
use strict;
use warnings;
use FFI::Platypus;
use FFI::Platypus::API qw(
  arguments_set_pointer
  arguments_set_uint32
  arguments_set_uint64
);
use FFI::Platypus::Buffer qw( scalar_to_buffer );

my @stack;

*arguments_set_size_t
	= FFI::Platypus->new( api => 2 )->sizeof('size_t') == 4
	? \&arguments_set_uint32
	: \&arguments_set_uint64;

sub perl_to_native {
	my($pointer, $size) = scalar_to_buffer($_[0]);
	push @stack, [ $pointer, $size ];
	arguments_set_pointer $_[1], $pointer;
	arguments_set_size_t($_[1]+1, $size);
}

sub perl_to_native_post {
	my($pointer, $size) = @{ pop @stack };
	();
}

sub ffi_custom_type_api_1
{
	{
		native_type         => 'opaque',
		perl_to_native      => \&perl_to_native,
		perl_to_native_post => \&perl_to_native_post,
		argument_count      => 2,
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::Lib::FFIType::TFPtrSizeScalar - Type to hold pointer and size in a scalar (input only)

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022-2023 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
