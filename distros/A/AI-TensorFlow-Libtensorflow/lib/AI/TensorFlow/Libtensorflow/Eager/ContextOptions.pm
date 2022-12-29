package AI::TensorFlow::Libtensorflow::Eager::ContextOptions;
# ABSTRACT: Eager context options
$AI::TensorFlow::Libtensorflow::Eager::ContextOptions::VERSION = '0.0.4';
use strict;
use warnings;
use AI::TensorFlow::Libtensorflow::Lib qw(arg);
my $ffi = AI::TensorFlow::Libtensorflow::Lib->ffi;
$ffi->mangler(AI::TensorFlow::Libtensorflow::Lib->mangler_default);

$ffi->attach( [ 'NewContextOptions' => 'New' ] => [
] => 'TFE_ContextOptions' );

$ffi->attach( [ 'DeleteContextOptions' => 'DESTROY' ] => [
	arg TFE_ContextOptions => 'options'
] => 'void' );


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::Eager::ContextOptions - Eager context options

=head1 CONSTRUCTORS

=head2 New

B<C API>: L<< C<TFE_NewContextOptions>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TFE_NewContextOptions >>

=head1 DESTRUCTORS

=head2 DESTROY

B<C API>: L<< C<TFE_DeleteContextOptions>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TFE_DeleteContextOptions >>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
