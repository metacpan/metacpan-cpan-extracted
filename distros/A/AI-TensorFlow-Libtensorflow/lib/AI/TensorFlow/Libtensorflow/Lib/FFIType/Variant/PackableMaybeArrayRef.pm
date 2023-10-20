package AI::TensorFlow::Libtensorflow::Lib::FFIType::Variant::PackableMaybeArrayRef;
# ABSTRACT: Maybe[ArrayRef] to pack()'ed scalar argument with size argument (as int) (size is -1 if undef)
$AI::TensorFlow::Libtensorflow::Lib::FFIType::Variant::PackableMaybeArrayRef::VERSION = '0.0.7';
use strict;
use warnings;
use FFI::Platypus::Buffer qw(scalar_to_buffer buffer_to_scalar);
use FFI::Platypus::API qw( arguments_set_pointer arguments_set_sint32 );

use Package::Variant;
use Module::Runtime 'module_notional_filename';

sub make_variant {
	my ($class, $target_package, $package, %arguments) = @_;

	die "Invalid pack type, must be single character"
		unless $arguments{pack_type} =~ /^.$/;

	my @stack;

	my $perl_to_native = install perl_to_native => sub {
		my ($value, $i) = @_;
		if( defined $value ) {
			die "Value must be an ArrayRef" unless ref $value eq 'ARRAY';
			my $data = pack  $arguments{pack_type} . '*', @$value;
			my $n    = scalar @$value;
			my ($pointer, $size) = scalar_to_buffer($data);

			push @stack, [ \$data, $pointer, $size ];
			arguments_set_pointer( $i  , $pointer);
			arguments_set_sint32(  $i+1, $n);
		} else {
			my $data = undef;
			my $n    = -1;
			my ($pointer, $size) = (0, 0);
			push @stack, [ \$data, $pointer, $size ];
			arguments_set_pointer( $i  , $pointer);
			arguments_set_sint32(  $i+1, $n);
		}
	};

	my $perl_to_native_post = install perl_to_native_post => sub {
		my ($data_ref, $pointer, $size) = @{ pop @stack };
		if( ! Scalar::Util::readonly($_[0]) ) {
			$$data_ref = buffer_to_scalar($pointer, $size);
			@{$_[0]} = unpack $arguments{pack_type} . '*', $$data_ref;
		}
		();
	};
	install ffi_custom_type_api_1 => sub {
		{
			native_type => 'opaque',
			argument_count => 2,
			perl_to_native => $perl_to_native,
			perl_to_native_post => $perl_to_native_post,
		}
	};
}

sub make_variant_package_name {
	my ($class, $package, %arguments) = @_;
	$package = "AI::TensorFlow::Libtensorflow::Lib::FFIType::TF${package}";
	die "Won't clobber $package" if $INC{module_notional_filename $package};
	return $package;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::Lib::FFIType::Variant::PackableMaybeArrayRef - Maybe[ArrayRef] to pack()'ed scalar argument with size argument (as int) (size is -1 if undef)

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022-2023 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
