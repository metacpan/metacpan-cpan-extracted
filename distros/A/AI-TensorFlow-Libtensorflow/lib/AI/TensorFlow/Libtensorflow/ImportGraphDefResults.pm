package AI::TensorFlow::Libtensorflow::ImportGraphDefResults;
# ABSTRACT: Results from importing a graph definition
$AI::TensorFlow::Libtensorflow::ImportGraphDefResults::VERSION = '0.0.3';
use strict;
use warnings;
use namespace::autoclean;
use AI::TensorFlow::Libtensorflow::Lib qw(arg);
use FFI::Platypus::Buffer qw(buffer_to_scalar window);
use List::Util ();

my $ffi = AI::TensorFlow::Libtensorflow::Lib->ffi;
$ffi->mangler(AI::TensorFlow::Libtensorflow::Lib->mangler_default);

$ffi->attach( [ 'DeleteImportGraphDefResults' => 'DESTROY' ] => [
	arg TF_ImportGraphDefResults => 'results',
] => 'void' );

$ffi->attach( [ 'ImportGraphDefResultsReturnOutputs' => 'ReturnOutputs' ] => [
	arg TF_ImportGraphDefResults => 'results',
	arg 'int*' => 'num_outputs',
	arg 'opaque*' => { id => 'outputs', type => 'TF_Output_struct_array*' },
] => 'void' => sub {
	my ($xs, $results) = @_;
	my $num_outputs;
	my $outputs_array = undef;
	$xs->($results, \$num_outputs, \$outputs_array);
	return [] if $num_outputs == 0;

	my $sizeof_output = $ffi->sizeof('TF_Output');
	window(my $outputs_packed, $outputs_array, $sizeof_output * $num_outputs );
	# due to unpack, these are copies (no longer owned by $results)
	my @outputs = map bless(\$_, "AI::TensorFlow::Libtensorflow::Output"),
		unpack "(a${sizeof_output})*", $outputs_packed;
	return \@outputs;
});

$ffi->attach( [ 'ImportGraphDefResultsReturnOperations' => 'ReturnOperations' ] => [
	arg TF_ImportGraphDefResults => 'results',
	arg 'int*' => 'num_opers',
	arg 'opaque*' => { id => 'opers', type => 'TF_Operation_array*' },
] => 'void' => sub {
	my ($xs, $results) = @_;
	my $num_opers;
	my $opers_array = undef;
	$xs->($results, \$num_opers, \$opers_array);
	return [] if $num_opers == 0;

	my $opers_array_base_packed = buffer_to_scalar($opers_array,
		$ffi->sizeof('opaque') * $num_opers );
	my @opers = map {
		$ffi->cast('opaque', 'TF_Operation', $_ )
	} unpack "(@{[ AI::TensorFlow::Libtensorflow::Lib::_pointer_incantation ]})*", $opers_array_base_packed;
	return \@opers;
} );

$ffi->attach( [ 'ImportGraphDefResultsMissingUnusedInputMappings' => 'MissingUnusedInputMappings' ] => [
    arg TF_ImportGraphDefResults => 'results',
    arg 'int*' => 'num_missing_unused_input_mappings',
    arg 'opaque*' => { id => 'src_names', ctype => 'const char***' },
    arg 'opaque*' => { id => 'src_indexes', ctype => 'int**' },
] => 'void' => sub {
	my ($xs, $results) = @_;
	my $num_missing_unused_input_mappings;
	my $src_names;
	my $src_indexes;
	$xs->($results,
		\$num_missing_unused_input_mappings,
		\$src_names, \$src_indexes
	);
	my $src_names_str   = $ffi->cast('opaque',
		"string[$num_missing_unused_input_mappings]", $src_names);
	my $src_indexes_int = $ffi->cast('opaque',
		"int[$num_missing_unused_input_mappings]", $src_indexes);
	return [ List::Util::zip($src_names_str, $src_indexes_int) ];
});

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::ImportGraphDefResults - Results from importing a graph definition

=head1 METHODS

=head2 ReturnOutputs

B<C API>: L<< C<TF_ImportGraphDefResultsReturnOutputs>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_ImportGraphDefResultsReturnOutputs >>

=head2 ReturnOperations

B<C API>: L<< C<TF_ImportGraphDefResultsReturnOperations>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_ImportGraphDefResultsReturnOperations >>

=head2 MissingUnusedInputMappings

B<C API>: L<< C<TF_ImportGraphDefResultsMissingUnusedInputMappings>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_ImportGraphDefResultsMissingUnusedInputMappings >>

=head1 DESTRUCTORS

=head2 DESTROY

B<C API>: L<< C<TF_DeleteImportGraphDefResults>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_DeleteImportGraphDefResults >>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
