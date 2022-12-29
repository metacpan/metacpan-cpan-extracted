package AI::TensorFlow::Libtensorflow::Eager::Context;
# ABSTRACT: Eager context
$AI::TensorFlow::Libtensorflow::Eager::Context::VERSION = '0.0.4';
use strict;
use warnings;
use AI::TensorFlow::Libtensorflow::Lib qw(arg);
my $ffi = AI::TensorFlow::Libtensorflow::Lib->ffi;
$ffi->mangler(AI::TensorFlow::Libtensorflow::Lib->mangler_default);

$ffi->attach( [ 'NewContext' => 'New' ] => [
	arg TFE_ContextOptions => 'opts',
	arg TF_Status => 'status'
] => 'TFE_Context' => sub {
	my ($xs, $class, @rest) = @_;
	$xs->(@rest);
} );

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::Eager::Context - Eager context

=head1 CONSTRUCTORS

=head2 New

B<C API>: L<< C<TFE_NewContext>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TFE_NewContext >>

B<C API>: L<< C<TFE_DeleteContext>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TFE_DeleteContext >>

1;

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
