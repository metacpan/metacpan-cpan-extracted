package AI::TensorFlow::Libtensorflow::Lib::FFIType::TFInt64SizeArrayRef;
# ABSTRACT: Type to hold int64_t array and number of elements
$AI::TensorFlow::Libtensorflow::Lib::FFIType::TFInt64SizeArrayRef::VERSION = '0.0.2';
use FFI::Platypus::Buffer qw(scalar_to_buffer);
use FFI::Platypus::API qw( arguments_set_pointer arguments_set_sint32 );

# int64_t[] + int
my @stack;

sub perl_to_native {
	my ($value, $i) = @_;
	# q = signed 64-bit int (quad)
	my $data = pack 'q*', @$value;
	my $n    = scalar @$value;
	my ($pointer, $size) = scalar_to_buffer($data);

	push @stack, [ \$data, $pointer, $size ];
	arguments_set_pointer( $i  , $pointer);
	arguments_set_sint32(  $i+1, $n);
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

AI::TensorFlow::Libtensorflow::Lib::FFIType::TFInt64SizeArrayRef - Type to hold int64_t array and number of elements

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
