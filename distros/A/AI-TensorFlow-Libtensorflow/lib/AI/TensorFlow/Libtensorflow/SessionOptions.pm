package AI::TensorFlow::Libtensorflow::SessionOptions;
$AI::TensorFlow::Libtensorflow::SessionOptions::VERSION = '0.0.2';
use namespace::autoclean;
use AI::TensorFlow::Libtensorflow::Lib qw(arg);;
my $ffi = AI::TensorFlow::Libtensorflow::Lib->ffi;
$ffi->mangler(AI::TensorFlow::Libtensorflow::Lib->mangler_default);

$ffi->attach( [ 'NewSessionOptions' => 'New' ] =>
	[ ], => 'TF_SessionOptions' );

$ffi->attach( [ 'DeleteSessionOptions' => 'DESTROY' ] => [
	arg 'TF_SessionOptions' => 'self',
] => 'void');

$ffi->attach( 'SetTarget' => [
	arg 'TF_SessionOptions' => 'options',
	arg 'string' => 'target',
] => 'void');

$ffi->attach( 'SetConfig' => [
	arg 'TF_SessionOptions' => 'options',
	arg 'tf_config_proto_buffer' => [qw(proto proto_len)],
	arg 'TF_Status' => 'status',
] => 'void' );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::SessionOptions

=head1 CONSTRUCTORS

=head2 New

B<Returns>

=over 4

=item L<TFSessionOptions|AI::TensorFlow::Libtensorflow::Lib::Types/TFSessionOptions>

A new options object.

=back

B<C API>: L<< C<TF_NewSessionOptions>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_NewSessionOptions >>

=head1 METHODS

=head2 SetTarget

B<C API>: L<< C<TF_SetTarget>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_SetTarget >>

=head2 SetConfig

B<C API>: L<< C<TF_SetConfig>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_SetConfig >>

=head1 DESTRUCTORS

=head2 DESTROY

B<C API>: L<< C<TF_DeleteSessionOptions>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_DeleteSessionOptions >>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
