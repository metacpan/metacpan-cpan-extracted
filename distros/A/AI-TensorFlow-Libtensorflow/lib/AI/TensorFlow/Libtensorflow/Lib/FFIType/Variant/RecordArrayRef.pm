package AI::TensorFlow::Libtensorflow::Lib::FFIType::Variant::RecordArrayRef;
# ABSTRACT: Turn FFI::Platypus::Record into packed array (+ size)?
$AI::TensorFlow::Libtensorflow::Lib::FFIType::Variant::RecordArrayRef::VERSION = '0.0.7';
use strict;
use warnings;
use FFI::Platypus::Buffer qw(scalar_to_buffer buffer_to_scalar);
use FFI::Platypus::API qw( arguments_set_pointer arguments_set_sint32 );

use Package::Variant;
use Module::Runtime qw(module_notional_filename is_module_name);

sub make_variant {
	my ($class, $target_package, $package, %arguments) = @_;

	die "Missing/invalid module name: $arguments{record_module}"
		unless is_module_name($arguments{record_module});

	my $record_module = $arguments{record_module};
	my $with_size     = exists $arguments{with_size} ? $arguments{with_size} : 1;

	my @stack;

	my $perl_to_native = install perl_to_native => sub {
		my ($value, $i) = @_;
		my $data = pack "(a*)*", map $$_, @$value;
		my($pointer, $size) = scalar_to_buffer($data);
		my $n = @$value;
		my $sizeof = $size / $n;
		push @stack, [ \$data, $n, $pointer, $size , $sizeof ];
		arguments_set_pointer $i  , $pointer;
		arguments_set_sint32  $i+1, $n if $with_size;
	};

	my $perl_to_native_post = install perl_to_native_post => sub {
		my($data_ref, $n, $pointer, $size, $sizeof) = @{ pop @stack };
		$$data_ref = buffer_to_scalar($pointer, $size);
		@{$_[0]} = map {
			bless \$_, $record_module
		} unpack  "(a${sizeof})*", $$data_ref;
		();
	};

	install ffi_custom_type_api_1 => sub {
		{
			native_type => 'opaque',
			argument_count => ($with_size ? 2 : 1),
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

AI::TensorFlow::Libtensorflow::Lib::FFIType::Variant::RecordArrayRef - Turn FFI::Platypus::Record into packed array (+ size)?

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022-2023 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
