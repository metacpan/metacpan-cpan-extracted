package AI::TensorFlow::Libtensorflow::TString;
# ABSTRACT: A variable-capacity string type
$AI::TensorFlow::Libtensorflow::TString::VERSION = '0.0.7';
use strict;
use warnings;
use namespace::autoclean;
use AI::TensorFlow::Libtensorflow::Lib qw(arg);
use FFI::Platypus::Memory qw(malloc free);

my $ffi = AI::TensorFlow::Libtensorflow::Lib->ffi;
$ffi->mangler(AI::TensorFlow::Libtensorflow::Lib->mangler_default);

### From <tensorflow/tsl/platform/ctstring_internal.h>
#// _Static_assert(sizeof(TF_TString) == 24);
use constant SIZEOF_TF_TString => 24;


### From <tensorflow/tsl/platform/ctstring_internal.h>
# typedef enum TF_TString_Type {  // NOLINT
#   TF_TSTR_SMALL = 0x00,
#   TF_TSTR_LARGE = 0x01,
#   TF_TSTR_OFFSET = 0x02,
#   TF_TSTR_VIEW = 0x03,
#   TF_TSTR_TYPE_MASK = 0x03
# } TF_TString_Type;

sub _CREATE {
	my ($class) = @_;
	my $pointer = malloc SIZEOF_TF_TString;
	my $obj = bless { ptr => $pointer }, $class;
}

$ffi->attach( [ 'StringInit' => 'Init' ] => [
	arg 'TF_TString' => 'tstr'
] => 'void' => sub {
	my ($xs, $invoc) = @_;
	my $obj = ref $invoc ? $invoc : $invoc->_CREATE();
	$xs->($obj);
	$obj;
});

$ffi->attach( [ 'StringCopy' => 'Copy' ] => [
	arg TF_TString => 'dst',
	arg tf_text_buffer => [ qw( src size ) ],
] => 'void' );

$ffi->attach( [ 'StringAssignView' => 'AssignView' ] => [
	arg TF_TString => 'dst',
	arg tf_text_buffer => [ qw( src size ) ],
] => 'void' );

$ffi->attach( [ 'StringGetDataPointer' => 'GetDataPointer' ] => [
	arg TF_TString => 'tstr',
] => 'opaque' );

$ffi->attach( [ 'StringGetType' => 'GetType' ] => [
	arg TF_TString => 'str'
] => 'int' );

$ffi->attach( [ 'StringGetSize' => 'GetSize' ] => [
	arg TF_TString => 'tstr'
] => 'size_t' );

$ffi->attach( [ 'StringGetCapacity' => 'GetCapacity' ] => [
	arg TF_TString => 'str'
] => 'size_t' );

$ffi->attach( [ 'StringDealloc' => 'Dealloc' ] => [
	arg TF_TString => 'tstr',
] => 'void' );

sub DESTROY {
	if( ! $_[0]->{owner} ) {
		$_[0]->Dealloc;
		free $_[0]->{ptr};
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::TString - A variable-capacity string type

=head1 SYNOPSIS

  use aliased 'AI::TensorFlow::Libtensorflow::TString';

=head1 CONSTRUCTORS

=head2 Init

  my $tstr = TString->Init;

B<C API>: L<< C<TF_StringInit>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_StringInit >>

=head1 METHODS

=head2 Copy

B<C API>: L<< C<TF_StringCopy>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_StringCopy >>

=head2 AssignView

B<C API>: L<< C<TF_StringAssignView>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_StringAssignView >>

=head2 GetDataPointer

TODO API question: Should this be an opaque or a window()?

B<C API>: L<< C<TF_StringGetDataPointer>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_StringGetDataPointer >>

=head2 GetType

TODO API question: Add enum for TF_TString_Type return type?

B<C API>: L<< C<TF_StringGetType>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_StringGetType >>

=head2 GetSize

B<C API>: L<< C<TF_StringGetSize>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_StringGetSize >>

=head2 GetCapacity

B<C API>: L<< C<TF_StringGetCapacity>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_StringGetCapacity >>

=head2 Dealloc

B<C API>: L<< C<TF_StringDealloc>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_StringDealloc >>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022-2023 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
