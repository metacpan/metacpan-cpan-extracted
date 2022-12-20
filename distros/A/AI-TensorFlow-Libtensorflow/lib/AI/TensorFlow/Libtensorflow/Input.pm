package AI::TensorFlow::Libtensorflow::Input;
# ABSTRACT: Input of operation as (operation, index) pair
$AI::TensorFlow::Libtensorflow::Input::VERSION = '0.0.3';
# See L<AI::TensorFlow::Libtensorflow::Output> for similar.
# In fact, they are mostly the same, but keeping the classes separate for now
# in case the upstream API changes.

use strict;
use warnings;
use namespace::autoclean;
use FFI::Platypus::Record;
use AI::TensorFlow::Libtensorflow::Lib::FFIType::Variant::RecordArrayRef;

use AI::TensorFlow::Libtensorflow::Lib;
my $ffi = AI::TensorFlow::Libtensorflow::Lib->ffi;
$ffi->mangler(AI::TensorFlow::Libtensorflow::Lib->mangler_default);

record_layout_1($ffi,
	'opaque' => '_oper',   # 8 (on 64-bit)
	'int'    => '_index',  # 4

	$ffi->sizeof('opaque') == 8 ? (
		'char[4]' => ':',
	) : (),
);
$ffi->type('record(AI::TensorFlow::Libtensorflow::Input)', 'TF_Input');

sub New {
	my ($class, $args) = @_;

	my $record = $class->new({
		_oper => $ffi->cast( 'TF_Operation', 'opaque', delete $args->{oper} ),
		_index => delete $args->{index},
	});
}

sub oper  { $ffi->cast('opaque', 'TF_Operation', $_[0]->_oper ) }
sub index { $_[0]->_index }

use FFI::C::ArrayDef;
use FFI::C::StructDef;
my $sdef = FFI::C::StructDef->new($ffi,
	name     => 'TF_Input_struct',
	members  => [
		_oper  => 'opaque',
		_index => 'int',
		__ignore => 'char[4]',
	],
);
my $adef = FFI::C::ArrayDef->new($ffi,
       name => 'TF_Input_struct_array',
       members => [ 'TF_Input_struct' ]
);
sub _adef { $adef; }
sub _as_array {
	my $class = shift;
	my $output = $class->_adef->create(0 + @_);
	for my $idx (0..@_-1) {
		next unless defined $_[$idx];
		$class->_copy_to_other( $_[$idx], $output->[$idx] );
	}
	$output;
}
sub _from_array {
	my ($class, $array) = @_;
	[
		map {
			my $record = $class->new;
			$class->_copy_to_other($array->[$_], $record);
			$record;
		} 0..$array->count-1
	]
}
sub _copy_to_other {
	my ($class, $this, $that) = @_;
       $that->_oper ($this->_oper);
       $that->_index($this->_index);
}

$ffi->load_custom_type(
	RecordArrayRef( 'InputArrayPtr',
		record_module => __PACKAGE__, with_size => 0,
	),
	=> 'TF_Input_array');
$ffi->load_custom_type(
	RecordArrayRef( 'InputArrayPtrSz',
		record_module => __PACKAGE__, with_size => 1,
	),
	=> 'TF_Input_array_sz');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::Input - Input of operation as (operation, index) pair

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
