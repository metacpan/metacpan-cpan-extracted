package AI::TensorFlow::Libtensorflow::_Misc;
# ABSTRACT: Private API
$AI::TensorFlow::Libtensorflow::_Misc::VERSION = '0.0.6';
use strict;
use warnings;
use namespace::autoclean;
use AI::TensorFlow::Libtensorflow::Lib qw(arg);

my $ffi = AI::TensorFlow::Libtensorflow::Lib->ffi;
$ffi->mangler(AI::TensorFlow::Libtensorflow::Lib->mangler_default);

$ffi->attach( 'TensorFromProto' => [
	arg 'TF_Buffer' => 'from',
	arg 'TF_Tensor' => 'to',
	arg 'TF_Status' => 'status',
]);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::_Misc - Private API

=head1 FUNCTIONS

=head2 FromProto

B<C API>: L<< C<TF_TensorFromProto>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_TensorFromProto >>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022-2023 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
