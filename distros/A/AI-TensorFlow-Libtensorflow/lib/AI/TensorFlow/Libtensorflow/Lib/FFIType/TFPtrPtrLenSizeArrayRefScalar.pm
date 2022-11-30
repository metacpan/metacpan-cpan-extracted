package AI::TensorFlow::Libtensorflow::Lib::FFIType::TFPtrPtrLenSizeArrayRefScalar;
# ABSTRACT: Type to hold string list as void** strings, size_t* lengths, int num_items
$AI::TensorFlow::Libtensorflow::Lib::FFIType::TFPtrPtrLenSizeArrayRefScalar::VERSION = '0.0.2';
# TODO implement this

sub perl_to_native {
	...
}

sub perl_to_native_post {
	...
}

sub ffi_custom_type_api_1 {
	{
		'native_type' => 'opaque',
		'perl_to_native' => \&perl_to_native,
		'perl_to_native_post' => \&perl_to_native_post,
		argument_count => 3,
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::Lib::FFIType::TFPtrPtrLenSizeArrayRefScalar - Type to hold string list as void** strings, size_t* lengths, int num_items

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
