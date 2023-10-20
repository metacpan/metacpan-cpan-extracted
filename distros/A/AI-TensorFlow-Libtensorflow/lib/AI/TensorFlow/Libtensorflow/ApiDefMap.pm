package AI::TensorFlow::Libtensorflow::ApiDefMap;
# ABSTRACT: Maps Operation to API description
$AI::TensorFlow::Libtensorflow::ApiDefMap::VERSION = '0.0.7';
use strict;
use warnings;
use namespace::autoclean;
use AI::TensorFlow::Libtensorflow::Lib qw(arg);

my $ffi = AI::TensorFlow::Libtensorflow::Lib->ffi;
$ffi->mangler(AI::TensorFlow::Libtensorflow::Lib->mangler_default);

$ffi->attach( [ 'NewApiDefMap' => 'New' ] => [
	arg 'TF_Buffer' => 'op_list_buffer',
	arg 'TF_Status' => 'status',
] => 'TF_ApiDefMap' => sub {
	my ($xs, $class, @rest) = @_;
	$xs->(@rest);
});

$ffi->attach( ['DeleteApiDefMap' => 'DESTROY'] => [
	arg 'TF_ApiDefMap' => 'apimap'
] => 'void');

$ffi->attach( [ 'ApiDefMapPut' => 'Put' ] => [
	arg 'TF_ApiDefMap' => 'api_def_map',
	arg 'tf_text_buffer' => [qw(text text_len)],
	arg 'TF_Status' => 'status',
] => 'void' );

$ffi->attach( ['ApiDefMapGet' => 'Get' ] => [
	arg 'TF_ApiDefMap' => 'api_def_map',
	arg 'tf_text_buffer'  => [qw(name name_len)],
	arg 'TF_Status' => 'status',
] => 'TF_Buffer');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::ApiDefMap - Maps Operation to API description

=head1 SYNOPSIS

  use aliased 'AI::TensorFlow::Libtensorflow::ApiDefMap' => 'ApiDefMap';

=head1 CONSTRUCTORS

=head2 New

  use AI::TensorFlow::Libtensorflow;
  use AI::TensorFlow::Libtensorflow::Status;

  my $map = ApiDefMap->New(
    AI::TensorFlow::Libtensorflow::TFLibrary->GetAllOpList,
    my $status = AI::TensorFlow::Libtensorflow::Status->New
  );
  ok $map, 'Created ApiDefMap';

B<C API>: L<< C<TF_NewApiDefMap>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_NewApiDefMap >>

=head1 METHODS

=head2 Put

B<C API>: L<< C<TF_ApiDefMapPut>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_ApiDefMapPut >>

=head2 Get

=over 2

C<<<
Get($name, $status)
>>>

=back

  my $api_def_buf = $map->Get(
    'NoOp',
    my $status = AI::TensorFlow::Libtensorflow::Status->New
  );

  cmp_ok $api_def_buf->length, '>', 0, 'Got ApiDef buffer for NoOp operation';

B<Parameters>

=over 4

=item Str $name

Name of the operation to retrieve.

=item L<TFStatus|AI::TensorFlow::Libtensorflow::Lib::Types/TFStatus> $status

Status.

=back

B<Returns>

=over 4

=item Maybe[TFBuffer]

Contains a serialized C<ApiDef> proto for the operation.

=back

B<C API>: L<< C<TF_ApiDefMapGet>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_ApiDefMapGet >>

=head1 DESTRUCTORS

=head2 DESTROY

B<C API>: L<< C<TF_DeleteApiDefMap>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_DeleteApiDefMap >>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022-2023 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
