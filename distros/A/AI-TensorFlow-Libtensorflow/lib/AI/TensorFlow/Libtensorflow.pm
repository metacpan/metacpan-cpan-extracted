package AI::TensorFlow::Libtensorflow;
# ABSTRACT: Bindings for Libtensorflow deep learning library
$AI::TensorFlow::Libtensorflow::VERSION = '0.0.4';
use strict;
use warnings;

use AI::TensorFlow::Libtensorflow::Lib;

use AI::TensorFlow::Libtensorflow::DataType;
use AI::TensorFlow::Libtensorflow::Status;
use AI::TensorFlow::Libtensorflow::TString;

use AI::TensorFlow::Libtensorflow::Buffer;
use AI::TensorFlow::Libtensorflow::Tensor;

use AI::TensorFlow::Libtensorflow::Operation;
use AI::TensorFlow::Libtensorflow::Output;
use AI::TensorFlow::Libtensorflow::Input;

use AI::TensorFlow::Libtensorflow::ApiDefMap;
use AI::TensorFlow::Libtensorflow::TFLibrary;

use AI::TensorFlow::Libtensorflow::ImportGraphDefOptions;
use AI::TensorFlow::Libtensorflow::ImportGraphDefResults;
use AI::TensorFlow::Libtensorflow::Graph;

use AI::TensorFlow::Libtensorflow::OperationDescription;

use AI::TensorFlow::Libtensorflow::SessionOptions;
use AI::TensorFlow::Libtensorflow::Session;
use AI::TensorFlow::Libtensorflow::DeviceList;

use AI::TensorFlow::Libtensorflow::Eager::ContextOptions;
use AI::TensorFlow::Libtensorflow::Eager::Context;

use FFI::C;

my $ffi = AI::TensorFlow::Libtensorflow::Lib->ffi;
FFI::C->ffi($ffi);

$ffi->mangler(AI::TensorFlow::Libtensorflow::Lib->mangler_default);

sub new {
	my ($class) = @_;
	bless {}, $class;
}

$ffi->attach( 'Version' => [], 'string' );#}}}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow - Bindings for Libtensorflow deep learning library

=head1 SYNOPSIS

  use aliased 'AI::TensorFlow::Libtensorflow' => 'Libtensorflow';

=head1 DESCRIPTION

The C<libtensorflow> library provides low-level C bindings
for TensorFlow with a stable ABI.

=head1 CLASS METHODS

=head2 Version

  my $version = Libtensorflow->Version();
  like $version, qr/(\d|\.)+/, 'Got version';

B<Returns>

=over 4

=item Str

Version number for the C<libtensorflow> library.

=back

B<C API>: L<< C<TF_Version>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_Version >>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
