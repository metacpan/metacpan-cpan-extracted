package AI::TensorFlow::Libtensorflow::DeviceList;
# ABSTRACT: A list of devices available for the session to run on
$AI::TensorFlow::Libtensorflow::DeviceList::VERSION = '0.0.7';
use strict;
use warnings;
use namespace::autoclean;
use AI::TensorFlow::Libtensorflow::Lib qw(arg);

my $ffi = AI::TensorFlow::Libtensorflow::Lib->ffi;
$ffi->mangler(AI::TensorFlow::Libtensorflow::Lib->mangler_default);

$ffi->attach( [ 'DeleteDeviceList' => 'DESTROY' ] => [
	arg TF_DeviceList => 'list',
] => 'void' );

$ffi->attach( [ 'DeviceListCount' => 'Count' ] => [
	arg TF_DeviceList => 'list',
] => 'int' );

my %methods = (
	Name        => 'string',
	Type        => 'string',
	MemoryBytes => 'int64_t',
	Incarnation => 'uint64_t',
);
for my $method (keys %methods) {
	$ffi->attach( [ "DeviceList${method}" => $method ] => [
		arg TF_DeviceList => 'list',
		arg int => 'index',
		arg TF_Status => 'status'
	] => $methods{$method} );
}

### From tensorflow/core/framework/types.cc
my %DEVICE_TYPES = (
	DEFAULT => "DEFAULT",
	CPU => "CPU",
	GPU => "GPU",
	TPU => "TPU",
	TPU_SYSTEM => "TPU_SYSTEM",
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::DeviceList - A list of devices available for the session to run on

=head1 ATTRIBUTES

=head2 Count

B<C API>: L<< C<TF_DeviceListCount>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_DeviceListCount >>

=head1 METHODS

=head2 Name

B<C API>: L<< C<TF_DeviceListName>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_DeviceListName >>

=head2 Type

B<C API>: L<< C<TF_DeviceListType>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_DeviceListType >>

=head2 MemoryBytes

B<C API>: L<< C<TF_DeviceListMemoryBytes>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_DeviceListMemoryBytes >>

=head2 Incarnation

B<C API>: L<< C<TF_DeviceListIncarnation>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_DeviceListIncarnation >>

=head1 DESTRUCTORS

=head2 DESTROY

B<C API>: L<< C<TF_DeleteDeviceList>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_DeleteDeviceList >>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022-2023 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
